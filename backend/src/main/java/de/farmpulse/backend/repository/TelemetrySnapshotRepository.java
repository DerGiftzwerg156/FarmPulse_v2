package de.farmpulse.backend.repository;

import de.farmpulse.backend.domain.TelemetrySnapshot;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TelemetrySnapshotRepository extends JpaRepository<TelemetrySnapshot, Long> {

    Optional<TelemetrySnapshot> findTopByFarmIdOrderByRecordedAtDesc(Long farmId);
}
