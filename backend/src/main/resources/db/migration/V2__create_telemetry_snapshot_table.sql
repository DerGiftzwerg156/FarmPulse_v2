-- Historisierte Momentaufnahmen von telemetry.json (siehe
-- Bridge/README.md, Abschnitt "Dateiformat: telemetry.json").
CREATE TABLE telemetry_snapshot (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    farm_id         BIGINT       NOT NULL,
    game_year       INT          NOT NULL,
    game_month      INT          NOT NULL,
    game_day        INT          NOT NULL,
    game_hour       INT          NOT NULL,
    game_minute     INT          NOT NULL,
    days_per_month  INT          NOT NULL,
    money           BIGINT       NOT NULL,
    recorded_at     TIMESTAMP(6) NOT NULL,
    created_at      TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_telemetry_snapshot_farm FOREIGN KEY (farm_id) REFERENCES farm (id),
    INDEX idx_telemetry_snapshot_farm_recorded (farm_id, recorded_at)
) ENGINE = InnoDB;
