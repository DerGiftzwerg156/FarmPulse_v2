package de.farmpulse.backend.dashboard.dto;

/**
 * Ein aus den vorhandenen Snapshot-Daten abgeleiteter Hinweis (z.B. fast
 * volles Lager, negativer Kontostand) - im Gegensatz zum MockDashboard
 * NICHT KI-generiert, sondern einfache Schwellwert-Regeln auf echten Daten.
 */
public record Alert(Severity severity, String message) {

    public enum Severity {
        WARNING
    }
}
