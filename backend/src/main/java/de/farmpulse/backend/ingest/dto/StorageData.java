package de.farmpulse.backend.ingest.dto;

/**
 * Ein Eintrag aus world.json/storages, siehe Bridge/README.md, Abschnitt
 * "Dateiformat: world.json".
 */
public record StorageData(
        String fillType,
        long amount,
        long capacity,
        Double currentPricePer1000L,
        Double bestPricePer1000L,
        Integer bestPricePeriod,
        String bestPricePeriodLabel) {
}
