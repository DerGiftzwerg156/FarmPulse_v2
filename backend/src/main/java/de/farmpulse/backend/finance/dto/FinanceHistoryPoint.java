package de.farmpulse.backend.finance.dto;

import java.time.Instant;

/**
 * Ein Kontostand-Messpunkt fuer den Verlaufs-Chart der Finanzen-Seite
 * (Vorlage MockDashboard/Finances.html).
 */
public record FinanceHistoryPoint(Instant recordedAt, int gameDay, long money) {
}
