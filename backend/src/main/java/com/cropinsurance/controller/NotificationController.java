package com.cropinsurance.controller;

import com.cropinsurance.dto.response.ApiResponse;
import com.cropinsurance.entity.Notification;
import com.cropinsurance.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Notification Controller
 * Farmer notifications
 */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Tag(name = "Notifications", description = "Farmer notifications")
@SecurityRequirement(name = "bearerAuth")
public class NotificationController {

    private final NotificationService notificationService;

    /**
     * Get all notifications
     */
    @GetMapping
    @Operation(summary = "Get all notifications for farmer")
    public ResponseEntity<ApiResponse<List<Notification>>> getNotifications(
            @AuthenticationPrincipal String userId) {
        List<Notification> notifications = notificationService.getFarmerNotifications(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(notifications));
    }

    /**
     * Get unread count
     */
    @GetMapping("/unread-count")
    @Operation(summary = "Get unread notification count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount(
            @AuthenticationPrincipal String userId) {
        long count = notificationService.getUnreadCount(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(count));
    }

    /**
     * Mark notification as read
     */
    @PutMapping("/{notificationId}/read")
    @Operation(summary = "Mark notification as read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(
            @AuthenticationPrincipal String userId,
            @PathVariable UUID notificationId) {
        notificationService.markAsRead(UUID.fromString(userId), notificationId);
        return ResponseEntity.ok(ApiResponse.success(null, "Marked as read"));
    }

    /**
     * Mark all as read
     */
    @PutMapping("/read-all")
    @Operation(summary = "Mark all notifications as read")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(
            @AuthenticationPrincipal String userId) {
        notificationService.markAllAsRead(UUID.fromString(userId));
        return ResponseEntity.ok(ApiResponse.success(null, "All marked as read"));
    }
}
