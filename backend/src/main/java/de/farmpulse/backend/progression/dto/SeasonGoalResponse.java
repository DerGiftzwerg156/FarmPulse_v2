package de.farmpulse.backend.progression.dto;

import de.farmpulse.backend.domain.SeasonGoalStatus;
import de.farmpulse.backend.domain.SeasonGoalType;

/**
 * Ein Saisonziel fuer die Finanzen-Seite im Frontend (Vorlage
 * MockDashboard/Finances.html, Panel "Saisonziel"). {@code currentValue}
 * ist aktuell immer 0 - die Berechnung aus dem tatsaechlichen Farm-Zustand
 * ist noch nicht implementiert (siehe
 * {@code de.farmpulse.backend.progression.ProgressionService}).
 */
public record SeasonGoalResponse(
        SeasonGoalType type,
        String title,
        String unit,
        double targetValue,
        double currentValue,
        String fillType,
        String deadlineLabel,
        SeasonGoalStatus status) {
}
