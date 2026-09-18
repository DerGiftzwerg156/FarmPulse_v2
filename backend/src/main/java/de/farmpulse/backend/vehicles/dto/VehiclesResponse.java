package de.farmpulse.backend.vehicles.dto;

import java.util.List;

/**
 * Antwort von {@code GET /api/vehicles}: alle Fahrzeuge der aktiven Farm
 * samt Zusammenfassung, fuer die Flotten-Seite im Frontend.
 */
public record VehiclesResponse(
        int count,
        long totalSellValue,
        Double averageConditionPercent,
        List<VehicleDetail> items) {
}
