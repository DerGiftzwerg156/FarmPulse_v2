package de.farmpulse.backend.mailbox;

import de.farmpulse.backend.domain.MailboxPriority;

/**
 * Eine Mock-Nachrichtenvorlage aus {@code mailbox-templates.json} (siehe
 * {@link MailboxGenerationService}). Rein statischer Beispielinhalt - kein
 * generierter Text.
 */
public record MailboxTemplate(
        String sender,
        String category,
        MailboxPriority priority,
        String subject,
        String body) {
}
