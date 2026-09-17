package de.farmpulse.backend.progression;

import de.farmpulse.backend.domain.SeasonGoalType;

/**
 * Eine Mock-Vorlage fuer ein Saisonziel aus {@code season-goal-templates.json}
 * (siehe {@link ProgressionService}). Rein statischer Beispielinhalt - kein
 * generiertes Ziel und keine Berechnungslogik.
 *
 * @param fillType nur bei {@link SeasonGoalType#HARVEST_AMOUNT} gesetzt (sonst null)
 * @param deadlineLabel optionale Freitext-Frist, z.B. "Bis Jahresende" (sonst null)
 */
public record SeasonGoalTemplate(
        SeasonGoalType type,
        String title,
        String unit,
        double targetValue,
        String fillType,
        String deadlineLabel) {
}
