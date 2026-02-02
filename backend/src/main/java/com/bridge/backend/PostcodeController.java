package com.bridge.backend;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import java.util.Collections;

@RestController
@RequestMapping("/api/postcode")
@CrossOrigin // 必要に応じてオリジン指定
public class PostcodeController {
    private static final String API_KEY = "WcUh82VWknCNMtoqSgjtXr243hp2CV";
    private static final String ENDPOINT = "https://apis.postcode-jp.com/api/v6/postcodes/";

    @GetMapping
    public ResponseEntity<String> getAddress(@RequestParam String postcode) {
        RestTemplate restTemplate = new RestTemplate();
        String url = ENDPOINT + postcode + "?apikey=" + API_KEY;
        System.out.println("[DEBUG] PostcodeJP API request URL: " + url);
        HttpHeaders headers = new HttpHeaders();
        headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));
        HttpEntity<String> entity = new HttpEntity<>(headers);
        try {
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);
            String body = response.getBody();
            String wrapped = "{\"data\":" + body + "}";
            return ResponseEntity.status(response.getStatusCode()).body(wrapped);
        } catch (Exception e) {
            return ResponseEntity.status(500).body("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }
}
