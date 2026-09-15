package de.farmpulse.backend.ingest;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Manueller Trigger fuer einen einmaligen Ingest-Durchlauf, zusaetzlich zum
 * regulaeren {@link IngestScheduler}-Betrieb - z.B. fuer Tests oder um nach
 * dem Start nicht auf den ersten Scheduler-Tick warten zu muessen.
 */
@RestController
@RequestMapping("/api/ingest")
public class IngestController {

    private final TelemetryIngestService telemetryIngestService;
    private final WorldIngestService worldIngestService;
    private final FarmIngestService farmIngestService;

    public IngestController(TelemetryIngestService telemetryIngestService, WorldIngestService worldIngestService,
            FarmIngestService farmIngestService) {
        this.telemetryIngestService = telemetryIngestService;
        this.worldIngestService = worldIngestService;
        this.farmIngestService = farmIngestService;
    }

    @PostMapping("/trigger")
    public IngestTriggerResult trigger() {
        boolean telemetryIngested = telemetryIngestService.ingestIfChanged().isPresent();
        boolean worldIngested = worldIngestService.ingestIfChanged().isPresent();
        boolean farmIngested = farmIngestService.ingestIfChanged().isPresent();
        return new IngestTriggerResult(telemetryIngested, worldIngested, farmIngested);
    }
}
