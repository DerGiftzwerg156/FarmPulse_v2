package de.farmpulse.backend.mailbox;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.MailboxMessage;
import de.farmpulse.backend.domain.MailboxPriority;
import de.farmpulse.backend.mailbox.dto.MailboxMessageResponse;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.MailboxMessageRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

class MailboxServiceTest {

    private MailboxMessageRepository mailboxMessageRepository;
    private FarmRepository farmRepository;
    private MailboxService service;

    @BeforeEach
    void setUp() {
        mailboxMessageRepository = mock(MailboxMessageRepository.class);
        farmRepository = mock(FarmRepository.class);
        service = new MailboxService(mailboxMessageRepository, farmRepository);
    }

    private MailboxMessage nachrichtMitId(long id, Farm farm) {
        MailboxMessage message = new MailboxMessage(farm, "Wetterdienst", "Unwetterwarnung", "Text", "WEATHER",
                MailboxPriority.HIGH, 2025, 6, 12, 8, 30, Instant.now());
        ReflectionTestUtils.setField(message, "id", id);
        return message;
    }

    @Test
    void liefertLeereListeOhneFarm() {
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        assertThat(service.getMessages()).isEmpty();
    }

    @Test
    void liefertNachrichtenDerAktivenFarmNeuesteZuerst() {
        Farm farm = new Farm(1L, Instant.now());
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        MailboxMessage message = nachrichtMitId(5L, farm);
        when(mailboxMessageRepository.findByFarmIdOrderByCreatedAtDesc(1L)).thenReturn(List.of(message));

        List<MailboxMessageResponse> result = service.getMessages();

        assertThat(result).hasSize(1);
        assertThat(result.get(0).id()).isEqualTo(5L);
        assertThat(result.get(0).sender()).isEqualTo("Wetterdienst");
    }

    @Test
    void markReadMarkiertUndSpeichertDieNachricht() {
        Farm farm = new Farm(1L, Instant.now());
        MailboxMessage message = nachrichtMitId(5L, farm);
        when(mailboxMessageRepository.findById(5L)).thenReturn(Optional.of(message));

        service.markRead(5L);

        assertThat(message.isRead()).isTrue();
        verify(mailboxMessageRepository).save(message);
    }

    @Test
    void markReadWirftWennNachrichtFehlt() {
        when(mailboxMessageRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.markRead(99L)).isInstanceOf(ResponseStatusException.class);
    }
}
