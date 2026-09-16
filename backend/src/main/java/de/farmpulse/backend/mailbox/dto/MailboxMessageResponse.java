package de.farmpulse.backend.mailbox.dto;

import de.farmpulse.backend.domain.MailboxPriority;
import java.time.Instant;

public record MailboxMessageResponse(
        long id,
        String sender,
        String subject,
        String body,
        String category,
        MailboxPriority priority,
        int gameYear,
        int gameMonth,
        int gameDay,
        int gameHour,
        int gameMinute,
        boolean read,
        Instant createdAt) {
}
