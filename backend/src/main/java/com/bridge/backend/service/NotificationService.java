package com.bridge.backend.service;

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

    /**
     * お知らせ作成（DB保存）
     * 予約送信日時を LocalDateTime に変換してセット
     */
    public Notification createNotification(Notification notification) {
        if (notification.getReservationTime() == null) {
            // 即時送信
            notification.setSendFlagInt(2);
            notification.setSendFlag(LocalDateTime.now());
        } else {
            // 予約送信
            notification.setSendFlagInt(1);
        }
        return notificationRepository.save(notification);
    }

    /**
     * 定期的に予約送信済み通知をチェックし、送信時刻を過ぎたものを即時送信に変更
     */
    @Scheduled(fixedRate = 60000) // 1分ごとにチェック
    public void processScheduledNotifications() {
        LocalDateTime now = LocalDateTime.now();

        // sendFlagInt=1 は予約送信
        List<Notification> dueNotifications = notificationRepository
                .findBySendFlagIntAndReservationTimeBefore(1, now);

        for (Notification notification : dueNotifications) {
            // 即時送信に変更
            notification.setSendFlagInt(2);
            notification.setSendFlag(now);
            notificationRepository.save(notification);

            // ここでメール送信やプッシュ通知を呼ぶ
            sendNotification(notification);
        }
    }

    /**
     * 実際の通知処理
     * メール・プッシュ通知等をここで実装
     */
    private void sendNotification(Notification notification) {
        // TODO: メールやプッシュ通知の送信処理
        System.out.println("通知送信: " + notification.getTitle() + " / 宛先タイプ: " + notification.getType());
    }
}
