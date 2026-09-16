package de.farmpulse.backend.savegame;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.SavegameBackstory;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.ingest.event.FarmCreatedEvent;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.SavegameBackstoryRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import de.farmpulse.backend.savegame.dto.SavegameStatusResponse;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;

class SavegameServiceTest {

    private SavegameBackstoryRepository backstoryRepository;
    private FarmRepository farmRepository;
    private TelemetrySnapshotRepository telemetrySnapshotRepository;
    private WorldSnapshotRepository worldSnapshotRepository;
    private SavegameService service;

    @BeforeEach
    void setUp() {
        backstoryRepository = mock(SavegameBackstoryRepository.class);
        farmRepository = mock(FarmRepository.class);
        telemetrySnapshotRepository = mock(TelemetrySnapshotRepository.class);
        worldSnapshotRepository = mock(WorldSnapshotRepository.class);
        service = new SavegameService(backstoryRepository, farmRepository, telemetrySnapshotRepository,
                worldSnapshotRepository);
    }

    @Test
    void nichtGestartetWennNochNichtsVorliegt() {
        when(backstoryRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.empty());
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        SavegameStatusResponse status = service.getStatus();

        assertThat(status.started()).isFalse();
        assertThat(status.backstorySubmitted()).isFalse();
        assertThat(status.telemetryPolled()).isFalse();
        assertThat(status.worldPolled()).isFalse();
        assertThat(status.farmDataPolled()).isFalse();
    }

    @Test
    void gestartetErstWennVorgeschichteUndAlleDreiDatenVorliegen() {
        when(backstoryRepository.findFirstByOrderByIdAsc())
                .thenReturn(Optional.of(new SavegameBackstory("Es war einmal...", Instant.now())));
        Farm farm = new Farm(1L, Instant.now());
        farm.updateIdentity("Sonnenhof", "Keno", Instant.now());
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L))
                .thenReturn(Optional.of(mock(TelemetrySnapshot.class)));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L))
                .thenReturn(Optional.of(mock(WorldSnapshot.class)));

        SavegameStatusResponse status = service.getStatus();

        assertThat(status.started()).isTrue();
        assertThat(status.backstorySubmitted()).isTrue();
        assertThat(status.telemetryPolled()).isTrue();
        assertThat(status.worldPolled()).isTrue();
        assertThat(status.farmDataPolled()).isTrue();
    }

    @Test
    void nichtGestartetWennFarmJsonNochNichtGepolltWurde() {
        when(backstoryRepository.findFirstByOrderByIdAsc())
                .thenReturn(Optional.of(new SavegameBackstory("Es war einmal...", Instant.now())));
        Farm farm = new Farm(1L, Instant.now());
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L))
                .thenReturn(Optional.of(mock(TelemetrySnapshot.class)));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L))
                .thenReturn(Optional.of(mock(WorldSnapshot.class)));

        SavegameStatusResponse status = service.getStatus();

        assertThat(status.started()).isFalse();
        assertThat(status.farmDataPolled()).isFalse();
    }

    @Test
    void speichertVorgeschichteUndVerknuepftSieMitBekannterFarm() {
        when(backstoryRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.empty());
        Farm farm = new Farm(1L, Instant.now());
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(backstoryRepository.save(any(SavegameBackstory.class)))
                .thenAnswer((InvocationOnMock invocation) -> invocation.getArgument(0));

        service.submitBackstory("  Es war einmal ein Hof.  ");

        ArgumentCaptor<SavegameBackstory> captor = ArgumentCaptor.forClass(SavegameBackstory.class);
        verify(backstoryRepository).save(captor.capture());
        assertThat(captor.getValue().getText()).isEqualTo("Es war einmal ein Hof.");
        assertThat(captor.getValue().getFarm()).isSameAs(farm);
    }

    @Test
    void speichertVorgeschichteAuchOhneBekannteFarm() {
        when(backstoryRepository.findFirstByOrderByIdAsc()).thenReturn(Optional.empty());
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());
        when(backstoryRepository.save(any(SavegameBackstory.class)))
                .thenAnswer((InvocationOnMock invocation) -> invocation.getArgument(0));

        service.submitBackstory("Es war einmal ein Hof.");

        ArgumentCaptor<SavegameBackstory> captor = ArgumentCaptor.forClass(SavegameBackstory.class);
        verify(backstoryRepository).save(captor.capture());
        assertThat(captor.getValue().getFarm()).isNull();
    }

    @Test
    void lehntLeereVorgeschichteAb() {
        assertThatThrownBy(() -> service.submitBackstory("   "))
                .isInstanceOf(InvalidBackstoryException.class);
        verify(backstoryRepository, never()).save(any());
    }

    @Test
    void lehntZweiteVorgeschichteAb() {
        when(backstoryRepository.findFirstByOrderByIdAsc())
                .thenReturn(Optional.of(new SavegameBackstory("Alte Vorgeschichte", Instant.now())));

        assertThatThrownBy(() -> service.submitBackstory("Neue Vorgeschichte"))
                .isInstanceOf(BackstoryAlreadySubmittedException.class);
        verify(backstoryRepository, never()).save(any());
    }

    @Test
    void verknuepftPendenteVorgeschichteBeiFarmCreatedEvent() {
        SavegameBackstory pending = new SavegameBackstory("Es war einmal...", Instant.now());
        when(backstoryRepository.findFirstByFarmIsNullOrderByIdAsc()).thenReturn(Optional.of(pending));
        Farm farm = new Farm(1L, Instant.now());

        service.onFarmCreated(new FarmCreatedEvent(farm));

        assertThat(pending.getFarm()).isSameAs(farm);
    }
}
