package com.devwonder.auth_service.controller;

import com.devwonder.auth_service.dto.*;
import com.devwonder.auth_service.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest loginRequest) {
        AuthResponse response = authService.login(loginRequest);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest registerRequest) {
        AuthResponse response = authService.register(registerRequest);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refreshToken(@Valid @RequestBody RefreshTokenRequest refreshRequest) {
        AuthResponse response = authService.refreshToken(refreshRequest.getRefreshToken());
        return ResponseEntity.ok(response);
    }

    @PostMapping("/logout")
    public ResponseEntity<String> logout(@RequestHeader("Authorization") String token) {
        authService.logout(token);
        return ResponseEntity.ok("Logged out successfully");
    }

    @GetMapping("/validate")
    public ResponseEntity<Boolean> validateToken(@RequestHeader("Authorization") String token) {
        boolean isValid = authService.validateToken(token);
        return ResponseEntity.ok(isValid);
    }

    @GetMapping("/profile")
    public ResponseEntity<AuthResponse.UserInfo> getProfile(@RequestHeader("Authorization") String token) {
        AuthResponse.UserInfo userInfo = authService.getUserProfile(token);
        return ResponseEntity.ok(userInfo);
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Auth Service is running");
    }
}