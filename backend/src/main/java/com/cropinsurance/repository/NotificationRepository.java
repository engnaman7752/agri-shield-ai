package com.cropinsurance.repository;

import com.cropinsurance.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    List<Notification> findByFarmerIdOrderBySentAtDesc(UUID farmerId);

    List<Notification> findByFarmerIdAndIsReadFalse(UUID farmerId);

    long countByFarmerIdAndIsReadFalse(UUID farmerId);
}
