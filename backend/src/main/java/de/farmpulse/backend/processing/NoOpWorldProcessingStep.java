package de.farmpulse.backend.processing;

import de.farmpulse.backend.ingest.dto.WorldData;
import org.springframework.stereotype.Component;

/** Standardimplementierung von {@link WorldProcessingStep}: Passthrough. */
@Component
public class NoOpWorldProcessingStep implements WorldProcessingStep {

    @Override
    public WorldData process(WorldData raw) {
        return raw;
    }
}
