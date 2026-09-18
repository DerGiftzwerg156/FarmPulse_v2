package de.farmpulse.backend.vehicles.dto;

/**
 * Ein Fahrzeug der aktiven Farm (siehe
 * {@code de.farmpulse.backend.domain.VehicleSnapshot}). {@code horsepowerHp}/
 * {@code operatingHours}/{@code conditionPercent} sind {@code null}, solange
 * die Bridge das jeweilige Detail-Feld nicht liefern konnte (siehe
 * backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md).
 */
public record VehicleDetail(
        String name,
        String category,
        Double horsepowerHp,
        Double operatingHours,
        Double conditionPercent,
        String ownershipStatus,
        long sellPrice) {
}
