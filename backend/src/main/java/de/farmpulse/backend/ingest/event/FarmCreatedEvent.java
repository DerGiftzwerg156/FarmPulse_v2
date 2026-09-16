package de.farmpulse.backend.ingest.event;

import de.farmpulse.backend.domain.Farm;

/**
 * Wird von {@link de.farmpulse.backend.ingest.service.TelemetryIngestService}
 * veroeffentlicht, sobald telemetry.json zum ersten Mal eine bislang
 * unbekannte Farm liefert (siehe dort, {@code farmNeuAngelegt}). Entkoppelt
 * die Ingest-Pipeline von Modulen wie
 * {@link de.farmpulse.backend.savegame.SavegameService}, die auf das
 * erstmalige Bekanntwerden einer Farm reagieren muessen.
 */
public record FarmCreatedEvent(Farm farm) {
}
