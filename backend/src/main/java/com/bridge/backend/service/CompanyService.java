package com.bridge.backend.service;

import com.bridge.backend.dto.CompanyDTO;
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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
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
     * CompanyエンティティをCompanyDTOに変換（写真パス情報、業界情報、email情報を含む）
     * 
     * @param company Companyエンティティ
     * @return CompanyDTO
     */
    private CompanyDTO convertToDTO(Company company) {
        CompanyDTO dto = CompanyDTO.fromEntity(company);
        
        // 写真パス情報を取得して設定
        if (company.getPhotoId() != null) {
            Optional<Photo> photo = photoRepository.findById(company.getPhotoId());
            if (photo.isPresent()) {
                dto.setPhotoPath(photo.get().getPhotoPath());
            }
        }
        
        // 企業に関連するユーザー情報を取得
        Optional<User> companyUser = userRepository.findByCompanyId(company.getId());
        if (companyUser.isPresent()) {
            User user = companyUser.get();
            
            // email情報を設定
            dto.setEmail(user.getEmail());
            
            // 業界情報を取得（type=3で企業の業界を指定）
            Optional<IndustryRelation> industryRelation = 
                industryRelationRepository.findByUserIdAndType(user.getId(), 3);
            
            if (industryRelation.isPresent()) {
                Optional<Industry> industry = 
                    industryRepository.findById(industryRelation.get().getTargetId());
                
                if (industry.isPresent()) {
                    dto.setIndustry(industry.get().getIndustry());
                }
            }
        }
        
        return dto;
    }
}