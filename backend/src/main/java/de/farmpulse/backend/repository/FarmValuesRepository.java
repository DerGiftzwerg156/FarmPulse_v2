package de.farmpulse.backend.repository;

import de.farmpulse.backend.domain.FarmValues;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FarmValuesRepository extends JpaRepository<FarmValues, Long> {
}
