package de.farmpulse.backend.mailbox;

import de.farmpulse.backend.domain.MailboxMessage;
import de.farmpulse.backend.mailbox.dto.MailboxMessageResponse;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.MailboxMessageRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

/**
 * Liest Postfach-Nachrichten der aktiven Farm (siehe
 * {@link MailboxGenerationService} fuer deren Erzeugung).
 */
@Service
public class MailboxService {

    private final MailboxMessageRepository mailboxMessageRepository;
    private final FarmRepository farmRepository;

    public MailboxService(MailboxMessageRepository mailboxMessageRepository, FarmRepository farmRepository) {
        this.mailboxMessageRepository = mailboxMessageRepository;
        this.farmRepository = farmRepository;
    }

    @Transactional(readOnly = true)
    public List<MailboxMessageResponse> getMessages() {
        return farmRepository.findTopByOrderByUpdatedAtDesc()
                .map(farm -> mailboxMessageRepository.findByFarmIdOrderByCreatedAtDesc(farm.getId()).stream()
                        .map(MailboxService::toResponse)
                        .toList())
                .orElseGet(List::of);
    }

    @Transactional
    public void markRead(long id) {
        MailboxMessage message = mailboxMessageRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Nachricht nicht gefunden."));
        message.markRead();
        mailboxMessageRepository.save(message);
    }

    private static MailboxMessageResponse toResponse(MailboxMessage message) {
        return new MailboxMessageResponse(message.getId(), message.getSender(), message.getSubject(),
                message.getBody(), message.getCategory(), message.getPriority(), message.getGameYear(),
                message.getGameMonth(), message.getGameDay(), message.getGameHour(), message.getGameMinute(),
                message.isRead(), message.getCreatedAt());
    }
}
