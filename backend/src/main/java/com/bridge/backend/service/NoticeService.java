package com.bridge.backend.service;

import com.bridge.backend.dto.NoticeDTO;
import com.bridge.backend.entity.Notice;
import com.bridge.backend.repository.NoticeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NoticeService {
    
    @Autowired
    private NoticeRepository noticeRepository;


    /**
     * 全ての記事を取得（削除されていないもの）
     * 
     * @return NoticeDTOのリスト
     */
    public List<NoticeDTO> getNotices() {
        List<Notice> notices = noticeRepository.findAll();
        System.out.println("Fetched notices count: " + notices.size());
        return notices.stream()
        .map(n -> new NoticeDTO(
            n.getId(),
            n.getFromUserId(),
            n.getToUserId(),
            n.getThreadId(),
            n.getChatId(),
            n.getCreatedAt()
        )).toList();
    }
}
