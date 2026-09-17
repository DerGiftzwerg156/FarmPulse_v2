package de.farmpulse.backend.dashboard.dto;

/**
 * Aktuelles Wetter, wie zuletzt aus telemetry.json gepollt (siehe
 * {@code de.farmpulse.backend.domain.TelemetrySnapshot}). {@code type} ist
 * einer von {@code SUN}/{@code PARTIALLY_CLOUDY}/{@code CLOUDY}/{@code RAIN}/
 * {@code SNOW}/{@code HAIL}/{@code THUNDER}/{@code TWISTER}/{@code UNKNOWN}.
 */
public record WeatherInfo(String type, double temperature) {
}
