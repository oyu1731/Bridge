package com.bridge.backend.controller;

import com.bridge.backend.dto.PhotoDTO;
import com.bridge.backend.service.PhotoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

/**
 * PhotoController
 * 写真アップロード、取得、削除のAPIエンドポイントを提供
 */
@RestController
@RequestMapping("/api/photos")
// @CrossOrigin(origins = "*")
// ↑を↓に変えたらできたけど↑のでしたい（高橋が作ったコントローラーとこのコントローラーだけ変えました。）
@CrossOrigin(origins = "http://localhost:xxxx", allowCredentials = "true")
public class PhotoController {

    @Autowired
    private PhotoService photoService;

    /**
     * 画像をアップロード
     * 
     * POST /api/photos/upload
     * 
     * @param file アップロードする画像ファイル
     * @param userId ユーザーID（オプション）
     * @return 保存された写真のDTO
     */
    @PostMapping("/upload")
    public ResponseEntity<?> uploadPhoto(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "userId", required = false) Integer userId) {
        try {
            PhotoDTO photoDTO = photoService.uploadPhoto(file, userId);
            return ResponseEntity.status(HttpStatus.CREATED).body(photoDTO);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("ファイルのアップロードに失敗しました: " + e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Internal Server Error");
        }
    }

    /**
     * 写真IDから写真情報を取得
     * 
     * GET /api/photos/{id}
     * 
     * @param id 写真ID
     * @return 写真のDTO
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getPhotoById(@PathVariable Integer id) {
        PhotoDTO photoDTO = photoService.getPhotoById(id);
        if (photoDTO != null) {
            return ResponseEntity.ok(photoDTO);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * 写真を削除
     * 
     * DELETE /api/photos/{id}
     * 
     * @param id 写真ID
     * @return 削除結果
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deletePhoto(@PathVariable Integer id) {
        boolean deleted = photoService.deletePhoto(id);
        if (deleted) {
            return ResponseEntity.ok().body("写真を削除しました");
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
