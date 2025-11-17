package com.bridge.backend.service;

import com.bridge.backend.dto.PhotoDTO;
import com.bridge.backend.entity.Photo;
import com.bridge.backend.repository.PhotoRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Optional;
import java.util.UUID;

/**
 * PhotoService
 * 写真のアップロード、保存、取得を管理するサービスクラス
 */
@Service
public class PhotoService {

    @Autowired
    private PhotoRepository photoRepository;

    // application.propertiesから画像保存ディレクトリを取得
    @Value("${file.upload-dir:uploads/photos}")
    private String uploadDir;

    /**
     * 画像をアップロードして保存
     * 
     * @param file アップロードされた画像ファイル
     * @param userId ユーザーID（オプション）
     * @return 保存された写真のDTO
     * @throws IOException ファイル保存時のエラー
     */
    public PhotoDTO uploadPhoto(MultipartFile file, Integer userId) throws IOException {
        // ファイル名の検証
        if (file.isEmpty()) {
            throw new IllegalArgumentException("ファイルが空です");
        }

        // ファイルサイズの検証（例: 10MB）
        long maxFileSize = 10 * 1024 * 1024; // 10MB
        if (file.getSize() > maxFileSize) {
            throw new IllegalArgumentException("ファイルサイズが大きすぎます（最大10MB）");
        }

        // ファイル拡張子の検証
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !isValidImageExtension(originalFilename)) {
            throw new IllegalArgumentException("サポートされていないファイル形式です");
        }

        // ユニークなファイル名を生成
        String fileExtension = getFileExtension(originalFilename);
        String uniqueFilename = UUID.randomUUID().toString() + fileExtension;

        // アップロードディレクトリを作成
        Path uploadPath = Paths.get(uploadDir);
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }

        // ファイルを保存
        Path filePath = uploadPath.resolve(uniqueFilename);
        Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

        // データベースに保存
        Photo photo = new Photo();
        photo.setPhotoPath("/uploads/photos/" + uniqueFilename);
        photo.setUserId(userId);
        
        Photo savedPhoto = photoRepository.save(photo);

        return new PhotoDTO(savedPhoto.getId(), savedPhoto.getPhotoPath(), savedPhoto.getUserId());
    }

    /**
     * 写真IDから写真情報を取得
     * 
     * @param id 写真ID
     * @return 写真のDTO
     */
    public PhotoDTO getPhotoById(Integer id) {
        Optional<Photo> photo = photoRepository.findById(id);
        if (photo.isPresent()) {
            Photo p = photo.get();
            return new PhotoDTO(p.getId(), p.getPhotoPath(), p.getUserId());
        }
        return null;
    }

    /**
     * 写真を削除
     * 
     * @param id 写真ID
     * @return 削除成功の場合true
     */
    public boolean deletePhoto(Integer id) {
        Optional<Photo> photo = photoRepository.findById(id);
        if (photo.isPresent()) {
            Photo p = photo.get();
            
            // ファイルシステムからファイルを削除
            try {
                String photoPath = p.getPhotoPath();
                if (photoPath != null && photoPath.startsWith("/uploads/photos/")) {
                    String filename = photoPath.substring("/uploads/photos/".length());
                    Path filePath = Paths.get(uploadDir, filename);
                    Files.deleteIfExists(filePath);
                }
            } catch (IOException e) {
                // ファイル削除に失敗してもデータベースからは削除する
                System.err.println("ファイル削除エラー: " + e.getMessage());
            }
            
            // データベースから削除
            photoRepository.deleteById(id);
            return true;
        }
        return false;
    }

    /**
     * ファイル拡張子を取得
     * 
     * @param filename ファイル名
     * @return 拡張子（.を含む）
     */
    private String getFileExtension(String filename) {
        int lastIndexOf = filename.lastIndexOf(".");
        if (lastIndexOf == -1) {
            return "";
        }
        return filename.substring(lastIndexOf);
    }

    /**
     * 有効な画像拡張子かチェック
     * 
     * @param filename ファイル名
     * @return 有効な場合true
     */
    private boolean isValidImageExtension(String filename) {
        String lowerCaseFilename = filename.toLowerCase();
        return lowerCaseFilename.endsWith(".jpg") ||
               lowerCaseFilename.endsWith(".jpeg") ||
               lowerCaseFilename.endsWith(".png") ||
               lowerCaseFilename.endsWith(".gif") ||
               lowerCaseFilename.endsWith(".webp");
    }
}
