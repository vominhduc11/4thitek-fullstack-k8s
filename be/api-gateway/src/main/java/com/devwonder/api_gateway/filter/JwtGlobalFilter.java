package com.devwonder.api_gateway.filter;

import com.devwonder.api_gateway.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
@Order(1)
@Slf4j
public class JwtGlobalFilter extends OncePerRequestFilter {

    @Autowired
    private JwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain) throws ServletException, IOException {
        
        String authHeader = request.getHeader("Authorization");
        
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            
            try {
                if (jwtUtil.validateToken(token)) {
                    String username = jwtUtil.extractUsername(token);
                    String role = jwtUtil.extractRole(token);
                    
                    // Set authentication in SecurityContext
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                        username, null, Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role))
                    );
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                    
                    log.debug("JWT authentication successful for user: {}", username);
                    filterChain.doFilter(request, response);
                    return;
                } else {
                    log.debug("JWT token validation failed");
                }
            } catch (Exception e) {
                log.warn("JWT token processing error: {}", e.getMessage());
            }
        }
        
        // Continue without JWT info (SecurityConfig will handle authorization)
        filterChain.doFilter(request, response);
    }
}