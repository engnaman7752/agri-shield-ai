package com.cropinsurance.repository;

import com.cropinsurance.entity.District;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DistrictRepository extends JpaRepository<District, Long> {

    List<District> findByStateId(Long stateId);

    @Query("SELECT d FROM District d WHERE d.state.name = :stateName")
    List<District> findByStateName(@Param("stateName") String stateName);

    @Query("SELECT d FROM District d WHERE d.state.code = :stateCode")
    List<District> findByStateCode(@Param("stateCode") String stateCode);

    Optional<District> findByNameAndStateId(String name, Long stateId);
}
