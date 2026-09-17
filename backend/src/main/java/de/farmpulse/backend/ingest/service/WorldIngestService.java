package de.farmpulse.backend.ingest.service;

import de.farmpulse.backend.config.BridgeExchangeProperties;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.FieldSnapshot;
import de.farmpulse.backend.domain.StorageSnapshot;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.ingest.dto.WorldData;
import de.farmpulse.backend.processing.WorldProcessingStep;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Liest world.json ein und historisiert jede tatsaechlich neue
 * Momentaufnahme als {@link WorldSnapshot} samt Feld-/Lagerbestandsliste.
 *
 * <p>world.json enthaelt selbst keine FarmID (siehe Bridge/README.md,
 * Abschnitt "Dateiformat: world.json") - siehe {@link FarmRepository} fuer
 * die Begruendung, warum die zuletzt ueber telemetry.json gesehene Farm
 * verwendet wird. Ist noch keine Farm bekannt (telemetry.json wurde noch
 * nicht verarbeitet), wird dieser Poll uebersprungen und beim naechsten
 * Intervall erneut versucht.
 */
@Service
public class WorldIngestService {

    private static final Logger log = LoggerFactory.getLogger(WorldIngestService.class);
    private static final String FILENAME = "world.json";

    private final BridgeExchangeProperties properties;
    private final ExchangeFileReader fileReader;
    private final WorldProcessingStep processingStep;
    private final FarmRepository farmRepository;
    private final WorldSnapshotRepository snapshotRepository;

    private final AtomicReference<Instant> lastProcessedAt = new AtomicReference<>();

    public WorldIngestService(BridgeExchangeProperties properties, ExchangeFileReader fileReader,
            WorldProcessingStep processingStep, FarmRepository farmRepository,
            WorldSnapshotRepository snapshotRepository) {
        this.properties = properties;
        this.fileReader = fileReader;
        this.processingStep = processingStep;
        this.farmRepository = farmRepository;
        this.snapshotRepository = snapshotRepository;
    }

    @Transactional
    public Optional<WorldSnapshot> ingestIfChanged() {
        var file = properties.exchangeDirPath().resolve(FILENAME);
        log.debug("Pruefe {} auf Aenderungen (zuletzt verarbeitet: {})", file, lastProcessedAt.get());
        Optional<ExchangeFile<WorldData>> read =
                fileReader.readIfNewer(file, lastProcessedAt.get(), WorldData.class);
        if (read.isEmpty()) {
            return Optional.empty();
        }

        Optional<Farm> farm = farmRepository.findTopByOrderByUpdatedAtDesc();
        if (farm.isEmpty()) {
            log.debug("world.json geaendert, aber noch keine Farm aus telemetry.json bekannt - warte auf naechsten Poll.");
            return Optional.empty();
        }

        ExchangeFile<WorldData> exchangeFile = read.get();
        log.debug("world.json geaendert (recordedAt={}) - Verarbeitungsschritt starten", exchangeFile.recordedAt());
        WorldData data = processingStep.process(exchangeFile.data());
        Instant now = Instant.now();

        WorldSnapshot snapshot = new WorldSnapshot(farm.get(), data.fleetValue(), exchangeFile.recordedAt(), now);
        data.fields().forEach(field -> snapshot.addField(
                new FieldSnapshot(field.fieldId(), field.ownerFarmId(), field.sizeHa(), field.price(),
                        field.fruitType(), field.growthState(), field.estimatedYieldLiters())));
        data.storages().forEach(storage -> snapshot.addStorage(
                new StorageSnapshot(storage.fillType(), storage.amount(), storage.capacity(),
                        storage.currentPricePer1000L(), storage.bestPricePer1000L(), storage.bestPricePeriod(),
                        storage.bestPricePeriodLabel())));

        log.debug("Speichere WorldSnapshot: farmId={}, fleetValue={}, felder={}, lagerbestaende={}",
                farm.get().getId(), data.fleetValue(), data.fields().size(), data.storages().size());
        WorldSnapshot saved = snapshotRepository.save(snapshot);

        lastProcessedAt.set(exchangeFile.recordedAt());
        log.debug("world.json eingelesen: snapshotId={}, {} Felder, {} Lagerbestaende, recordedAt={}",
                saved.getId(), data.fields().size(), data.storages().size(), exchangeFile.recordedAt());
        return Optional.of(saved);
    }
}
