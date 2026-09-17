package de.farmpulse.backend.ingest.dto;

/**
 * Rohabbild von telemetry.json, siehe Bridge/README.md, Abschnitt
 * "Dateiformat: telemetry.json". Feldnamen entsprechen bewusst 1:1 dem
 * JSON-Format der Bridge.
 */
public record TelemetryData(
        int hour,
        int minute,
        int day,
        int month,
        int year,
        int daysPerMonth,
        long money,
        long farmId,
        String weatherType,
        double temperature) {
}
