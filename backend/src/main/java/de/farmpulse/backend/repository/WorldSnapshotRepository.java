package de.farmpulse.backend.repository;

import de.farmpulse.backend.domain.WorldSnapshot;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WorldSnapshotRepository extends JpaRepository<WorldSnapshot, Long> {

    Optional<WorldSnapshot> findTopByFarmIdOrderByRecordedAtDesc(Long farmId);
}
