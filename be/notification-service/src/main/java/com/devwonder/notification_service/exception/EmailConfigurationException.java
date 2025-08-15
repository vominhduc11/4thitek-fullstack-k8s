package com.devwonder.notification_service.exception;

public class EmailConfigurationException extends RuntimeException {
    
    private final String errorCode;
    
    public EmailConfigurationException(String message) {
        super(message);
        this.errorCode = "EMAIL_CONFIG_ERROR";
    }
    
    public EmailConfigurationException(String message, String errorCode) {
        super(message);
        this.errorCode = errorCode;
    }
    
    public EmailConfigurationException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = "EMAIL_CONFIG_ERROR";
    }
    
    public EmailConfigurationException(String message, String errorCode, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }
    
    public String getErrorCode() {
        return errorCode;
    }
}