package de.farmpulse.backend.dashboard;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.dashboard.dto.DashboardResponse;
import de.farmpulse.backend.dashboard.dto.HistoryPoint;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.FieldSnapshot;
import de.farmpulse.backend.domain.StorageSnapshot;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Pageable;

class DashboardServiceTest {

    private FarmRepository farmRepository;
    private TelemetrySnapshotRepository telemetrySnapshotRepository;
    private WorldSnapshotRepository worldSnapshotRepository;
    private DashboardService service;

    @BeforeEach
    void setUp() {
        farmRepository = mock(FarmRepository.class);
        telemetrySnapshotRepository = mock(TelemetrySnapshotRepository.class);
        worldSnapshotRepository = mock(WorldSnapshotRepository.class);
        service = new DashboardService(farmRepository, telemetrySnapshotRepository, worldSnapshotRepository);
    }

    private Farm farmMitId(long id) {
        Farm farm = new Farm(id, Instant.now());
        farm.updateIdentity("Sonnenhof", "Keno", Instant.now());
        return farm;
    }

    @Test
    void wirftWennNochKeineFarmVorliegt() {
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getDashboard()).isInstanceOf(NoActiveFarmException.class);
    }

    @Test
    void wirftWennNochKeineTelemetrieVorliegt() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getDashboard()).isInstanceOf(NoActiveFarmException.class);
    }

    @Test
    void liefertAggregiertenZustandOhneWorldSnapshot() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        TelemetrySnapshot telemetry = new TelemetrySnapshot(farm, 2025, 6, 12, 8, 30, 30, 50_000L, "SUN", 11.4,
                Instant.now(), Instant.now());
        when(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.of(telemetry));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.empty());

        DashboardResponse response = service.getDashboard();

        assertThat(response.farm().id()).isEqualTo(1L);
        assertThat(response.farm().name()).isEqualTo("Sonnenhof");
        assertThat(response.money()).isEqualTo(50_000L);
        assertThat(response.fleetValue()).isZero();
        assertThat(response.fields().count()).isZero();
        assertThat(response.storages()).isEmpty();
        assertThat(response.gameTime().year()).isEqualTo(2025);
        assertThat(response.gameTime().hour()).isEqualTo(8);
        assertThat(response.weather().type()).isEqualTo("SUN");
        assertThat(response.weather().temperature()).isEqualTo(11.4);
    }

    @Test
    void aggregiertFelderNurDerEigenenFarmUndLagerbestaende() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        TelemetrySnapshot telemetry = new TelemetrySnapshot(farm, 2025, 6, 12, 8, 30, 30, 100_000L, "SUN", 11.4,
                Instant.now(), Instant.now());
        when(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.of(telemetry));

        WorldSnapshot world = new WorldSnapshot(farm, 250_000L, Instant.now(), Instant.now());
        world.addField(new FieldSnapshot(1, 1, 5.0, 20_000L, "WHEAT", 0.5, 12500.0));
        world.addField(new FieldSnapshot(2, 0, 3.0, 15_000L, null, null, null));
        world.addField(new FieldSnapshot(3, 2, 4.0, 18_000L, null, null, null));
        world.addStorage(new StorageSnapshot("WHEAT", 9_500L, 10_000L));
        world.addStorage(new StorageSnapshot("CANOLA", 100L, 5_000L));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.of(world));

        DashboardResponse response = service.getDashboard();

        assertThat(response.fleetValue()).isEqualTo(250_000L);
        assertThat(response.fields().count()).isEqualTo(1);
        assertThat(response.fields().totalAreaHa()).isEqualTo(5.0);
        assertThat(response.fields().totalValue()).isEqualTo(20_000L);
        assertThat(response.storages()).hasSize(2);
        assertThat(response.storages().get(0).fillPercentage()).isEqualTo(95.0);
        assertThat(response.alerts()).anyMatch(alert -> alert.message().contains("WHEAT"));
    }

    @Test
    void meldetNegativenKontostandAlsAlert() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        TelemetrySnapshot telemetry = new TelemetrySnapshot(farm, 2025, 6, 12, 8, 30, 30, -500L, "SUN", 11.4,
                Instant.now(), Instant.now());
        when(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.of(telemetry));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.empty());

        DashboardResponse response = service.getDashboard();

        assertThat(response.alerts()).anyMatch(alert -> alert.message().contains("negativ"));
    }

    @Test
    void liefertKontostandVerlaufChronologischAufsteigend() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        Instant t1 = Instant.parse("2025-01-01T10:00:00Z");
        Instant t2 = Instant.parse("2025-01-01T10:00:05Z");
        TelemetrySnapshot newer = new TelemetrySnapshot(farm, 2025, 1, 1, 10, 0, 30, 200L, "SUN", 11.4, t2, t2);
        TelemetrySnapshot older = new TelemetrySnapshot(farm, 2025, 1, 1, 9, 59, 30, 100L, "RAIN", 9.8, t1, t1);
        when(telemetrySnapshotRepository.findByFarmIdOrderByRecordedAtDesc(eq(1L), any(Pageable.class)))
                .thenReturn(List.of(newer, older));

        List<HistoryPoint> history = service.getMoneyHistory(20);

        assertThat(history).hasSize(2);
        assertThat(history.get(0).money()).isEqualTo(100L);
        assertThat(history.get(1).money()).isEqualTo(200L);
    }
}
