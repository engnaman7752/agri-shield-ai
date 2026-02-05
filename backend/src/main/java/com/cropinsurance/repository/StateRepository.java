package com.cropinsurance.repository;

import com.cropinsurance.entity.State;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface StateRepository extends JpaRepository<State, Long> {

    Optional<State> findByName(String name);

    Optional<State> findByCode(String code);
}
