package com.devwonder.notification_service.exception;

public class EmailSendingException extends RuntimeException {
    
    private final String errorCode;
    
    public EmailSendingException(String message) {
        super(message);
        this.errorCode = "EMAIL_SEND_ERROR";
    }
    
    public EmailSendingException(String message, String errorCode) {
        super(message);
        this.errorCode = errorCode;
    }
    
    public EmailSendingException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = "EMAIL_SEND_ERROR";
    }
    
    public EmailSendingException(String message, String errorCode, Throwable cause) {
        super(message, cause);
        this.errorCode = errorCode;
    }
    
    public String getErrorCode() {
        return errorCode;
    }
}