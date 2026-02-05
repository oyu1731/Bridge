package com.example.bridge.service;

import com.example.bridge.dto.CompanySignUpRequest;
import com.example.bridge.entity.Company;
import com.example.bridge.entity.User;
import com.example.bridge.repository.CompanyRepository;
import com.example.bridge.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

/**
 * 企業サービス
 * 企業と企業ユーザーの登録をトランザクション内で処理
 */
@Service
public class CompanyService {
    
    @Autowired
    private CompanyRepository companyRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    /**
     * 企業と企業ユーザーを同一トランザクション内で登録
     * 
     * @param request 企業ユーザー登録リクエスト
     * @return 登録された企業ユーザー情報を含むマップ
     * @throws Exception メール重複や入力エラー時
     */
    @Transactional
    public Map<String, Object> registerCompanyWithUser(CompanySignUpRequest request) throws Exception {
        // Step 1: メール重複チェック
        User existingUser = userRepository.findByEmail(request.getUserEmail());
        if (existingUser != null) {
            throw new Exception("このメールアドレスは既に登録されています");
        }
        
        // Step 2: 企業レコードを作成・保存
        Company company = new Company(
            request.getCompanyName(),
            request.getCompanyAddress(),
            request.getCompanyPhoneNumber(),
            request.getCompanyDescription(),
            parsePhotoId(request.getCompanyPhotoId())
        );
        Company savedCompany = companyRepository.save(company);
        System.out.println("✅ 企業レコード作成: companyId=" + savedCompany.getId() + ", name=" + savedCompany.getName());
        
        // Step 3: 企業ユーザーレコードを作成
        // type=3 は企業ユーザーを示す
        User companyUser = new User(
            request.getUserNickname(),
            request.getUserEmail(),
            request.getUserPassword(),
            3  // type: 3 = 企業ユーザー
        );
        
        // Step 4: ★重要★ company_id を明示的にセット
        companyUser.setCompanyId(savedCompany.getId());
        companyUser.setPhoneNumber(request.getUserPhoneNumber());
        companyUser.setPlanStatus("無料");
        companyUser.setAnnouncementDeletion(1);
        
        User savedUser = userRepository.save(companyUser);
        System.out.println("✅ 企業ユーザー作成: userId=" + savedUser.getId() 
            + ", companyId=" + savedUser.getCompanyId() 
            + ", type=" + savedUser.getType());
        
        // Step 5: レスポンスを構築
        Map<String, Object> result = new HashMap<>();
        result.put("userId", savedUser.getId());
        result.put("companyId", savedCompany.getId());
        result.put("email", savedUser.getEmail());
        result.put("nickname", savedUser.getNickname());
        result.put("type", savedUser.getType());
        result.put("companyName", savedCompany.getName());
        
        return result;
    }
    
    /**
     * PhotoId をパース（文字列から Integer に）
     */
    private Integer parsePhotoId(String photoIdStr) {
        if (photoIdStr == null || photoIdStr.isEmpty()) {
            return null;
        }
        try {
            return Integer.parseInt(photoIdStr);
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
