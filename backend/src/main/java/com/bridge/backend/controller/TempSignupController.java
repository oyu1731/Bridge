package com.bridge.backend.controller;

import com.bridge.backend.entity.TempCompanySignup;
import com.bridge.backend.repository.TempCompanySignupRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/temp-signups")
public class TempSignupController {

    @Autowired
    private TempCompanySignupRepository tempRepo;

    @PostMapping
    public ResponseEntity<Map<String, Object>> createTempSignup(@RequestBody Map<String, Object> body) {
        TempCompanySignup temp = new TempCompanySignup();
        temp.setNickname((String) body.getOrDefault("nickname", ""));
        temp.setEmail((String) body.getOrDefault("email", ""));
        temp.setPassword((String) body.getOrDefault("password", ""));
        temp.setPhoneNumber((String) body.getOrDefault("phoneNumber", ""));
        temp.setCompanyName((String) body.getOrDefault("companyName", ""));
        temp.setCompanyAddress((String) body.getOrDefault("companyAddress", ""));
        temp.setCompanyPhoneNumber((String) body.getOrDefault("companyPhoneNumber", ""));
        // desiredIndustries may be list; store as JSON string if present
        Object di = body.get("desiredIndustries");
        if (di != null) temp.setDesiredIndustries(di.toString());

        TempCompanySignup saved = tempRepo.save(temp);
        return ResponseEntity.ok(Map.of("tempId", saved.getId()));
    }
}
