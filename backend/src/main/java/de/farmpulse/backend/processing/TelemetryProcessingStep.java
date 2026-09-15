package de.farmpulse.backend.processing;

import de.farmpulse.backend.ingest.dto.TelemetryData;

/**
 * Erweiterungspunkt der Ingest-Pipeline fuer telemetry.json, zwischen dem
 * reinen JSON-Parsing und der Abbildung auf {@link
 * de.farmpulse.backend.domain.TelemetrySnapshot}. Aktuell gibt es keine
 * fachliche Verarbeitung - die Standardimplementierung
 * {@link NoOpTelemetryProcessingStep} reicht die Rohdaten unveraendert
 * durch. Kuenftige fachliche Schritte (z.B. Plausibilisierung, Ableitung
 * weiterer Kennzahlen) implementieren dieses Interface, ohne die
 * umgebende Pipeline (Lesen -> Verarbeiten -> Persistieren) aendern zu
 * muessen.
 */
public interface TelemetryProcessingStep {

    TelemetryData process(TelemetryData raw);
}
