package com.bridge.backend.dto;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * NotificationDto
 * フロントから送信されるお知らせ情報を受け取るDTO
 */
public class NotificationDto {
    private Integer id;
    private Integer type;
    private String title;
    private String content;
    private Integer category;
    private Integer userId;

    @JsonFormat(pattern="yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime reservationTime;

    @JsonFormat(pattern="yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime sendFlag;

    private Integer sendFlagInt;

    public NotificationDto() {}

    public NotificationDto(Integer id, Integer type, String title, String content, Integer category, Integer userId, LocalDateTime reservationTime, LocalDateTime sendFlag, Integer sendFlagInt) {
        this.id = id;
        this.type = type;
        this.title = title;
        this.content = content;
        this.category = category;
        this.userId = userId;
        this.reservationTime = reservationTime;
        this.sendFlag = sendFlag;
        this.sendFlagInt = sendFlagInt;
    }

    // --- ゲッターとセッター ---
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }
    
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

    public Integer getCategory() {
        return category;
    }

    public void setCategory(Integer category) {
        this.category = category;
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

    public LocalDateTime getSendFlag() {
        return sendFlag;
    }

    public void setSendFlag(LocalDateTime sendFlag) {
        this.sendFlag = sendFlag;
    }

    public Integer getSendFlagInt() {
        return sendFlagInt;
    }

    public void setSendFlagInt(Integer sendFlagInt) {
        this.sendFlagInt = sendFlagInt;
    }
}
