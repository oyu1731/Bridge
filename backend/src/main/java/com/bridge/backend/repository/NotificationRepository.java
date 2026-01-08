package com.bridge.backend.repository;

import com.bridge.backend.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Integer> {

    /**
     * 削除されていないお知らせを全取得
     */
    List<Notification> findByIsDeletedFalse();

    /**
     * 削除申請中：削除されていないお知らせを取得
     */
    Notification findByIdAndIsDeletedFalse(Integer id);

    /**
     * 予約日時 < 現在 かつ send_flag_int = 1 のデータを検索
     */
    List<Notification> findByReservationTimeBeforeAndSendFlagInt(LocalDateTime reservationTime, int sendFlagInt);

    /**
     * 送信済み（sendFlagInt=2）のお知らせを取得
     */
    List<Notification> findBySendFlagInt(Integer sendFlagInt);

    /**
     * 予約日時が過ぎている予約お知らせを取得
     * sendFlagInt=1 かつ reservationTime <= 現在時刻
     */
    List<Notification> findBySendFlagIntAndReservationTimeBefore(Integer sendFlagInt, LocalDateTime now);

    /**
     * タイプ別にお知らせを取得
     * @param type お知らせタイプ
     */
    List<Notification> findByType(Integer type);

    /**
     * 特定ユーザー向けのお知らせを取得
     * @param userId ユーザーID
     */
    List<Notification> findByTypeAndUserId(Integer type, Integer userId);
}
