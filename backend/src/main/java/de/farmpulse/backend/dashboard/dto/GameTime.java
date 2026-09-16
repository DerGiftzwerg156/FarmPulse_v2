package de.farmpulse.backend.dashboard.dto;

/** Aktueller Spielzeitpunkt, wie zuletzt aus telemetry.json gepollt. */
public record GameTime(int year, int month, int day, int hour, int minute, int daysPerMonth) {
}
