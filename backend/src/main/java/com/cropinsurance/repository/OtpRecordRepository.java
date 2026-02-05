package com.cropinsurance.repository;

import com.cropinsurance.entity.OtpRecord;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OtpRecordRepository extends JpaRepository<OtpRecord, UUID> {

    @Query("SELECT o FROM OtpRecord o WHERE o.phone = :phone AND o.isUsed = false AND o.expiresAt > :now ORDER BY o.createdAt DESC")
    Optional<OtpRecord> findValidOtp(@Param("phone") String phone, @Param("now") LocalDateTime now);

    @Modifying
    @Query("UPDATE OtpRecord o SET o.isUsed = true WHERE o.phone = :phone")
    void markAllAsUsed(@Param("phone") String phone);

    @Modifying
    @Query("DELETE FROM OtpRecord o WHERE o.expiresAt < :now")
    void deleteExpired(@Param("now") LocalDateTime now);
}
