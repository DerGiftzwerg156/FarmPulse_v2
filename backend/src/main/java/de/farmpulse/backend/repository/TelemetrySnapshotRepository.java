package de.farmpulse.backend.repository;

import de.farmpulse.backend.domain.TelemetrySnapshot;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TelemetrySnapshotRepository extends JpaRepository<TelemetrySnapshot, Long> {

    Optional<TelemetrySnapshot> findTopByFarmIdOrderByRecordedAtDesc(Long farmId);

    /**
     * Fuer den Kontostand-Verlauf (Sparkline im Dashboard): die zuletzt
     * aufgezeichneten Snapshots einer Farm, neueste zuerst. Anzahl wird
     * ueber {@code pageable} begrenzt.
     */
    List<TelemetrySnapshot> findByFarmIdOrderByRecordedAtDesc(Long farmId, Pageable pageable);
}
