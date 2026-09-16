package de.farmpulse.backend.config;

import java.nio.file.Path;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Konfiguration des Austauschordners und der Poll-Intervalle, mit denen das
 * Backend die von der FarmPulse Bridge geschriebenen Dateien einliest. Die
 * Standardwerte der Intervalle sind an FarmPulseBridge.POLL_INTERVAL_MS /
 * WORLD_POLL_INTERVAL_MS angelehnt (siehe Bridge/FarmPulseBridge.lua).
 *
 * <p>{@code exchangeDir} ist bewusst ein {@code String} statt direkt
 * {@link Path}: Spring bindet {@link Path}-Properties in einer echten
 * Webanwendung ueber die Servlet-{@code Resource}-Aufloesung
 * (ServletContextResource) statt ueber ein einfaches {@code Paths.get(...)}
 * - ein relativer Pfad mit {@code ..} (Standardwert, siehe application.yml)
 * laesst sich darueber nicht ueber die Servlet-Context-Wurzel hinaus
 * aufloesen ("has been normalized to [null] which is not valid"). Deshalb
 * wird der rohe String gebunden und selbst in einen {@link Path}
 * umgewandelt (siehe {@link #exchangeDirPath()}).
 */
@ConfigurationProperties(prefix = "farmpulse.bridge")
public record BridgeExchangeProperties(
        String exchangeDir,
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

    public Path exchangeDirPath() {
        return Path.of(exchangeDir);
    }
}
