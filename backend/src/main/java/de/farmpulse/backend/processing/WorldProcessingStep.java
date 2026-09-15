package de.farmpulse.backend.processing;

import de.farmpulse.backend.ingest.dto.WorldData;

/**
 * Erweiterungspunkt der Ingest-Pipeline fuer world.json, siehe
 * {@link TelemetryProcessingStep} fuer die Begruendung dieses Musters.
 */
public interface WorldProcessingStep {

    WorldData process(WorldData raw);
}
