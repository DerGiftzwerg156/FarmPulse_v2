package de.farmpulse.backend.processing;

import de.farmpulse.backend.ingest.dto.FarmData;
import org.springframework.stereotype.Component;

/** Standardimplementierung von {@link FarmProcessingStep}: Passthrough. */
@Component
public class NoOpFarmProcessingStep implements FarmProcessingStep {

    @Override
    public FarmData process(FarmData raw) {
        return raw;
    }
}
