package de.farmpulse.backend.mailbox;

import de.farmpulse.backend.mailbox.dto.MailboxMessageResponse;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * Minimale REST-Schnittstelle fuer das Postfach der aktiven Farm (siehe
 * {@link MailboxGenerationService}). Es existiert bewusst (noch) keine
 * eigene Frontend-Seite dafuer - dieser Endpoint dient aktuell dazu, die
 * generierten Nachrichten ueberhaupt einsehen zu koennen.
 */
@RestController
@RequestMapping("/api/mailbox")
public class MailboxController {

    private final MailboxService mailboxService;

    public MailboxController(MailboxService mailboxService) {
        this.mailboxService = mailboxService;
    }

    @GetMapping
    public List<MailboxMessageResponse> messages() {
        return mailboxService.getMessages();
    }

    @PostMapping("/{id}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markRead(@PathVariable long id) {
        mailboxService.markRead(id);
    }
}
