package de.farmpulse.backend.ingest.service;

import java.time.Instant;

/**
 * Ergebnis eines gelesenen Austauschfiles: die geparsten Nutzdaten plus der
 * reale Zeitpunkt des Exports (Datei-mtime, siehe {@link ExchangeFileReader}).
 */
public record ExchangeFile<T>(T data, Instant recordedAt) {
}
