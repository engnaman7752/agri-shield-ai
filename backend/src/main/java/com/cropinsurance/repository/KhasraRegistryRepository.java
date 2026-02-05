package com.cropinsurance.repository;

import com.cropinsurance.entity.KhasraRegistry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface KhasraRegistryRepository extends JpaRepository<KhasraRegistry, UUID> {

    List<KhasraRegistry> findByVillageId(Long villageId);

    @Query("SELECT k FROM KhasraRegistry k WHERE k.village.id = :villageId AND k.isRegistered = false")
    List<KhasraRegistry> findAvailableByVillageId(@Param("villageId") Long villageId);

    @Query("SELECT k FROM KhasraRegistry k WHERE k.village.name = :villageName AND k.isRegistered = false")
    List<KhasraRegistry> findAvailableByVillageName(@Param("villageName") String villageName);

    @Query("SELECT k FROM KhasraRegistry k WHERE k.village.name = :villageName " +
            "AND k.village.district.name = :districtName " +
            "AND k.village.district.state.name = :stateName " +
            "AND k.isRegistered = false")
    List<KhasraRegistry> findAvailableByLocation(@Param("stateName") String stateName,
            @Param("districtName") String districtName, @Param("villageName") String villageName);

    Optional<KhasraRegistry> findByKhasraNumber(String khasraNumber);
}
