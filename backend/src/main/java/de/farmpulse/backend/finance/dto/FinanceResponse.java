package de.farmpulse.backend.finance.dto;

import java.util.List;

/**
 * Antwort von {@code GET /api/finance} fuer die Finanzen-Seite im Frontend
 * (Vorlage MockDashboard/Finances.html). Einnahmen/Ausgaben und
 * balanceDelta beziehen sich auf den in {@code history} abgedeckten
 * Zeitraum (die zuletzt aufgezeichneten Telemetrie-Snapshots), nicht auf
 * einen festen Kalenderzeitraum.
 *
 * Transaktions-Logs aus der Vorlage fehlen bewusst - die Bridge liefert
 * dafuer keine Daten (siehe backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md).
 * Reputation, Mitarbeiterzufriedenheit und Saisonziel liefert stattdessen
 * das getrennte {@code GET /api/progression} (siehe
 * {@code de.farmpulse.backend.progression.ProgressionController}) - beide
 * Konzepte stammen ebenfalls nicht aus der Bridge, wurden aber bewusst als
 * eigenstaendiges Modul umgesetzt (siehe MOCK_DASHBOARD_DATENLUECKEN.md).
 */
public record FinanceResponse(
        long balance,
        long balanceDeltaInPeriod,
        long incomeInPeriod,
        long expenseInPeriod,
        List<FinanceHistoryPoint> history) {
}
