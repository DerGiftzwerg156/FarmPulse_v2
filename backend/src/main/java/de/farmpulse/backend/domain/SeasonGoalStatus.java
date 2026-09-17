package de.farmpulse.backend.domain;

/** Lebenszyklus-Status eines {@link SeasonGoal}. */
public enum SeasonGoalStatus {
    /** Aktuell verfolgtes Ziel der Farm - genau eines pro Farm gleichzeitig. */
    ACTIVE,
    /** Ziel wurde erreicht. */
    COMPLETED,
    /** Ziel wurde nicht erreicht (z.B. Frist verstrichen). */
    FAILED,
}
