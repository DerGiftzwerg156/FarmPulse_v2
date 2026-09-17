package de.farmpulse.backend.progression.dto;

/**
 * Antwort von {@code GET /api/progression} fuer die Finanzen-Seite im
 * Frontend (Vorlage MockDashboard/Finances.html, Panels "Werte" und
 * "Saisonziel"). {@code seasonGoal} ist null, falls keine Vorlagen geladen
 * werden konnten (siehe {@code de.farmpulse.backend.progression.ProgressionService}).
 */
public record ProgressionResponse(
        int reputationPercent,
        int employeeSatisfactionPercent,
        SeasonGoalResponse seasonGoal) {
}
