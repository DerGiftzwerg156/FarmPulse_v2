-- Wetter (Typ + Temperatur) je Telemetrie-Snapshot, siehe Bridge/README.md,
-- Abschnitt "Dateiformat: telemetry.json" (weatherType/temperature).
-- DEFAULT noetig, damit das ALTER TABLE auch gegen eine bereits befuellte
-- Tabelle (bestehende Installationen) funktioniert - bestehende Zeilen
-- stammen von vor dieser Migration und hatten schlicht kein Wetter.
ALTER TABLE telemetry_snapshot
    ADD COLUMN weather_type VARCHAR(32) NOT NULL DEFAULT 'UNKNOWN',
    ADD COLUMN temperature  DOUBLE       NOT NULL DEFAULT 0;
