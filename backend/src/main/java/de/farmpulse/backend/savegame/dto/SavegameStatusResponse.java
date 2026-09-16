package de.farmpulse.backend.savegame.dto;

/**
 * Antwort von {@code GET /api/savegame}: der Fortschritt bis zum "Start"
 * des Savegames (siehe de.farmpulse.backend.savegame.SavegameService) -
 * {@code started} ist erst {@code true}, wenn alle vier Flags {@code true}
 * sind.
 */
public record SavegameStatusResponse(
        boolean started,
        boolean backstorySubmitted,
        boolean telemetryPolled,
        boolean worldPolled,
        boolean farmDataPolled) {
}
