package de.farmpulse.backend.ingest.dto;

/**
 * Ein Eintrag aus world.json/fields, siehe Bridge/README.md, Abschnitt
 * "Dateiformat: world.json".
 */
public record FieldData(
        int fieldId,
        int ownerFarmId,
        double sizeHa,
        long price,
        String fruitType,
        Double growthState,
        Double estimatedYieldLiters) {
}
