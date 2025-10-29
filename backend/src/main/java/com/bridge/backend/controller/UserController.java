package com.bridge.backend.controller;

import com.bridge.backend.entity.User; // Userエンティティをインポート
import com.bridge.backend.repository.UserRepository; // UserRepositoryをインポート
import org.springframework.web.bind.annotation.*; // Spring WebのRESTコントローラ関連のアノテーションをインポート

import java.util.List; // Javaのリスト型をインポート

/**
 * UserController
 * このクラスは、ユーザー情報に関するAPIエンドポイントを定義するRESTコントローラです。
 * Flutterフロントエンドからのリクエストを受け取り、ユーザーデータを返します。
 *
 * チームメンバーへ:
 *   - `@RestController`: このクラスがRESTfulなWebサービスを提供することを示します。
 *   - `@RequestMapping("/api/users")`: このコントローラが処理するベースURLパスを定義します。
 *   - `@CrossOrigin(origins = "*")`: 異なるオリジンからのリクエストを許可します。
 *     開発中は `*` で全て許可していますが、本番環境では特定のオリジンに制限することが推奨されます。
 */
@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*") // すべてのオリジンからのアクセスを許可 (開発用)
public class UserController {

    // UserRepositoryを注入するためのフィールド
    private final UserRepository userRepository;

    /**
     * コンストラクタインジェクション
     * SpringがUserRepositoryのインスタンスを自動的に提供します。
     *
     * @param userRepository ユーザーデータへのアクセスを提供するリポジトリ
     */
    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * すべてのユーザーを取得するAPIエンドポイント
     * HTTP GETリクエスト `/api/users` に対応します。
     *
     * @return データベースに保存されているすべてのユーザーのリスト
     */
    @GetMapping // HTTP GETリクエストに対応
    public List<User> getAllUsers() {
        return userRepository.findAll(); // UserRepositoryを使ってすべてのユーザーを取得
    }
}
