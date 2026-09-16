package de.farmpulse.backend.dashboard.dto;

/** Ein Lager-/Silobestand, siehe {@code de.farmpulse.backend.domain.StorageSnapshot}. */
public record StorageItem(String fillType, long amount, long capacity, double fillPercentage) {
}
