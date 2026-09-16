package de.farmpulse.backend.dashboard.dto;

import java.util.List;

/** Aggregation der Felder, die aktuell der Farm gehoeren (ownerFarmId == Farm-ID). */
public record FieldsSummary(int count, double totalAreaHa, long totalValue, List<FieldItem> items) {
}
