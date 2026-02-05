package com.cropinsurance.service;

import com.cropinsurance.entity.Notification;
import com.cropinsurance.entity.enums.NotificationType;
import com.cropinsurance.exception.ResourceNotFoundException;
import com.cropinsurance.repository.FarmerRepository;
import com.cropinsurance.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Notification Service - Send and manage notifications
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final FarmerRepository farmerRepository;
    private final SmsService smsService;

    /**
     * Send general notification
     */
    @Transactional
    public void sendNotification(UUID farmerId, String title, String message, NotificationType type) {
        var farmer = farmerRepository.findById(farmerId)
                .orElseThrow(() -> new ResourceNotFoundException("Farmer", "id", farmerId));

        Notification notification = Notification.builder()
                .farmer(farmer)
                .title(title)
                .message(message)
                .type(type)
                .build();

        notificationRepository.save(notification);
        log.info("📢 Notification sent to {}: {}", farmer.getName(), title);

        // Also send SMS for important notifications
        if (type == NotificationType.CLAIM || type == NotificationType.PAYMENT) {
            smsService.sendSms(farmer.getPhone(), title + ": " + message);
        }
    }

    /**
     * Send insurance notification
     */
    public void sendInsuranceNotification(UUID farmerId, String title, String message) {
        sendNotification(farmerId, title, message, NotificationType.INSURANCE);
    }

    /**
     * Send claim notification
     */
    public void sendClaimNotification(UUID farmerId, String title, String message) {
        sendNotification(farmerId, title, message, NotificationType.CLAIM);
    }

    /**
     * Send verification notification
     */
    public void sendVerificationNotification(UUID farmerId, String title, String message) {
        sendNotification(farmerId, title, message, NotificationType.VERIFICATION);
    }

    /**
     * Get farmer notifications
     */
    public List<Notification> getFarmerNotifications(UUID farmerId) {
        return notificationRepository.findByFarmerIdOrderBySentAtDesc(farmerId);
    }

    /**
     * Get unread count
     */
    public long getUnreadCount(UUID farmerId) {
        return notificationRepository.countByFarmerIdAndIsReadFalse(farmerId);
    }

    /**
     * Mark notification as read
     */
    @Transactional
    public void markAsRead(UUID farmerId, UUID notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification", "id", notificationId));

        if (!notification.getFarmer().getId().equals(farmerId)) {
            throw new ResourceNotFoundException("Notification", "id", notificationId);
        }

        notification.setIsRead(true);
        notificationRepository.save(notification);
    }

    /**
     * Mark all as read
     */
    @Transactional
    public void markAllAsRead(UUID farmerId) {
        List<Notification> unread = notificationRepository.findByFarmerIdAndIsReadFalse(farmerId);
        unread.forEach(n -> n.setIsRead(true));
        notificationRepository.saveAll(unread);
    }
}
