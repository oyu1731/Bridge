package com.bridge.backend.repository;

import com.bridge.backend.entity.User; // Userエンティティをインポート
import org.springframework.data.jpa.repository.JpaRepository; // Spring Data JPAのJpaRepositoryをインポート

/**
 * UserRepository
 * このインターフェースは、Userエンティティのデータアクセス操作を提供します。
 * Spring Data JPAの `JpaRepository` を継承することで、CRUD (作成、読み取り、更新、削除) 操作を
 * 自動的に提供してくれます。
 *
 * チームメンバーへ:
 *   - `JpaRepository<User, Integer>`:
 *     - `User`: このリポジトリが扱うエンティティの型。
 *     - `Integer`: エンティティの主キーの型。
 *   - 通常、ここにカスタムクエリメソッドを追加することもできますが、
 *     基本的なCRUD操作は `JpaRepository` が提供するため、空のインターフェースで十分です。
 */
public interface UserRepository extends JpaRepository<User, Integer> {
}
