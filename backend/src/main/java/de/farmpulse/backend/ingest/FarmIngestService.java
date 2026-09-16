package de.farmpulse.backend.ingest;

import de.farmpulse.backend.config.BridgeExchangeProperties;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.ingest.dto.FarmData;
import de.farmpulse.backend.processing.FarmProcessingStep;
import de.farmpulse.backend.repository.FarmRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Liest farm.json ein und aktualisiert Name/Spielername der zugehoerigen
 * {@link Farm}. farm.json wird von der Bridge nur einmalig bei Aktivierung
 * geschrieben und aendert sich praktisch nie (siehe Bridge/README.md,
 * Abschnitt "Dateiformat: farm.json") - trotzdem wird die Datei weiterhin
 * periodisch (Standardintervall deutlich seltener als telemetry.json/
 * world.json) auf Aenderungen geprueft, damit z.B. ein Hof-/Spielername-
 * Wechsel im laufenden Betrieb erkannt wird.
 *
 * <p>farm.json enthaelt selbst keine FarmID - siehe {@link FarmRepository}
 * fuer die Begruendung, warum die zuletzt ueber telemetry.json gesehene
 * Farm verwendet wird.
 */
@Service
public class FarmIngestService {

    private static final Logger log = LoggerFactory.getLogger(FarmIngestService.class);
    private static final String FILENAME = "farm.json";

    private final BridgeExchangeProperties properties;
    private final ExchangeFileReader fileReader;
    private final FarmProcessingStep processingStep;
    private final FarmRepository farmRepository;

    private final AtomicReference<Instant> lastProcessedAt = new AtomicReference<>();

    public FarmIngestService(BridgeExchangeProperties properties, ExchangeFileReader fileReader,
            FarmProcessingStep processingStep, FarmRepository farmRepository) {
        this.properties = properties;
        this.fileReader = fileReader;
        this.processingStep = processingStep;
        this.farmRepository = farmRepository;
    }

    @Transactional
    public Optional<Farm> ingestIfChanged() {
        var file = properties.exchangeDirPath().resolve(FILENAME);
        log.debug("Pruefe {} auf Aenderungen (zuletzt verarbeitet: {})", file, lastProcessedAt.get());
        Optional<ExchangeFile<FarmData>> read =
                fileReader.readIfNewer(file, lastProcessedAt.get(), FarmData.class);
        if (read.isEmpty()) {
            return Optional.empty();
        }

        Optional<Farm> farm = farmRepository.findTopByOrderByUpdatedAtDesc();
        if (farm.isEmpty()) {
            log.debug("farm.json geaendert, aber noch keine Farm aus telemetry.json bekannt - warte auf naechsten Poll.");
            return Optional.empty();
        }

        ExchangeFile<FarmData> exchangeFile = read.get();
        log.debug("farm.json geaendert (recordedAt={}) - Verarbeitungsschritt starten", exchangeFile.recordedAt());
        FarmData data = processingStep.process(exchangeFile.data());

        Farm existing = farm.get();
        log.debug("Aktualisiere Farm id={}: farmName={}, playerName={}", existing.getId(), data.farmName(), data.playerName());
        existing.updateIdentity(data.farmName(), data.playerName(), Instant.now());

        lastProcessedAt.set(exchangeFile.recordedAt());
        log.debug("farm.json eingelesen: farmId={}, farmName={}, playerName={}",
                existing.getId(), data.farmName(), data.playerName());
        return Optional.of(existing);
    }
}
