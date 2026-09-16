package de.farmpulse.backend.ingest.dto;

import java.util.List;

/**
 * Rohabbild von world.json, siehe Bridge/README.md, Abschnitt "Dateiformat:
 * world.json".
 */
public record WorldData(
        long fleetValue,
        List<FieldData> fields,
        List<StorageData> storages) {
}
