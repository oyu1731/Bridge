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
    public Boolean threadDeleted;   // ← 追加
    public Boolean chatDeleted;     // ← 追加
    public Integer totalCount;
}
