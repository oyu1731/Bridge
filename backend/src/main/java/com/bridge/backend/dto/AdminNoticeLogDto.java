package com.bridge.backend.dto;

import java.time.LocalDateTime;

public class AdminNoticeLogDto {

    public Integer id;
    public Integer fromUserId;
    public Integer toUserId;
    public Integer type;
    public Integer threadId;
    public Integer chatId;
    public LocalDateTime createdAt;
    public String threadTitle;
    public String chatContent;
    public Boolean threadDeleted;
    public Boolean chatDeleted;
    public Integer totalCount;
    public Boolean fromUserDeleted;
    public Boolean toUserDeleted;
}
