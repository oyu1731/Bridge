package com.bridge.backend.service;

import com.bridge.backend.dto.AdminNoticeLogDto;
import com.bridge.backend.dto.NoticeDTO;
import com.bridge.backend.entity.Notice;
import com.bridge.backend.repository.ChatRepository;
import com.bridge.backend.repository.NoticeRepository;
import com.bridge.backend.repository.ThreadRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.Timestamp;
import java.time.ZoneId;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NoticeService {

    private final NoticeRepository noticeRepository;
    private final ThreadRepository threadRepository;
    private final ChatRepository chatRepository;

    /* 通常取得 */
    public List<NoticeDTO> getNotices() {
        return noticeRepository.findAll().stream().map(n -> {

            String title = null;
            String content = null;

            if (n.getThreadId() != null) {
                title = threadRepository.findById(n.getThreadId())
                        .map(t -> t.getTitle())
                        .orElse(null);
            }

            if (n.getChatId() != null) {
                content = chatRepository.findById(n.getChatId())
                        .map(c -> c.getContent())
                        .orElse(null);
            }

            return new NoticeDTO(
                    n.getId(),
                    n.getFromUserId(),
                    n.getToUserId(),
                    n.getThreadId(),
                    n.getChatId(),
                    n.getCreatedAt(),
                    title,
                    content
            );
        }).toList();
    }

    /* 管理者ログ */
    public List<AdminNoticeLogDto> getLogs() {
        return noticeRepository.findAdminNoticeLogs().stream().map(r -> {

            AdminNoticeLogDto d = new AdminNoticeLogDto();

            d.id = ((Number) r[0]).intValue();
            d.fromUserId = r[1] != null ? ((Number) r[1]).intValue() : null;
            d.toUserId   = r[2] != null ? ((Number) r[2]).intValue() : null;
            d.type       = r[3] != null ? ((Number) r[3]).intValue() : null;
            d.threadId   = r[4] != null ? ((Number) r[4]).intValue() : null;
            d.chatId     = r[5] != null ? ((Number) r[5]).intValue() : null;

            Object ts = r[6];
            if (ts instanceof Timestamp t) {
                d.createdAt = t.toLocalDateTime();
            } else if (ts instanceof java.util.Date d2) {
                d.createdAt = d2.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
            }

            d.threadTitle = (String) r[7];
            d.chatContent = (String) r[8];

            d.threadDeleted = r[9] != null && ((Boolean) r[9]);   // ← 追加
            d.chatDeleted   = r[10] != null && ((Boolean) r[10]); // ← 追加

            d.totalCount = ((Number) r[11]).intValue();

            return d;
        }).toList();
    }


    /* 管理者削除 */
    @Transactional
    public void adminDeleteByNotice(Integer noticeId) {

        Notice n = noticeRepository.findById(noticeId)
                .orElseThrow(() -> new RuntimeException("not found"));

        if (n.getType() == 1 && n.getThreadId() != null) {
            threadRepository.softDelete(n.getThreadId());
        }

        if (n.getType() == 2 && n.getChatId() != null) {
            chatRepository.softDelete(n.getChatId());
        }
    }
}
