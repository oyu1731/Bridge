package com.bridge.backend.service;

import com.bridge.backend.dto.CompanyDTO;
import com.bridge.backend.entity.Company;
import com.bridge.backend.entity.ImageRelation;
import com.bridge.backend.repository.CompanyRepository;
import com.bridge.backend.repository.ImageRelationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
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
    private ImageRelationRepository imageRelationRepository;
    
    @Value("${app.image.base-url:http://localhost:8080/api/images}")
    private String imageBaseUrl;
    
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
    public Optional<CompanyDTO> getCompanyById(Long id) {
        Optional<Company> company = companyRepository.findByIdAndIsWithdrawnFalse(id);
        return company.map(this::convertToDTO);
    }
    
    /**
     * 企業を新規作成
     */
    public CompanyDTO createCompany(CompanyDTO companyDTO) {
        Company company = companyDTO.toEntity();
        Company savedCompany = companyRepository.save(company);
        return convertToDTO(savedCompany);
    }
    
    /**
     * 企業情報を更新
     */
    public Optional<CompanyDTO> updateCompany(Long id, CompanyDTO companyDTO) {
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
            if (companyDTO.getPhotoId() != null) {
                company.setPhotoId(companyDTO.getPhotoId());
            }
            
            Company savedCompany = companyRepository.save(company);
            return Optional.of(convertToDTO(savedCompany));
        }
        
        return Optional.empty();
    }
    
    /**
     * 企業を論理削除（退会処理）
     */
    public boolean withdrawCompany(Long id) {
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
     * 最新の企業を指定数取得
     */
    @Transactional(readOnly = true)
    public List<CompanyDTO> getRecentCompanies(int limit) {
        List<Company> companies = companyRepository.findTopNRecentCompanies(limit);
        return companies.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * 企業の存在確認
     */
    @Transactional(readOnly = true)
    public boolean existsCompany(Long id) {
        return companyRepository.existsByIdAndIsWithdrawnFalse(id);
    }
    
    /**
     * EntityをDTOに変換（画像URL付き）
     */
    private CompanyDTO convertToDTO(Company company) {
        CompanyDTO dto = CompanyDTO.fromEntity(company);
        
        // 関連画像を取得してURLを設定
        List<ImageRelation> images = imageRelationRepository.findCompanyImages(company.getId());
        List<String> imageUrls = images.stream()
                .map(image -> imageBaseUrl + "/" + image.getImagePath())
                .collect(Collectors.toList());
        dto.setImageUrls(imageUrls);
        
        return dto;
    }
}