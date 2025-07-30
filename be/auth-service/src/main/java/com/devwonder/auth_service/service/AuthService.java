package com.devwonder.auth_service.service;

import com.devwonder.auth_service.dto.*;
import com.devwonder.auth_service.entity.User;
import com.devwonder.auth_service.repository.UserRepository;
import com.devwonder.auth_service.util.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@Transactional
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private AuthenticationManager authenticationManager;

    public AuthResponse login(LoginRequest loginRequest) {
        // Authenticate user
        Authentication authentication = authenticationManager.authenticate(
            new UsernamePasswordAuthenticationToken(
                loginRequest.getUsernameOrEmail(),
                loginRequest.getPassword()
            )
        );

        // Get user details
        User user = userRepository.findByUsernameOrEmail(
            loginRequest.getUsernameOrEmail(),
            loginRequest.getUsernameOrEmail()
        ).orElseThrow(() -> new UsernameNotFoundException("User not found"));

        // Update last login
        userRepository.updateLastLogin(user.getId(), LocalDateTime.now());

        // Generate tokens
        String accessToken = jwtUtil.generateToken(user);
        String refreshToken = jwtUtil.generateRefreshToken(user);

        return new AuthResponse(accessToken, refreshToken, jwtUtil.getExpirationTime(), user);
    }

    public AuthResponse register(RegisterRequest registerRequest) {
        // Check if username exists
        if (userRepository.existsByUsername(registerRequest.getUsername())) {
            throw new RuntimeException("Username is already taken");
        }

        // Check if email exists
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            throw new RuntimeException("Email is already registered");
        }

        // Create new user
        User user = new User();
        user.setUsername(registerRequest.getUsername());
        user.setEmail(registerRequest.getEmail());
        user.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        user.setFullName(registerRequest.getFullName());
        user.setRole(User.Role.USER);

        // Save user
        user = userRepository.save(user);

        // Generate tokens
        String accessToken = jwtUtil.generateToken(user);
        String refreshToken = jwtUtil.generateRefreshToken(user);

        return new AuthResponse(accessToken, refreshToken, jwtUtil.getExpirationTime(), user);
    }

    public AuthResponse refreshToken(String refreshToken) {
        if (!jwtUtil.validateToken(refreshToken) || !jwtUtil.isRefreshToken(refreshToken)) {
            throw new RuntimeException("Invalid refresh token");
        }

        String username = jwtUtil.extractUsername(refreshToken);
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        // Generate new tokens
        String newAccessToken = jwtUtil.generateToken(user);
        String newRefreshToken = jwtUtil.generateRefreshToken(user);

        return new AuthResponse(newAccessToken, newRefreshToken, jwtUtil.getExpirationTime(), user);
    }

    public void logout(String authHeader) {
        // In a real application, you might want to blacklist the token
        // For now, we'll just validate the token format
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Invalid token format");
        }
        
        String token = authHeader.substring(7);
        if (!jwtUtil.validateToken(token)) {
            throw new RuntimeException("Invalid token");
        }
        
        // Token blacklisting logic would go here
        // For now, logout is handled client-side by removing the token
    }

    public boolean validateToken(String authHeader) {
        try {
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                return false;
            }
            
            String token = authHeader.substring(7);
            return jwtUtil.validateToken(token);
        } catch (Exception e) {
            return false;
        }
    }

    public AuthResponse.UserInfo getUserProfile(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Invalid token format");
        }

        String token = authHeader.substring(7);
        if (!jwtUtil.validateToken(token)) {
            throw new RuntimeException("Invalid token");
        }

        String username = jwtUtil.extractUsername(token);
        User user = userRepository.findByUsername(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        return new AuthResponse.UserInfo(user);
    }
}