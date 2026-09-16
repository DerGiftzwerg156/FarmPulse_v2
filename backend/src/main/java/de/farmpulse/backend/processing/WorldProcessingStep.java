package de.farmpulse.backend.processing;

import de.farmpulse.backend.ingest.dto.WorldData;
import org.springframework.stereotype.Component;

/**
 * Erweiterungspunkt der Ingest-Pipeline fuer world.json, siehe
 * {@link TelemetryProcessingStep} fuer die Begruendung dieses Musters.
 */
public interface WorldProcessingStep {

    WorldData process(WorldData raw);
}

/** Standardimplementierung von {@link WorldProcessingStep}: Passthrough. */
@Component
class NoOpWorldProcessingStep implements WorldProcessingStep {

    @Override
    public WorldData process(WorldData raw) {
        return raw;
    }
}
