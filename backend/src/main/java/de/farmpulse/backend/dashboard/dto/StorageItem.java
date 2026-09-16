package de.farmpulse.backend.dashboard.dto;

/**
 * Ein Lager-/Silobestand, siehe {@code de.farmpulse.backend.domain.StorageSnapshot}.
 * Die Preisfelder sind nullable, siehe dort.
 */
public record StorageItem(
        String fillType,
        long amount,
        long capacity,
        double fillPercentage,
        Double currentPricePer1000L,
        Double bestPricePer1000L,
        Integer bestPricePeriod,
        String bestPricePeriodLabel) {
}
