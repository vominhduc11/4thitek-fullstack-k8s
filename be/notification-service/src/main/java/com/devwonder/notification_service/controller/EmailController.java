package com.devwonder.notification_service.controller;

import com.devwonder.notification_service.dto.AsyncEmailResponse;
import com.devwonder.notification_service.dto.EmailRequest;
import com.devwonder.notification_service.dto.EmailResponse;
import com.devwonder.notification_service.service.EmailService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/email")
@RequiredArgsConstructor
@Slf4j
public class EmailController {
    
    private final EmailService emailService;

    @PostMapping("/send")
    public ResponseEntity<EmailResponse> sendEmail(@Valid @RequestBody EmailRequest request) {
        EmailResponse response = emailService.sendEmail(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/send-async")
    public ResponseEntity<AsyncEmailResponse> sendEmailAsync(@Valid @RequestBody EmailRequest request) {
        String taskId = UUID.randomUUID().toString();
        
        // Submit async email task
        CompletableFuture<EmailResponse> future = emailService.sendEmailAsync(request);
        
        // Handle completion asynchronously (optional logging)
        future.whenComplete((result, throwable) -> {
            if (throwable != null) {
                log.error("Async email task {} failed: {}", taskId, throwable.getMessage());
            } else {
                log.info("Async email task {} completed with result: {}", taskId, result.isSuccess());
            }
        });
        
        AsyncEmailResponse response = AsyncEmailResponse.accepted(
            request.getTo(), 
            request.getSubject(), 
            taskId
        );
        
        return ResponseEntity.ok(response);
    }
}
