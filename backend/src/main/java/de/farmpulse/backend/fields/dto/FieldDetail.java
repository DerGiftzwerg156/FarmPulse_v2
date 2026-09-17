package de.farmpulse.backend.fields.dto;

/**
 * Ein Feld der aktiven Farm samt optionalen Anbaudaten (siehe
 * {@code de.farmpulse.backend.domain.FieldSnapshot}). {@code fruitType}/
 * {@code growthState}/{@code estimatedYieldLiters} sind {@code null}, solange
 * die Bridge dazu keine Daten liefern konnte (siehe
 * backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md).
 */
public record FieldDetail(
        int fieldId,
        double sizeHa,
        long price,
        String fruitType,
        Double growthState,
        Double estimatedYieldLiters) {
}
