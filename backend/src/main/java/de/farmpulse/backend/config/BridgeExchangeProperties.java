package de.farmpulse.backend.config;

import java.nio.file.Path;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Konfiguration des Austauschordners und der Poll-Intervalle, mit denen das
 * Backend die von der FarmPulse Bridge geschriebenen Dateien einliest. Die
 * Standardwerte der Intervalle sind an FarmPulseBridge.POLL_INTERVAL_MS /
 * WORLD_POLL_INTERVAL_MS angelehnt (siehe Bridge/FarmPulseBridge.lua).
 */
@ConfigurationProperties(prefix = "farmpulse.bridge")
public record BridgeExchangeProperties(
        Path exchangeDir,
        long telemetryIntervalMs,
        long worldIntervalMs,
        long farmIntervalMs) {

    public BridgeExchangeProperties {
        if (telemetryIntervalMs <= 0) {
            telemetryIntervalMs = 5000;
        }
        if (worldIntervalMs <= 0) {
            worldIntervalMs = 30000;
        }
        if (farmIntervalMs <= 0) {
            farmIntervalMs = 60000;
        }
    }
}
