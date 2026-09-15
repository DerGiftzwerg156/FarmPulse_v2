-- Betriebe, wie sie von der Bridge exportiert werden. Die ID entspricht der
-- FarmID aus telemetry.json (natuerlicher Schluessel, siehe Farm.java).
CREATE TABLE farm (
    id             BIGINT       NOT NULL,
    name           VARCHAR(255) NULL,
    player_name    VARCHAR(255) NULL,
    first_seen_at  TIMESTAMP(6) NOT NULL,
    updated_at     TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id)
) ENGINE = InnoDB;
