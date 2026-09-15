package de.farmpulse.backend.ingest;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Stoesst die drei Ingest-Services periodisch an. Die Standardintervalle
 * orientieren sich an den Schreibintervallen der Bridge selbst
 * (FarmPulseBridge.POLL_INTERVAL_MS / WORLD_POLL_INTERVAL_MS, siehe
 * Bridge/FarmPulseBridge.lua) - konfigurierbar ueber
 * farmpulse.bridge.telemetry-interval-ms/world-interval-ms/farm-interval-ms
 * (siehe application.yml).
 */
@Component
public class IngestScheduler {

    private final TelemetryIngestService telemetryIngestService;
    private final WorldIngestService worldIngestService;
    private final FarmIngestService farmIngestService;

    public IngestScheduler(TelemetryIngestService telemetryIngestService, WorldIngestService worldIngestService,
            FarmIngestService farmIngestService) {
        this.telemetryIngestService = telemetryIngestService;
        this.worldIngestService = worldIngestService;
        this.farmIngestService = farmIngestService;
    }

    @Scheduled(fixedDelayString = "${farmpulse.bridge.telemetry-interval-ms:5000}")
    public void pollTelemetry() {
        telemetryIngestService.ingestIfChanged();
    }

    @Scheduled(fixedDelayString = "${farmpulse.bridge.world-interval-ms:30000}")
    public void pollWorld() {
        worldIngestService.ingestIfChanged();
    }

    @Scheduled(fixedDelayString = "${farmpulse.bridge.farm-interval-ms:60000}")
    public void pollFarm() {
        farmIngestService.ingestIfChanged();
    }
}
