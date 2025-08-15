package com.devwonder.notification_service.service;

import com.devwonder.notification_service.dto.EmailRequest;
import com.devwonder.notification_service.dto.EmailResponse;
import com.devwonder.notification_service.exception.EmailConfigurationException;
import com.devwonder.notification_service.exception.EmailSendingException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {
    
    private final JavaMailSender mailSender;

    public EmailResponse sendEmail(EmailRequest request) {
        try {
            log.info("Sending email to: {} with subject: {}", request.getTo(), request.getSubject());
            
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setTo(request.getTo());
            helper.setSubject(request.getSubject());
            helper.setText(request.getBody(), request.isHtml());
            
            if (request.getFrom() != null && !request.getFrom().isEmpty()) {
                helper.setFrom(request.getFrom());
            }

            mailSender.send(message);
            
            String messageId = UUID.randomUUID().toString();
            log.info("Email sent successfully to: {} with messageId: {}", request.getTo(), messageId);
            
            return EmailResponse.success(request.getTo(), request.getSubject(), messageId);
            
        }
        catch (MessagingException e) {
            log.error("Failed to send email to: {} - Error: {}", request.getTo(), e.getMessage(), e);
            throw new EmailSendingException(
                "Failed to send email due to messaging error: " + e.getMessage(), 
                "MESSAGING_ERROR", 
                e
            );
        }
        catch (MailException e) {
            log.error("Mail configuration error while sending to: {} - Error: {}", request.getTo(), e.getMessage(), e);
            throw new EmailConfigurationException(
                "Email configuration error: " + e.getMessage(), 
                "MAIL_CONFIG_ERROR", 
                e
            );
        }
        catch (Exception e) {
            log.error("Unexpected error while sending email to: {} - Error: {}", request.getTo(), e.getMessage(), e);
            throw new EmailSendingException(
                "An unexpected error occurred while sending email", 
                "UNKNOWN_ERROR", 
                e
            );
        }
    }

    @Async("emailTaskExecutor")
    public CompletableFuture<EmailResponse> sendEmailAsync(EmailRequest request) {
        try {
            log.info("Sending email asynchronously to: {} with subject: {}", request.getTo(), request.getSubject());
            
            EmailResponse response = sendEmail(request);
            
            log.info("Async email sent successfully to: {} with messageId: {}", 
                    request.getTo(), response.getMessageId());
            
            return CompletableFuture.completedFuture(response);
            
        } catch (Exception e) {
            log.error("Async email sending failed for: {} - Error: {}", request.getTo(), e.getMessage(), e);
            
            EmailResponse errorResponse = EmailResponse.failure(
                request.getTo(), 
                request.getSubject(), 
                "ASYNC_EMAIL_ERROR", 
                "Failed to send email asynchronously: " + e.getMessage()
            );
            
            return CompletableFuture.completedFuture(errorResponse);
        }
    }
}
