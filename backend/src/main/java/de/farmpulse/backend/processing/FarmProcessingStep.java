package de.farmpulse.backend.processing;

import de.farmpulse.backend.ingest.dto.FarmData;

/**
 * Erweiterungspunkt der Ingest-Pipeline fuer farm.json, siehe
 * {@link TelemetryProcessingStep} fuer die Begruendung dieses Musters.
 */
public interface FarmProcessingStep {

    FarmData process(FarmData raw);
}
