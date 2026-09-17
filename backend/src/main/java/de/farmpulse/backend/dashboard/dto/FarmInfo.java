package de.farmpulse.backend.dashboard.dto;

/** Stammdaten der aktuell aktiven Farm. */
public record FarmInfo(long id, String name, String playerName) {
}
