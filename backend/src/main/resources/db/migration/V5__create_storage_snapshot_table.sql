-- Lager-/Silobestaende je world_snapshot (siehe Bridge/README.md, Abschnitt
-- "Dateiformat: world.json", world.json/storages[]).
CREATE TABLE storage_snapshot (
    id                  BIGINT       NOT NULL AUTO_INCREMENT,
    world_snapshot_id   BIGINT       NOT NULL,
    list_index          INT          NOT NULL,
    fill_type           VARCHAR(64)  NOT NULL,
    amount              BIGINT       NOT NULL,
    capacity            BIGINT       NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_storage_snapshot_world FOREIGN KEY (world_snapshot_id) REFERENCES world_snapshot (id) ON DELETE CASCADE,
    INDEX idx_storage_snapshot_world (world_snapshot_id)
) ENGINE = InnoDB;
