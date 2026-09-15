-- Historisierte Momentaufnahmen von world.json (siehe Bridge/README.md,
-- Abschnitt "Dateiformat: world.json"): Fuhrpark-Wert je Zeitpunkt. Felder
-- und Lagerbestaende haengen als eigene Tabellen daran (siehe V4/V5).
CREATE TABLE world_snapshot (
    id           BIGINT       NOT NULL AUTO_INCREMENT,
    farm_id      BIGINT       NOT NULL,
    fleet_value  BIGINT       NOT NULL,
    recorded_at  TIMESTAMP(6) NOT NULL,
    created_at   TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_world_snapshot_farm FOREIGN KEY (farm_id) REFERENCES farm (id),
    INDEX idx_world_snapshot_farm_recorded (farm_id, recorded_at)
) ENGINE = InnoDB;
