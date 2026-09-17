package de.farmpulse.backend.domain;

/**
 * Kategorisiert ein {@link SeasonGoal}, damit eine spaetere
 * Fortschrittsberechnung (siehe {@code de.farmpulse.backend.progression})
 * weiss, welche Farm-Kennzahl sie mit dem Ziel abgleichen muss. Aktuell
 * dient das Feld nur der Einordnung - die eigentliche Berechnung von
 * {@link SeasonGoal#getCurrentValue()} ist noch nicht implementiert.
 */
public enum SeasonGoalType {
    /** Ziel bezieht sich auf den Kontostand (siehe TelemetrySnapshot.money). */
    MONEY_BALANCE,
    /** Ziel bezieht sich auf eine geerntete Menge eines Fill-Typs (siehe SeasonGoal.fillType). */
    HARVEST_AMOUNT,
    /** Ziel bezieht sich auf die Mitarbeiteranzahl (in der Bridge noch nicht exportiert). */
    EMPLOYEE_COUNT,
    /** Freies Ziel ohne strukturierte Berechnungsgrundlage. */
    CUSTOM,
}
