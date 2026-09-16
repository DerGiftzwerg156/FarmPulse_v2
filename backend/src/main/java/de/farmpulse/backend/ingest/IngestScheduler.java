package de.farmpulse.backend.ingest;

import de.farmpulse.backend.config.BridgeExchangeProperties;
import de.farmpulse.backend.ingest.service.FarmIngestService;
import de.farmpulse.backend.ingest.service.TelemetryIngestService;
import de.farmpulse.backend.ingest.service.WorldIngestService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
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

    private static final Logger log = LoggerFactory.getLogger(IngestScheduler.class);

    private final BridgeExchangeProperties properties;
    private final TelemetryIngestService telemetryIngestService;
    private final WorldIngestService worldIngestService;
    private final FarmIngestService farmIngestService;

    public IngestScheduler(BridgeExchangeProperties properties, TelemetryIngestService telemetryIngestService,
            WorldIngestService worldIngestService, FarmIngestService farmIngestService) {
        this.properties = properties;
        this.telemetryIngestService = telemetryIngestService;
        this.worldIngestService = worldIngestService;
        this.farmIngestService = farmIngestService;
    }

    /**
     * Einmalige, gut sichtbare Log-Zeile nach dem Start (INFO, unabhaengig
     * vom konfigurierten Log-Level): zeigt den tatsaechlich verwendeten,
     * aufgeloesten Austauschordner - u.a. um Konfigurationsfehler wie einen
     * falsch aufgeloesten relativen Pfad sofort erkennbar zu machen.
     */
    @EventListener(ApplicationReadyEvent.class)
    public void logStartupConfiguration() {
        log.info("Ingest-Scheduler bereit: exchangeDir={} (aufgeloest von \"{}\"), "
                        + "telemetryIntervalMs={}, worldIntervalMs={}, farmIntervalMs={}",
                properties.exchangeDirPath().toAbsolutePath(), properties.exchangeDir(),
                properties.telemetryIntervalMs(), properties.worldIntervalMs(), properties.farmIntervalMs());
    }

    @Scheduled(fixedDelayString = "${farmpulse.bridge.telemetry-interval-ms:5000}")
    public void pollTelemetry() {
        log.debug("Scheduler-Tick: telemetry.json pruefen");
        telemetryIngestService.ingestIfChanged();
    }

    @Scheduled(fixedDelayString = "${farmpulse.bridge.world-interval-ms:30000}")
    public void pollWorld() {
        log.debug("Scheduler-Tick: world.json pruefen");
        worldIngestService.ingestIfChanged();
    }

    @Scheduled(fixedDelayString = "${farmpulse.bridge.farm-interval-ms:60000}")
    public void pollFarm() {
        log.debug("Scheduler-Tick: farm.json pruefen");
        farmIngestService.ingestIfChanged();
    }
}
