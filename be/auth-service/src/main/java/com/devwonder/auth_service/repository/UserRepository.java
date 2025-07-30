package com.devwonder.auth_service.repository;

import com.devwonder.auth_service.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByUsername(String username);

    Optional<User> findByEmail(String email);

    Optional<User> findByUsernameOrEmail(String username, String email);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);

    @Modifying
    @Query("UPDATE User u SET u.lastLogin = :lastLogin WHERE u.id = :id")
    void updateLastLogin(@Param("id") Long id, @Param("lastLogin") LocalDateTime lastLogin);

    @Query("SELECT COUNT(u) FROM User u WHERE u.role = :role")
    long countByRole(@Param("role") User.Role role);

    @Query("SELECT u FROM User u WHERE u.createdAt >= :fromDate")
    java.util.List<User> findUsersCreatedAfter(@Param("fromDate") LocalDateTime fromDate);
}