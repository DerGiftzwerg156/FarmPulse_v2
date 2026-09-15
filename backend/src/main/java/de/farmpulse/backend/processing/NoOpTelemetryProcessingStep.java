package de.farmpulse.backend.processing;

import de.farmpulse.backend.ingest.dto.TelemetryData;
import org.springframework.stereotype.Component;

/** Standardimplementierung von {@link TelemetryProcessingStep}: Passthrough. */
@Component
public class NoOpTelemetryProcessingStep implements TelemetryProcessingStep {

    @Override
    public TelemetryData process(TelemetryData raw) {
        return raw;
    }
}
