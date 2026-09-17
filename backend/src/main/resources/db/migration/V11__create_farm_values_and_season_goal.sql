-- Weiche Farm-Kennzahlen (Reputation, Mitarbeiterzufriedenheit) sowie
-- Saisonziele (siehe MockDashboard/Finances.html, Panels "Werte" und
-- "Saisonziel"). Beide Konzepte stammen NICHT aus der Bridge - FS25 kennt
-- weder Reputation/Mitarbeiterzufriedenheit noch Saisonziele. Siehe
-- de.farmpulse.backend.progression.ProgressionService fuer die aktuell nur
-- platzhalterhafte Befuellung (Berechnungslogik folgt spaeter).
CREATE TABLE farm_values (
    farm_id                        BIGINT       NOT NULL,
    reputation_percent             INT          NOT NULL,
    employee_satisfaction_percent  INT          NOT NULL,
    updated_at                     TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (farm_id),
    CONSTRAINT fk_farm_values_farm FOREIGN KEY (farm_id) REFERENCES farm (id)
) ENGINE = InnoDB;

CREATE TABLE season_goal (
    id              BIGINT       NOT NULL AUTO_INCREMENT,
    farm_id         BIGINT       NOT NULL,
    type            VARCHAR(32)  NOT NULL,
    title           VARCHAR(255) NOT NULL,
    unit            VARCHAR(32)  NOT NULL,
    target_value    DOUBLE       NOT NULL,
    current_value   DOUBLE       NOT NULL,
    fill_type       VARCHAR(64)  NULL,
    deadline_label  VARCHAR(128) NULL,
    status          VARCHAR(16)  NOT NULL,
    created_at      TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_season_goal_farm FOREIGN KEY (farm_id) REFERENCES farm (id),
    INDEX idx_season_goal_farm_status (farm_id, status, created_at)
) ENGINE = InnoDB;
