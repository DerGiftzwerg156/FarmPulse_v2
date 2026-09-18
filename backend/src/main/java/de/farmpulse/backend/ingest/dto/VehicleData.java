package de.farmpulse.backend.ingest.dto;

/**
 * Ein Eintrag aus world.json/vehicles, siehe Bridge/README.md, Abschnitt
 * "Dateiformat: world.json".
 */
public record VehicleData(
        String name,
        Double horsepowerHp,
        Double operatingHours,
        Double conditionPercent,
        long sellPrice) {
}
