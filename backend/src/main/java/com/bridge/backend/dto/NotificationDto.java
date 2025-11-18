package com.bridge.backend.dto;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * NotificationDto
 * フロントから送信されるお知らせ情報を受け取るDTO
 */
public class NotificationDto {

    // お知らせタイプ: 1=学生, 2=社会人, 3=企業, ... 8=特定ユーザー
    private Integer type;

    // 件名
    private String title;

    // 内容
    private String content;

    // 特定ユーザーID (typeに8が含まれる場合のみ)
    private Integer userId;

    // 予約送信日時（nullの場合は即時）
    @JsonFormat(pattern="yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime reservationTime;

    public NotificationDto() {}

    public NotificationDto(Integer type, String title, String content, Integer userId, LocalDateTime reservationTime) {
        this.type = type;
        this.title = title;
        this.content = content;
        this.userId = userId;
        this.reservationTime = reservationTime;
    }

    // ゲッターとセッター
    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Integer getUserId() {
        return userId;
    }

    public void setUserId(Integer userId) {
        this.userId = userId;
    }

    public LocalDateTime getReservationTime() {
        return reservationTime;
    }

    public void setReservationTime(LocalDateTime reservationTime) {
        this.reservationTime = reservationTime;
    }
}
