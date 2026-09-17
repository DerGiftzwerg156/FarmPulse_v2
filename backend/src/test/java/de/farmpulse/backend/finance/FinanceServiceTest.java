package de.farmpulse.backend.finance;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.finance.dto.FinanceResponse;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.web.server.ResponseStatusException;

class FinanceServiceTest {

    private FarmRepository farmRepository;
    private TelemetrySnapshotRepository telemetrySnapshotRepository;
    private FinanceService service;

    @BeforeEach
    void setUp() {
        farmRepository = mock(FarmRepository.class);
        telemetrySnapshotRepository = mock(TelemetrySnapshotRepository.class);
        service = new FinanceService(farmRepository, telemetrySnapshotRepository);
    }

    private Farm farmMitId(long id) {
        return new Farm(id, Instant.now());
    }

    private TelemetrySnapshot snapshot(Farm farm, long money, Instant recordedAt) {
        return new TelemetrySnapshot(farm, 2024, 6, 4, 8, 30, 30, money, "SUN", 11.4, recordedAt, recordedAt);
    }

    @Test
    void wirft404WennKeineFarmVorliegt() {
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getFinance(20)).isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void liefertNullwerteOhneTelemetrie() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(telemetrySnapshotRepository.findByFarmIdOrderByRecordedAtDesc(ArgumentMatchers.eq(1L), ArgumentMatchers.any(Pageable.class)))
                .thenReturn(List.of());

        FinanceResponse response = service.getFinance(20);

        assertThat(response.balance()).isZero();
        assertThat(response.history()).isEmpty();
    }

    @Test
    void berechnetEinnahmenUndAusgabenAusKontostandDeltas() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));

        Instant t0 = Instant.now().minus(3, ChronoUnit.HOURS);
        List<TelemetrySnapshot> newestFirst = List.of(
                snapshot(farm, 12_000L, t0.plus(2, ChronoUnit.HOURS)),
                snapshot(farm, 9_500L, t0.plus(1, ChronoUnit.HOURS)),
                snapshot(farm, 10_000L, t0));
        when(telemetrySnapshotRepository.findByFarmIdOrderByRecordedAtDesc(1L, PageRequest.of(0, 20)))
                .thenReturn(newestFirst);

        FinanceResponse response = service.getFinance(20);

        assertThat(response.balance()).isEqualTo(12_000L);
        assertThat(response.balanceDeltaInPeriod()).isEqualTo(2_000L);
        assertThat(response.incomeInPeriod()).isEqualTo(2_500L);
        assertThat(response.expenseInPeriod()).isEqualTo(500L);
        assertThat(response.history()).hasSize(3);
        assertThat(response.history().get(0).money()).isEqualTo(10_000L);
        assertThat(response.history().get(2).money()).isEqualTo(12_000L);
    }
}
