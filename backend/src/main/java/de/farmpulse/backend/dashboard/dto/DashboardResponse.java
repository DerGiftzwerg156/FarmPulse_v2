package de.farmpulse.backend.dashboard.dto;

import java.util.List;

/**
 * Antwort von {@code GET /api/dashboard}: aggregierter Zustand der aktiven
 * Farm aus den zuletzt gepollten Snapshots. Enthaelt bewusst nur Felder, fuer
 * die die Bridge tatsaechlich Daten liefert - siehe
 * backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md fuer Mock-Datenpunkte ohne
 * aktuelle Datenquelle.
 */
public record DashboardResponse(
        FarmInfo farm,
        GameTime gameTime,
        WeatherInfo weather,
        long money,
        long fleetValue,
        FieldsSummary fields,
        List<StorageItem> storages,
        List<Alert> alerts) {
}
