package de.farmpulse.backend.mailbox;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.MailboxMessage;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.MailboxMessageRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;

class MailboxGenerationServiceTest {

    private MailboxMessageRepository mailboxMessageRepository;
    private FarmRepository farmRepository;
    private TelemetrySnapshotRepository telemetrySnapshotRepository;
    private MailboxGenerationService service;

    @BeforeEach
    void setUp() {
        mailboxMessageRepository = mock(MailboxMessageRepository.class);
        farmRepository = mock(FarmRepository.class);
        telemetrySnapshotRepository = mock(TelemetrySnapshotRepository.class);
        // Echter ObjectMapper: laedt zugleich die tatsaechliche
        // mailbox-templates.json mit - validiert damit deren Syntax.
        service = new MailboxGenerationService(mailboxMessageRepository, farmRepository,
                telemetrySnapshotRepository, new ObjectMapper());
    }

    private Farm farmMitId(long id) {
        Farm farm = new Farm(id, Instant.now());
        farm.updateIdentity("Sonnenhof", "Keno", Instant.now());
        return farm;
    }

    @Test
    void generiertNichtsOhneFarm() {
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        Optional<MailboxMessage> result = service.generate();

        assertThat(result).isEmpty();
        verify(mailboxMessageRepository, never()).save(any());
    }

    @Test
    void generiertNichtsOhneTelemetrie() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.empty());

        Optional<MailboxMessage> result = service.generate();

        assertThat(result).isEmpty();
        verify(mailboxMessageRepository, never()).save(any());
    }

    @Test
    void generiertNachrichtAusVorlageMitAktuellerSpielzeit() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        TelemetrySnapshot telemetry = new TelemetrySnapshot(farm, 2025, 6, 12, 8, 30, 30, 50_000L, Instant.now(),
                Instant.now());
        when(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.of(telemetry));
        when(mailboxMessageRepository.save(any(MailboxMessage.class)))
                .thenAnswer((InvocationOnMock invocation) -> invocation.getArgument(0));

        Optional<MailboxMessage> result = service.generate();

        assertThat(result).isPresent();
        ArgumentCaptor<MailboxMessage> captor = ArgumentCaptor.forClass(MailboxMessage.class);
        verify(mailboxMessageRepository).save(captor.capture());
        MailboxMessage saved = captor.getValue();
        assertThat(saved.getFarm()).isSameAs(farm);
        assertThat(saved.getGameYear()).isEqualTo(2025);
        assertThat(saved.getGameDay()).isEqualTo(12);
        assertThat(saved.isRead()).isFalse();
        assertThat(saved.getSubject()).isNotBlank();
        assertThat(saved.getSender()).isNotBlank();
    }
}
