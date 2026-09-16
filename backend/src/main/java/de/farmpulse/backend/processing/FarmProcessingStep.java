package de.farmpulse.backend.processing;

import de.farmpulse.backend.ingest.dto.FarmData;
import org.springframework.stereotype.Component;

/**
 * Erweiterungspunkt der Ingest-Pipeline fuer farm.json, siehe
 * {@link TelemetryProcessingStep} fuer die Begruendung dieses Musters.
 */
public interface FarmProcessingStep {

    FarmData process(FarmData raw);
}

/** Standardimplementierung von {@link FarmProcessingStep}: Passthrough. */
@Component
class NoOpFarmProcessingStep implements FarmProcessingStep {

    @Override
    public FarmData process(FarmData raw) {
        return raw;
    }
}
