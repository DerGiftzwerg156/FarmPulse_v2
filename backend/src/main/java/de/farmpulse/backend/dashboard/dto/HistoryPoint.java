package de.farmpulse.backend.dashboard.dto;

import java.time.Instant;

/** Ein Punkt im Kontostand-Verlauf (fuer die Sparkline im Dashboard). */
public record HistoryPoint(Instant recordedAt, GameTime gameTime, long money) {
}
