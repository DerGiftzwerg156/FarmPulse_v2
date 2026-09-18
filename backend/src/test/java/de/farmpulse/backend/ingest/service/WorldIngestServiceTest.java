package de.farmpulse.backend.ingest.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.config.BridgeExchangeProperties;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.ingest.dto.FieldData;
import de.farmpulse.backend.ingest.dto.StorageData;
import de.farmpulse.backend.ingest.dto.VehicleData;
import de.farmpulse.backend.ingest.dto.WorldData;
import de.farmpulse.backend.processing.WorldProcessingStep;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.invocation.InvocationOnMock;

class WorldIngestServiceTest {

    @TempDir
    Path exchangeDir;

    private ExchangeFileReader fileReader;
    private FarmRepository farmRepository;
    private WorldSnapshotRepository snapshotRepository;
    private WorldIngestService service;

    @BeforeEach
    void setUp() {
        fileReader = mock(ExchangeFileReader.class);
        farmRepository = mock(FarmRepository.class);
        snapshotRepository = mock(WorldSnapshotRepository.class);
        WorldProcessingStep passthrough = raw -> raw;
        BridgeExchangeProperties properties = new BridgeExchangeProperties(exchangeDir.toString(), 5000, 30000, 60000);

        service = new WorldIngestService(properties, fileReader, passthrough, farmRepository, snapshotRepository);

        when(snapshotRepository.save(any(WorldSnapshot.class)))
                .thenAnswer((InvocationOnMock invocation) -> invocation.getArgument(0));
    }

    @Test
    void ueberspringtPollWennNochKeineFarmBekannt() {
        WorldData data = new WorldData(125000, List.of(), List.of(), List.of());
        when(fileReader.readIfNewer(any(), any(), eq(WorldData.class)))
                .thenReturn(Optional.of(new ExchangeFile<>(data, Instant.now())));
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        Optional<WorldSnapshot> result = service.ingestIfChanged();

        assertThat(result).isEmpty();
    }

    @Test
    void bildetFelderUndLagerbestaendeAufDenSnapshotAb() {
        WorldData data = new WorldData(
                125000,
                List.of(new VehicleData("John Deere 8R 410", 410.0, 128.5, 92.0, 245000),
                        new VehicleData("Anhaenger", null, null, null, 0)),
                List.of(new FieldData(1, 1, 4.53, 32000, "WHEAT", 0.5, 15862.5),
                        new FieldData(2, 0, 6.10, 45000, null, null, null)),
                List.of(new StorageData("BARLEY", 1200, 20000, 175.2, 198.5, 7, "Juli"),
                        new StorageData("WHEAT", 5000, 20000, 218.4, 254.1, 3, "März")));
        Instant recordedAt = Instant.parse("2024-06-04T08:30:00Z");
        when(fileReader.readIfNewer(any(), any(), eq(WorldData.class)))
                .thenReturn(Optional.of(new ExchangeFile<>(data, recordedAt)));
        Farm farm = new Farm(1L, recordedAt);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));

        Optional<WorldSnapshot> result = service.ingestIfChanged();

        assertThat(result).isPresent();
        WorldSnapshot snapshot = result.get();
        assertThat(snapshot.getFleetValue()).isEqualTo(125000);
        assertThat(snapshot.getFarm()).isSameAs(farm);
        assertThat(snapshot.getFields()).hasSize(2);
        assertThat(snapshot.getFields().get(0).getFieldId()).isEqualTo(1);
        assertThat(snapshot.getFields().get(0).getWorldSnapshot()).isSameAs(snapshot);
        assertThat(snapshot.getFields().get(0).getFruitType()).isEqualTo("WHEAT");
        assertThat(snapshot.getFields().get(0).getGrowthState()).isEqualTo(0.5);
        assertThat(snapshot.getFields().get(1).getFruitType()).isNull();
        assertThat(snapshot.getVehicles()).hasSize(2);
        assertThat(snapshot.getVehicles().get(0).getName()).isEqualTo("John Deere 8R 410");
        assertThat(snapshot.getVehicles().get(0).getWorldSnapshot()).isSameAs(snapshot);
        assertThat(snapshot.getVehicles().get(0).getHorsepowerHp()).isEqualTo(410.0);
        assertThat(snapshot.getVehicles().get(0).getOperatingHours()).isEqualTo(128.5);
        assertThat(snapshot.getVehicles().get(0).getConditionPercent()).isEqualTo(92.0);
        assertThat(snapshot.getVehicles().get(0).getSellPrice()).isEqualTo(245000);
        assertThat(snapshot.getVehicles().get(1).getHorsepowerHp()).isNull();
        assertThat(snapshot.getVehicles().get(1).getSellPrice()).isEqualTo(0);
        assertThat(snapshot.getStorages()).hasSize(2);
        assertThat(snapshot.getStorages().get(1).getFillType()).isEqualTo("WHEAT");
        assertThat(snapshot.getStorages().get(1).getWorldSnapshot()).isSameAs(snapshot);
        assertThat(snapshot.getStorages().get(1).getCurrentPricePer1000L()).isEqualTo(218.4);
        assertThat(snapshot.getStorages().get(1).getBestPricePer1000L()).isEqualTo(254.1);
        assertThat(snapshot.getStorages().get(1).getBestPricePeriod()).isEqualTo(3);
        assertThat(snapshot.getStorages().get(1).getBestPricePeriodLabel()).isEqualTo("März");
    }
}
