package com.devwonder.notification_service.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ErrorResponse {
    
    private String message;
    
    private String errorCode;
    
    private LocalDateTime timestamp;
    
    private String path;
    
    private int status;
    
    private List<String> details;
    
    public static ErrorResponse of(String message, String errorCode, String path, int status) {
        return ErrorResponse.builder()
                .message(message)
                .errorCode(errorCode)
                .timestamp(LocalDateTime.now())
                .path(path)
                .status(status)
                .build();
    }
    
    public static ErrorResponse of(String message, String errorCode, String path, int status, List<String> details) {
        return ErrorResponse.builder()
                .message(message)
                .errorCode(errorCode)
                .timestamp(LocalDateTime.now())
                .path(path)
                .status(status)
                .details(details)
                .build();
    }
}