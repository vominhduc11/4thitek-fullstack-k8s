package com.devwonder.notification_service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AsyncEmailResponse {
    
    private boolean accepted;
    
    private String message;
    
    private String taskId;
    
    private String to;
    
    private String subject;
    
    private LocalDateTime submittedAt;
    
    private String status;
    
    public static AsyncEmailResponse accepted(String to, String subject, String taskId) {
        return AsyncEmailResponse.builder()
                .accepted(true)
                .message("Email has been queued for sending")
                .taskId(taskId)
                .to(to)
                .subject(subject)
                .submittedAt(LocalDateTime.now())
                .status("QUEUED")
                .build();
    }
    
    public static AsyncEmailResponse rejected(String to, String subject, String reason) {
        return AsyncEmailResponse.builder()
                .accepted(false)
                .message("Email was rejected: " + reason)
                .to(to)
                .subject(subject)
                .submittedAt(LocalDateTime.now())
                .status("REJECTED")
                .build();
    }
}