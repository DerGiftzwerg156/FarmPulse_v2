package de.farmpulse.backend.ingest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.config.BridgeExchangeProperties;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.ingest.dto.TelemetryData;
import de.farmpulse.backend.processing.TelemetryProcessingStep;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import java.nio.file.Path;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;

class TelemetryIngestServiceTest {

    @TempDir
    Path exchangeDir;

    private ExchangeFileReader fileReader;
    private FarmRepository farmRepository;
    private TelemetrySnapshotRepository snapshotRepository;
    private TelemetryIngestService service;

    @BeforeEach
    void setUp() {
        fileReader = mock(ExchangeFileReader.class);
        farmRepository = mock(FarmRepository.class);
        snapshotRepository = mock(TelemetrySnapshotRepository.class);
        TelemetryProcessingStep passthrough = raw -> raw;
        BridgeExchangeProperties properties = new BridgeExchangeProperties(exchangeDir, 5000, 30000, 60000);

        service = new TelemetryIngestService(properties, fileReader, passthrough, farmRepository, snapshotRepository);

        when(snapshotRepository.save(any(TelemetrySnapshot.class)))
                .thenAnswer((InvocationOnMock invocation) -> invocation.getArgument(0));
    }

    @Test
    void liefertLeerOptionalWennKeineNeueDateiVorliegt() {
        when(fileReader.readIfNewer(any(), any(), eq(TelemetryData.class))).thenReturn(Optional.empty());

        Optional<TelemetrySnapshot> result = service.ingestIfChanged();

        assertThat(result).isEmpty();
        verify(farmRepository, never()).save(any());
        verify(snapshotRepository, never()).save(any());
    }

    @Test
    void legtNeueFarmAnUndSpeichertSnapshotWennFarmUnbekannt() {
        TelemetryData data = new TelemetryData(8, 30, 4, 6, 2, 3, 84250, 1L);
        Instant recordedAt = Instant.parse("2024-06-04T08:30:00Z");
        when(fileReader.readIfNewer(eq(exchangeDir.resolve("telemetry.json")), eq(null), eq(TelemetryData.class)))
                .thenReturn(Optional.of(new ExchangeFile<>(data, recordedAt)));
        when(farmRepository.findById(1L)).thenReturn(Optional.empty());
        when(farmRepository.save(any(Farm.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Optional<TelemetrySnapshot> result = service.ingestIfChanged();

        assertThat(result).isPresent();
        TelemetrySnapshot snapshot = result.get();
        assertThat(snapshot.getFarm().getId()).isEqualTo(1L);
        assertThat(snapshot.getMoney()).isEqualTo(84250);
        assertThat(snapshot.getGameYear()).isEqualTo(2);
        assertThat(snapshot.getGameMonth()).isEqualTo(6);
        assertThat(snapshot.getRecordedAt()).isEqualTo(recordedAt);
        verify(farmRepository).save(any(Farm.class));
    }

    @Test
    void verwendetVorhandeneFarmStattNeuerAnzulegen() {
        TelemetryData data = new TelemetryData(8, 30, 4, 6, 2, 3, 84250, 1L);
        Instant recordedAt = Instant.parse("2024-06-04T08:30:00Z");
        when(fileReader.readIfNewer(any(), any(), eq(TelemetryData.class)))
                .thenReturn(Optional.of(new ExchangeFile<>(data, recordedAt)));
        Farm existingFarm = new Farm(1L, Instant.parse("2024-01-01T00:00:00Z"));
        when(farmRepository.findById(1L)).thenReturn(Optional.of(existingFarm));

        service.ingestIfChanged();

        verify(farmRepository, never()).save(any());
    }

    @Test
    void verwendetRecordedAtDesGelesenenFilesAlsUntergrenzeFuerDenNaechstenPoll() {
        TelemetryData data = new TelemetryData(8, 30, 4, 6, 2, 3, 84250, 1L);
        Instant recordedAt = Instant.parse("2024-06-04T08:30:00Z");
        when(fileReader.readIfNewer(any(), any(), eq(TelemetryData.class)))
                .thenReturn(Optional.of(new ExchangeFile<>(data, recordedAt)))
                .thenReturn(Optional.empty());
        when(farmRepository.findById(1L)).thenReturn(Optional.of(new Farm(1L, recordedAt)));

        service.ingestIfChanged();
        service.ingestIfChanged();

        ArgumentCaptor<Instant> afterCaptor = ArgumentCaptor.forClass(Instant.class);
        verify(fileReader, org.mockito.Mockito.times(2))
                .readIfNewer(any(), afterCaptor.capture(), eq(TelemetryData.class));
        assertThat(afterCaptor.getAllValues().get(0)).isNull();
        assertThat(afterCaptor.getAllValues().get(1)).isEqualTo(recordedAt);
    }
}
