package de.farmpulse.backend.fields.dto;

import java.util.List;

/**
 * Antwort von {@code GET /api/fields}: alle der aktiven Farm gehoerenden
 * Felder samt Zusammenfassung, fuer die Felder-Seite im Frontend (Vorlage
 * MockDashboard/Fields.html).
 */
public record FieldsResponse(
        int count,
        double totalAreaHa,
        long totalValue,
        double totalEstimatedYieldLiters,
        List<FieldDetail> items) {
}
