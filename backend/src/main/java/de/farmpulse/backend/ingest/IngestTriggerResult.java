package de.farmpulse.backend.ingest;

/** Ergebnis eines manuell ausgeloesten Ingest-Durchlaufs, siehe {@link IngestController}. */
public record IngestTriggerResult(boolean telemetryIngested, boolean worldIngested, boolean farmIngested) {
}
