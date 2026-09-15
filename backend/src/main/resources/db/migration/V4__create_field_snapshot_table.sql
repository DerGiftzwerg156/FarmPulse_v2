-- Felder/Farmlands je world_snapshot (siehe Bridge/README.md, Abschnitt
-- "Dateiformat: world.json", world.json/fields[]). Jeder Snapshot enthaelt
-- die volle Feldliste der Karte, kein Delta - owner_farm_id ist deshalb
-- bewusst kein Fremdschluessel auf farm (0 = unbesitzt, oder eine andere,
-- hier nicht separat verfolgte Farm).
CREATE TABLE field_snapshot (
    id                  BIGINT         NOT NULL AUTO_INCREMENT,
    world_snapshot_id   BIGINT         NOT NULL,
    list_index          INT            NOT NULL,
    field_id            INT            NOT NULL,
    owner_farm_id       INT            NOT NULL,
    -- DOUBLE statt DECIMAL, da FieldSnapshot.sizeHa ein Java "double" ist -
    -- Hibernates Schema-Validierung (ddl-auto: validate) erwartet dafuer
    -- genau diesen SQL-Typ.
    size_ha             DOUBLE NOT NULL,
    price               BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_field_snapshot_world FOREIGN KEY (world_snapshot_id) REFERENCES world_snapshot (id) ON DELETE CASCADE,
    INDEX idx_field_snapshot_world (world_snapshot_id)
) ENGINE = InnoDB;
