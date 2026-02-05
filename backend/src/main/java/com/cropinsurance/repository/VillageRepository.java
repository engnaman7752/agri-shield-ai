package com.cropinsurance.repository;

import com.cropinsurance.entity.Village;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface VillageRepository extends JpaRepository<Village, Long> {

    List<Village> findByDistrictId(Long districtId);

    @Query("SELECT v FROM Village v WHERE v.district.name = :districtName")
    List<Village> findByDistrictName(@Param("districtName") String districtName);

    @Query("SELECT v FROM Village v WHERE v.district.name = :districtName AND v.district.state.name = :stateName")
    List<Village> findByDistrictAndState(@Param("districtName") String districtName,
            @Param("stateName") String stateName);

    Optional<Village> findByNameAndDistrictId(String name, Long districtId);
}
