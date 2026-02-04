package com.bridge.backend.controller;

import com.bridge.backend.dto.CompanyDTO;
import com.bridge.backend.service.CompanyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/companies")
//@CrossOrigin(origins = "*") // Flutter アプリからのアクセスを許可
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")public class CompanyController {
        /**
         * 企業写真IDを更新
         * PUT /api/companies/{id}/photo
         */
        @PutMapping("/{id}/photo")
        public ResponseEntity<Void> updateCompanyPhoto(@PathVariable Integer id, @RequestBody PhotoIdRequest request) {
            try {
                boolean updated = companyService.updateCompanyPhotoId(id, request.getPhotoId());
                if (updated) {
                    return ResponseEntity.ok().build();
                } else {
                    return ResponseEntity.notFound().build();
                }
            } catch (Exception e) {
                e.printStackTrace();
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
            }
        }

        // リクエスト用DTO
        public static class PhotoIdRequest {
            private Integer photo_id;
            public Integer getPhotoId() { return photo_id; }
            public void setPhotoId(Integer photo_id) { this.photo_id = photo_id; }
        }
    
    @Autowired
    private CompanyService companyService;

    /**
     * すべての企業を取得
     * GET /api/companies
     */
    @GetMapping
    public ResponseEntity<List<CompanyDTO>> getAllCompanies() {
        try {
            List<CompanyDTO> companies = companyService.getAllCompanies();
            return ResponseEntity.ok(companies);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * キーワードで企業を検索
     * GET /api/companies/search?keyword={keyword}
     */
    @GetMapping("/search")
    public ResponseEntity<List<CompanyDTO>> searchCompanies(@RequestParam(required = false) String keyword) {
        try {
            if (keyword == null) {
                CompanyDTO dto = new CompanyDTO();
                dto.setName(null); // 入力値（null）を保存
                // エラーメッセージ用のDTO拡張またはMapで返却
                dto.setDescription("不正な入力値です");
                return ResponseEntity.badRequest().body(java.util.Arrays.asList(dto));
            }
            List<CompanyDTO> companies = companyService.searchCompanies(keyword);
            return ResponseEntity.ok(companies);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * IDで企業を取得
     * GET /api/companies/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<CompanyDTO> getCompanyById(@PathVariable String id) {
        try {
            Integer companyId = null;
            try {
                companyId = Integer.valueOf(id);
            } catch (NumberFormatException e) {
                CompanyDTO dto = new CompanyDTO();
                dto.setId(null);
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
            Optional<CompanyDTO> company = companyService.getCompanyById(companyId);
            if (company.isPresent()) {
                return ResponseEntity.ok(company.get());
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * 企業を新規作成
     * POST /api/companies
     */
    @PostMapping
    public ResponseEntity<CompanyDTO> createCompany(@RequestBody CompanyDTO companyDTO) {
        try {
            // 入力値のバリデーション
            if (companyDTO.getName() == null || companyDTO.getName().trim().isEmpty()) {
                return ResponseEntity.badRequest().build();
            }
            
            CompanyDTO savedCompany = companyService.createCompany(companyDTO);
            return ResponseEntity.status(HttpStatus.CREATED).body(savedCompany);
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * 企業情報を更新
     * PUT /api/companies/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<CompanyDTO> updateCompany(@PathVariable String id, @RequestBody CompanyDTO companyDTO) {
        try {
            Integer companyId = null;
            try {
                companyId = Integer.valueOf(id);
            } catch (NumberFormatException e) {
                CompanyDTO dto = new CompanyDTO();
                dto.setId(null);
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
            // nickname, email, phoneNumber, address のバリデーション
            if (companyDTO.getName() == null || companyDTO.getName().trim().isEmpty()) {
                CompanyDTO dto = new CompanyDTO();
                dto.setName(companyDTO.getName());
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
            if (companyDTO.getEmail() == null || companyDTO.getEmail().trim().isEmpty()) {
                CompanyDTO dto = new CompanyDTO();
                dto.setEmail(companyDTO.getEmail());
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
            if (companyDTO.getPhoneNumber() == null || companyDTO.getPhoneNumber().trim().isEmpty()) {
                CompanyDTO dto = new CompanyDTO();
                dto.setPhoneNumber(companyDTO.getPhoneNumber());
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
            if (companyDTO.getAddress() == null || companyDTO.getAddress().trim().isEmpty()) {
                CompanyDTO dto = new CompanyDTO();
                dto.setAddress(companyDTO.getAddress());
                dto.setDescription("不正な入力値です");
                return ResponseEntity.ok(dto);
            }
            Optional<CompanyDTO> updatedCompany = companyService.updateCompany(companyId, companyDTO);
            if (updatedCompany.isPresent()) {
                return ResponseEntity.ok(updatedCompany.get());
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * 企業を論理削除（退会処理）
     * DELETE /api/companies/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> withdrawCompany(@PathVariable Integer id) {
        try {
            boolean deleted = companyService.withdrawCompany(id);
            
            if (deleted) {
                return ResponseEntity.noContent().build();
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}