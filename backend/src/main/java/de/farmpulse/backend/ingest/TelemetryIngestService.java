package de.farmpulse.backend.ingest;

import de.farmpulse.backend.config.BridgeExchangeProperties;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.ingest.dto.TelemetryData;
import de.farmpulse.backend.processing.TelemetryProcessingStep;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Liest telemetry.json ein und historisiert jede tatsaechlich neue
 * Momentaufnahme als {@link TelemetrySnapshot}. telemetry.json ist die
 * einzige Austauschdatei, die die FarmID mitliefert (siehe
 * Bridge/README.md, Abschnitt "Dateiformat: telemetry.json") - dieser
 * Service ist deshalb auch dafuer zustaendig, die {@link Farm} anzulegen
 * bzw. zu aktualisieren, von der world.json/farm.json (siehe
 * {@link WorldIngestService}/{@link FarmIngestService}) abhaengen.
 */
@Service
public class TelemetryIngestService {

    private static final Logger log = LoggerFactory.getLogger(TelemetryIngestService.class);
    private static final String FILENAME = "telemetry.json";

    private final BridgeExchangeProperties properties;
    private final ExchangeFileReader fileReader;
    private final TelemetryProcessingStep processingStep;
    private final FarmRepository farmRepository;
    private final TelemetrySnapshotRepository snapshotRepository;

    private final AtomicReference<Instant> lastProcessedAt = new AtomicReference<>();

    public TelemetryIngestService(BridgeExchangeProperties properties, ExchangeFileReader fileReader,
            TelemetryProcessingStep processingStep, FarmRepository farmRepository,
            TelemetrySnapshotRepository snapshotRepository) {
        this.properties = properties;
        this.fileReader = fileReader;
        this.processingStep = processingStep;
        this.farmRepository = farmRepository;
        this.snapshotRepository = snapshotRepository;
    }

    @Transactional
    public Optional<TelemetrySnapshot> ingestIfChanged() {
        var file = properties.exchangeDirPath().resolve(FILENAME);
        Optional<ExchangeFile<TelemetryData>> read =
                fileReader.readIfNewer(file, lastProcessedAt.get(), TelemetryData.class);
        if (read.isEmpty()) {
            return Optional.empty();
        }

        ExchangeFile<TelemetryData> exchangeFile = read.get();
        TelemetryData data = processingStep.process(exchangeFile.data());
        Instant now = Instant.now();

        Farm farm = farmRepository.findById(data.farmId())
                .map(existing -> {
                    existing.touch(now);
                    return existing;
                })
                .orElseGet(() -> farmRepository.save(new Farm(data.farmId(), now)));

        TelemetrySnapshot snapshot = new TelemetrySnapshot(
                farm,
                data.year(),
                data.month(),
                data.day(),
                data.hour(),
                data.minute(),
                data.daysPerMonth(),
                data.money(),
                exchangeFile.recordedAt(),
                now);
        TelemetrySnapshot saved = snapshotRepository.save(snapshot);

        lastProcessedAt.set(exchangeFile.recordedAt());
        log.debug("telemetry.json eingelesen: farmId={}, recordedAt={}", data.farmId(), exchangeFile.recordedAt());
        return Optional.of(saved);
    }
}
