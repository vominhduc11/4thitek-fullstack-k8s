package com.devwonder.notification_service.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.Builder;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmailResponse {
    
    private boolean success;
    
    private String message;
    
    private String messageId;
    
    private String to;
    
    private String subject;
    
    private LocalDateTime sentAt;
    
    private String errorCode;
    
    private String errorMessage;
    
    public static EmailResponse success(String to, String subject, String messageId) {
        return EmailResponse.builder()
                .success(true)
                .message("Email sent successfully")
                .messageId(messageId)
                .to(to)
                .subject(subject)
                .sentAt(LocalDateTime.now())
                .build();
    }
    
    public static EmailResponse failure(String to, String subject, String errorCode, String errorMessage) {
        return EmailResponse.builder()
                .success(false)
                .message("Failed to send email")
                .to(to)
                .subject(subject)
                .errorCode(errorCode)
                .errorMessage(errorMessage)
                .sentAt(LocalDateTime.now())
                .build();
    }
}