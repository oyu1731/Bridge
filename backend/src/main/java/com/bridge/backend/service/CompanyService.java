package com.bridge.backend.service;

import com.bridge.backend.dto.CompanyDTO;
import com.bridge.backend.dto.CompanySignUpRequest;
import com.bridge.backend.entity.Company;
import com.bridge.backend.entity.Photo;
import com.bridge.backend.entity.User;
import com.bridge.backend.entity.IndustryRelation;
import com.bridge.backend.entity.Industry;
import com.bridge.backend.repository.CompanyRepository;
import com.bridge.backend.repository.PhotoRepository;
import com.bridge.backend.repository.UserRepository;
import com.bridge.backend.repository.IndustryRelationRepository;
import com.bridge.backend.repository.IndustryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
public class CompanyService {
    @Autowired
    private CompanyRepository companyRepository;
    
    @Autowired
    private PhotoRepository photoRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private IndustryRelationRepository industryRelationRepository;
    
    @Autowired
    private IndustryRepository industryRepository;
    
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    
    /**
     * すべての企業を取得（退会していない企業のみ）
     */
    @Transactional(readOnly = true)
    public List<CompanyDTO> getAllCompanies() {
        List<Company> companies = companyRepository.findByIsWithdrawnFalseOrderByCreatedAtDesc();
        return companies.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * キーワードで企業を検索
     */
    @Transactional(readOnly = true)
    public List<CompanyDTO> searchCompanies(String keyword) {
        List<Company> companies;
        
        if (keyword == null || keyword.trim().isEmpty()) {
            companies = companyRepository.findByIsWithdrawnFalseOrderByCreatedAtDesc();
        } else {
            companies = companyRepository.findByNameOrAddressContaining(keyword.trim());
        }
        
        return companies.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * IDで企業を取得
     */
    @Transactional(readOnly = true)
    public Optional<CompanyDTO> getCompanyById(Integer id) {
        Optional<Company> company = companyRepository.findByIdAndIsWithdrawnFalse(id);
        return company.map(this::convertToDTO);
    }
    
    /**
     * 企業を新規作成
     */
    public CompanyDTO createCompany(CompanyDTO companyDTO) {
        Company company = companyDTO.toEntity();
        Company savedCompany = companyRepository.save(company);
        return this.convertToDTO(savedCompany);
    }
    
    /**
     * 企業情報を更新
     */
    public Optional<CompanyDTO> updateCompany(Integer id, CompanyDTO companyDTO) {
        Optional<Company> existingCompany = companyRepository.findByIdAndIsWithdrawnFalse(id);
        
        if (existingCompany.isPresent()) {
            Company company = existingCompany.get();
            
            // 更新可能なフィールドのみ更新
            if (companyDTO.getName() != null) {
                company.setName(companyDTO.getName());
            }
            if (companyDTO.getAddress() != null) {
                company.setAddress(companyDTO.getAddress());
            }
            if (companyDTO.getPhoneNumber() != null) {
                company.setPhoneNumber(companyDTO.getPhoneNumber());
            }
            if (companyDTO.getDescription() != null) {
                company.setDescription(companyDTO.getDescription());
            }
            if (companyDTO.getPlanStatus() != null) {
                company.setPlanStatus(companyDTO.getPlanStatus());
            }
            if (companyDTO.getPhotoId() != null) {
                company.setPhotoId(companyDTO.getPhotoId());
            }
            
            Company savedCompany = companyRepository.save(company);
            return Optional.of(this.convertToDTO(savedCompany));
        }
        
        return Optional.empty();
    }
    
    /**
     * 企業を論理削除（退会処理）
     */
    public boolean withdrawCompany(Integer id) {
        Optional<Company> existingCompany = companyRepository.findByIdAndIsWithdrawnFalse(id);
        
        if (existingCompany.isPresent()) {
            Company company = existingCompany.get();
            company.setIsWithdrawn(true);
            companyRepository.save(company);
            return true;
        }
        
        return false;
    }
    
    /**
     * プランステータスで企業を検索
     */
    @Transactional(readOnly = true)
    public List<CompanyDTO> getCompaniesByPlanStatus(Integer planStatus) {
        List<Company> companies = companyRepository.findByPlanStatusAndIsWithdrawnFalseOrderByCreatedAtDesc(planStatus);
        return companies.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * 企業の存在確認
     */
    @Transactional(readOnly = true)
    public boolean existsCompany(Integer id) {
        return companyRepository.existsByIdAndIsWithdrawnFalse(id);
    }
    
    /**
     * CompanyエンティティをCompanyDTOに変換（写真パス情報、業界情報リスト、email情報を含む）
     *
     * @param company Companyエンティティ
     * @return CompanyDTO
     */
    private CompanyDTO convertToDTO(Company company) {
        CompanyDTO dto = CompanyDTO.fromEntity(company);

        // 写真パス情報を取得して設定
        if (company.getPhotoId() != null) {
            Optional<Photo> photo = photoRepository.findById(company.getPhotoId());
            photo.ifPresent(value -> dto.setPhotoPath(value.getPhotoPath()));
        }

        // 企業に関連するユーザー情報を取得
        Optional<User> companyUser = userRepository.findByCompanyId(company.getId());
        if (companyUser.isPresent()) {
            User user = companyUser.get();

            // email情報を設定
            dto.setEmail(user.getEmail());

            // 業界情報リストを取得（type=1,2,3で企業の業界を指定）
            java.util.List<String> industries = new java.util.ArrayList<>();
            for (int type = 1; type <= 3; type++) {
                List<IndustryRelation> relations = industryRelationRepository.findAllByUserIdAndType(user.getId(), type);
                for (IndustryRelation rel : relations) {
                    Industry industry = rel.getIndustry();
                    if (industry != null && industry.getIndustry() != null && !industries.contains(industry.getIndustry())) {
                        industries.add(industry.getIndustry());
                    }
                }
            }
            dto.setIndustries(industries);

            // ユーザーのアイコンIDをセット
            dto.setIconId(user.getIcon());
        }

        return dto;
    }

    /**
     * 企業のphotoIdのみ更新
     */
    public boolean updateCompanyPhotoId(Integer companyId, Integer photoId) {
        Optional<Company> companyOpt = companyRepository.findByIdAndIsWithdrawnFalse(companyId);
        if (companyOpt.isPresent()) {
            Company company = companyOpt.get();
            company.setPhotoId(photoId);
            companyRepository.save(company);
            return true;
        }
        return false;
    }

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
        Optional<User> existingUser = userRepository.findByEmail(request.getUserEmail());
        if (existingUser.isPresent()) {
            throw new Exception("このメールアドレスは既に登録されています");
        }
        
        // Step 2: 企業レコードを作成・保存
        Company company = new Company();
        company.setName(request.getCompanyName());
        company.setAddress(request.getCompanyAddress());
        company.setPhoneNumber(request.getCompanyPhoneNumber());
        company.setDescription(request.getCompanyDescription());
        company.setPhotoId(parsePhotoId(request.getCompanyPhotoId()));
        company.setPlanStatus(1);
        company.setIsWithdrawn(false);
        company.setCreatedAt(LocalDateTime.now());
        
        Company savedCompany = companyRepository.save(company);
        System.out.println("✅ 企業レコード作成: companyId=" + savedCompany.getId() + ", name=" + savedCompany.getName());
        
        // Step 3: 企業ユーザーレコードを作成
        // type=3 は企業ユーザーを示す
        User companyUser = new User();
        companyUser.setNickname(request.getUserNickname());
        companyUser.setEmail(request.getUserEmail());
        companyUser.setPassword(passwordEncoder.encode(request.getUserPassword()));
        companyUser.setPhoneNumber(request.getUserPhoneNumber());
        companyUser.setType(3);  // type: 3 = 企業ユーザー
        
        // Step 4: ★重要★ company_id を明示的にセット
        companyUser.setCompanyId(savedCompany.getId());
        companyUser.setPlanStatus("企業プレミアム");
        companyUser.setToken(50);
        companyUser.setIcon(null);
        companyUser.setReportCount(0);
        companyUser.setAnnouncementDeletion(1);
        companyUser.setIsWithdrawn(false);
        companyUser.setCreatedAt(LocalDateTime.now());
        
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