-- Fahrzeuge je world_snapshot (siehe Bridge/README.md, Abschnitt
-- "Dateiformat: world.json", world.json/vehicles[]).
-- horsepower_hp/operating_hours/condition_percent sind nullable: die Bridge
-- liest jedes Detail-Feld einzeln ab, ein einzelner fehlgeschlagener
-- Lesezugriff (z.B. PS bei einem Anhaenger ohne Motor) darf die uebrigen
-- Felder nicht verwerfen.
CREATE TABLE vehicle_snapshot (
    id                  BIGINT       NOT NULL AUTO_INCREMENT,
    world_snapshot_id   BIGINT       NOT NULL,
    -- DEFAULT 0 noetig: Hibernate befuellt diese von @OrderColumn verwaltete
    -- Spalte bei einer "mappedBy"-Collection erst per nachtraeglichem UPDATE
    -- nach dem initialen INSERT.
    list_index          INT          NOT NULL DEFAULT 0,
    name                VARCHAR(128) NOT NULL,
    horsepower_hp       DOUBLE       NULL,
    operating_hours     DOUBLE       NULL,
    condition_percent   DOUBLE       NULL,
    sell_price          BIGINT       NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_vehicle_snapshot_world FOREIGN KEY (world_snapshot_id) REFERENCES world_snapshot (id) ON DELETE CASCADE,
    INDEX idx_vehicle_snapshot_world (world_snapshot_id)
) ENGINE = InnoDB;
