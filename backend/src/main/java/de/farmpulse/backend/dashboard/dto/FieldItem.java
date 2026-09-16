package de.farmpulse.backend.dashboard.dto;

/** Ein von der Farm bewirtschaftetes Feld, siehe {@code de.farmpulse.backend.domain.FieldSnapshot}. */
public record FieldItem(int fieldId, double sizeHa, long price) {
}
