package de.farmpulse.backend.savegame.dto;

/** Request-Body von {@code POST /api/savegame/backstory}. */
public record BackstoryRequest(String backstory) {
}
