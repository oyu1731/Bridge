package com.bridge.backend.service;

import com.bridge.backend.dto.NotificationDto;
import com.bridge.backend.entity.Notification;
import com.bridge.backend.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    public List<NotificationDto> getNotifications() {
        List<Notification> notifications = notificationRepository.findByIsDeletedFalse();

        return notifications.stream()
            .map(n -> new NotificationDto(
                n.getId(),
                n.getType(),
                n.getTitle(),
                n.getContent(),
                n.getCategory(),
                n.getUserId(),
                n.getReservationTime(),
                n.getSendFlag()
            )).toList();
    }

    public List<NotificationDto> searchNotifications(
        String title,
        Integer type,
        Integer category,
        String sendFlag
    ) {
        List<Notification> notifications = notificationRepository.findByIsDeletedFalse();
        return notifications.stream()
            .filter(n -> title == null || n.getTitle().contains(title)) // タイトル部分一致
            .filter(n -> type == null || n.getType().equals(type))      // 宛先一致
            .filter(n -> category == null || n.getCategory().equals(category)) // カテゴリ一致
            .filter(n -> {
                if (sendFlag == null || n.getSendFlag() == null) return true;
                // フロントは yyyy-MM-dd 形式で送信
                return n.getSendFlag().toLocalDate().toString().equals(sendFlag);
            })
            .map(n -> new NotificationDto(
            n.getId(),
            n.getType(),
            n.getTitle(),
            n.getContent(),
            n.getCategory(),
            n.getUserId(),
            n.getReservationTime(),
            n.getSendFlag()
        )).toList();
    }


    /**
     * お知らせ作成（DB保存） + バリデーション
     */
    public Notification createNotification(Notification notification) {

        // バリデーション
        if (notification.getTitle() == null || notification.getTitle().isEmpty()) {
            throw new IllegalArgumentException("件名は必須です");
        }
        if (notification.getContent() == null || notification.getContent().isEmpty()) {
            throw new IllegalArgumentException("内容は必須です");
        }
        if (notification.getCategory() == null) {
            throw new IllegalArgumentException("カテゴリは必須です");
        }
        if (notification.getCategory() < 1 || notification.getCategory() > 2) {
            throw new IllegalArgumentException("カテゴリが不正です");
        }

        Integer type = notification.getType();
        Integer userId = notification.getUserId();
        LocalDateTime reservationTime = notification.getReservationTime();

        // 個人宛のルール
        if (type == 8) {
            if (userId == null) {
                throw new IllegalArgumentException("個人宛の場合はユーザーIDが必要です");
            }
        } else {
            notification.setUserId(null); // type 1～7 の場合は userId は null
        }

        // 予約日時チェック
        if (reservationTime != null && reservationTime.isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("予約日時は過去に設定できません");
        }

        // 送信フラグ設定
        if (reservationTime == null) {
            notification.setSendFlagInt(2); // 即時送信
            notification.setSendFlag(LocalDateTime.now());
        } else {
            notification.setSendFlagInt(1); // 予約送信
        }

        return notificationRepository.save(notification);
    }
    
    /**
     * 記事を削除（論理削除）
     * 
     * @param id 削除する記事のID
     * @return 削除成功の場合true
    */
    public boolean deleteNotifications(Integer id) {
        Notification notification =notificationRepository.findByIdAndIsDeletedFalse(id);
        if (notification == null) {
            return false;
        }

        notification.setIsDeleted(true);
        notificationRepository.save(notification);
        return true;
    }

    /**
     * 予約日時を過ぎたお知らせを自動送信扱いにする
     * 1分ごとに実行
     */
    @Scheduled(fixedRate = 60000) // 60000ms = 1分
    public void checkAndSendReservedNotifications() {
        LocalDateTime now = LocalDateTime.now();

        // send_flag_int = 1 （予約のやつ）で、予約日時を過ぎているものを検索
        List<Notification> list =
                notificationRepository.findByReservationTimeBeforeAndSendFlagInt(now, 1);

        for (Notification n : list) {
            n.setSendFlagInt(2); // 送信済みに変更
            n.setSendFlag(LocalDateTime.now()); // 送信日時を更新
            notificationRepository.save(n);

            System.out.println("予約通知を送信しました → ID: " + n.getId());
            // 📝 本当はここでメールやプッシュ通知などの送信処理を書く
        }
    }
}
