-- Postfach-/Mailbox-Nachrichten einer Farm (siehe
-- de.farmpulse.backend.mailbox.MailboxGenerationService). Inhalte stammen
-- aktuell aus einer mitgelieferten Mock-Vorlagendatei
-- (mailbox-templates.json), nicht aus der Bridge - siehe
-- MailboxGenerationService fuer die als TODO markierte spaetere
-- KI-Anbindung.
CREATE TABLE mailbox_message (
    id          BIGINT       NOT NULL AUTO_INCREMENT,
    farm_id     BIGINT       NOT NULL,
    sender      VARCHAR(255) NOT NULL,
    subject     VARCHAR(255) NOT NULL,
    body        TEXT         NOT NULL,
    category    VARCHAR(64)  NOT NULL,
    priority    VARCHAR(16)  NOT NULL,
    game_year   INT          NOT NULL,
    game_month  INT          NOT NULL,
    game_day    INT          NOT NULL,
    game_hour   INT          NOT NULL,
    game_minute INT          NOT NULL,
    is_read     BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP(6) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_mailbox_message_farm FOREIGN KEY (farm_id) REFERENCES farm (id),
    INDEX idx_mailbox_message_farm_created (farm_id, created_at)
) ENGINE = InnoDB;
