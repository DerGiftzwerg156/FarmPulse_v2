-- Die einmalig eingegebene "Vorgeschichte" eines neuen Spielstands (siehe
-- de.farmpulse.backend.savegame.SavegameService). Kann bereits vor der
-- ersten Farm eingegeben werden (bevor telemetry.json ueberhaupt zum ersten
-- Mal gepollt wurde) - farm_id ist deshalb bewusst nullable und wird
-- nachtraeglich verknuepft, sobald die Farm bekannt ist (siehe
-- de.farmpulse.backend.ingest.event.FarmCreatedEvent).
CREATE TABLE savegame_backstory (
    id         BIGINT       NOT NULL AUTO_INCREMENT,
    text       TEXT         NOT NULL,
    created_at TIMESTAMP(6) NOT NULL,
    farm_id    BIGINT       NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_savegame_backstory_farm FOREIGN KEY (farm_id) REFERENCES farm (id)
) ENGINE = InnoDB;
