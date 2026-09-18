-- Fahrzeugkategorie und Eigentumsstatus je Fahrzeug, siehe Bridge/README.md,
-- Abschnitt "Dateiformat: world.json" (vehicles[]/category,
-- vehicles[]/ownershipStatus). Beide NOT NULL mit Fallback-Wert, da die
-- Bridge (VehicleCollector.lua) bei fehlendem/nicht auflösbarem Rohwert
-- bereits "Sonstiges" bzw. "UNKNOWN" liefert statt null - siehe
-- field_snapshot/fruit_type (Migration V9) fuer den Gegenbeispiel-Fall
-- echter Nullability.
ALTER TABLE vehicle_snapshot
    ADD COLUMN category         VARCHAR(64) NOT NULL DEFAULT 'Sonstiges',
    ADD COLUMN ownership_status VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN';

ALTER TABLE vehicle_snapshot
    ALTER COLUMN category DROP DEFAULT,
    ALTER COLUMN ownership_status DROP DEFAULT;
