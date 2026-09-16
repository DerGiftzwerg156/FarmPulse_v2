package de.farmpulse.backend.savegame;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.SavegameBackstory;
import de.farmpulse.backend.ingest.event.FarmCreatedEvent;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.SavegameBackstoryRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import de.farmpulse.backend.savegame.dto.SavegameStatusResponse;
import java.time.Instant;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Buendelt die Logik rund um das "Savegame": die einmalige Eingabe der
 * Vorgeschichte (siehe {@link SavegameBackstory}) und die Frage, ob das
 * Savegame bereits als gestartet gilt.
 *
 * <p>Das Savegame gilt als gestartet, sobald
 * <ol>
 *   <li>einmalig eine Vorgeschichte eingegeben wurde,</li>
 *   <li>telemetry.json mindestens einmal gepollt wurde (Farm existiert),</li>
 *   <li>world.json mindestens einmal gepollt wurde, und</li>
 *   <li>farm.json mindestens einmal gepollt wurde (Farm hat einen Namen).</li>
 * </ol>
 * Die aktuelle Architektur geht (wie schon {@link FarmRepository}) von
 * genau einem aktiven Spielstand/einer aktiven Farm pro Instanz aus.
 */
@Service
public class SavegameService {

    private static final Logger log = LoggerFactory.getLogger(SavegameService.class);
    private static final int MAX_BACKSTORY_LENGTH = 20_000;

    private final SavegameBackstoryRepository backstoryRepository;
    private final FarmRepository farmRepository;
    private final TelemetrySnapshotRepository telemetrySnapshotRepository;
    private final WorldSnapshotRepository worldSnapshotRepository;

    public SavegameService(SavegameBackstoryRepository backstoryRepository, FarmRepository farmRepository,
            TelemetrySnapshotRepository telemetrySnapshotRepository, WorldSnapshotRepository worldSnapshotRepository) {
        this.backstoryRepository = backstoryRepository;
        this.farmRepository = farmRepository;
        this.telemetrySnapshotRepository = telemetrySnapshotRepository;
        this.worldSnapshotRepository = worldSnapshotRepository;
    }

    @Transactional(readOnly = true)
    public SavegameStatusResponse getStatus() {
        boolean backstorySubmitted = backstoryRepository.findFirstByOrderByIdAsc().isPresent();
        Optional<Farm> farm = farmRepository.findTopByOrderByUpdatedAtDesc();

        boolean telemetryPolled = farm
                .filter(f -> telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(f.getId()).isPresent())
                .isPresent();
        boolean worldPolled = farm
                .filter(f -> worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(f.getId()).isPresent())
                .isPresent();
        boolean farmDataPolled = farm.filter(f -> f.getName() != null).isPresent();

        boolean started = backstorySubmitted && telemetryPolled && worldPolled && farmDataPolled;
        return new SavegameStatusResponse(started, backstorySubmitted, telemetryPolled, worldPolled, farmDataPolled);
    }

    @Transactional
    public SavegameStatusResponse submitBackstory(String backstory) {
        String trimmed = backstory == null ? "" : backstory.trim();
        if (trimmed.isEmpty()) {
            throw new InvalidBackstoryException("Die Vorgeschichte darf nicht leer sein.");
        }
        if (trimmed.length() > MAX_BACKSTORY_LENGTH) {
            throw new InvalidBackstoryException(
                    "Die Vorgeschichte ist zu lang (max. " + MAX_BACKSTORY_LENGTH + " Zeichen).");
        }
        if (backstoryRepository.findFirstByOrderByIdAsc().isPresent()) {
            throw new BackstoryAlreadySubmittedException("Es wurde bereits einmalig eine Vorgeschichte gespeichert.");
        }

        SavegameBackstory entity = new SavegameBackstory(trimmed, Instant.now());
        farmRepository.findTopByOrderByUpdatedAtDesc().ifPresent(entity::linkToFarm);
        backstoryRepository.save(entity);
        log.debug("Vorgeschichte gespeichert (farmId={})",
                entity.getFarm() != null ? entity.getFarm().getId() : null);

        return getStatus();
    }

    /**
     * Verknuepft eine bereits vor der ersten Farm eingegebene Vorgeschichte
     * nachtraeglich mit der neu angelegten Farm (siehe
     * {@link SavegameBackstory#getFarm()}).
     */
    @EventListener
    @Transactional
    public void onFarmCreated(FarmCreatedEvent event) {
        backstoryRepository.findFirstByFarmIsNullOrderByIdAsc().ifPresent(backstory -> {
            log.debug("Verknuepfe zuvor eingegebene Vorgeschichte mit neu angelegter Farm id={}",
                    event.farm().getId());
            backstory.linkToFarm(event.farm());
        });
    }
}
