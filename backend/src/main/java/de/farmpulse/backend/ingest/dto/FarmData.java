package de.farmpulse.backend.ingest.dto;

/**
 * Rohabbild von farm.json, siehe Bridge/README.md, Abschnitt "Dateiformat:
 * farm.json".
 */
public record FarmData(
        String farmName,
        String playerName) {
}
