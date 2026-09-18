package de.farmpulse.backend.vehicles;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.VehicleSnapshot;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import de.farmpulse.backend.vehicles.dto.VehiclesResponse;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

class VehiclesServiceTest {

    private FarmRepository farmRepository;
    private WorldSnapshotRepository worldSnapshotRepository;
    private VehiclesService service;

    @BeforeEach
    void setUp() {
        farmRepository = mock(FarmRepository.class);
        worldSnapshotRepository = mock(WorldSnapshotRepository.class);
        service = new VehiclesService(farmRepository, worldSnapshotRepository);
    }

    private Farm farmMitId(long id) {
        return new Farm(id, Instant.now());
    }

    @Test
    void wirft404WennKeineFarmVorliegt() {
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getVehicles()).isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void liefertLeereZusammenfassungOhneWorldSnapshot() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.empty());

        VehiclesResponse response = service.getVehicles();

        assertThat(response.count()).isZero();
        assertThat(response.totalSellValue()).isZero();
        assertThat(response.averageConditionPercent()).isNull();
        assertThat(response.items()).isEmpty();
    }

    @Test
    void aggregiertVerkaufswertUndDurchschnittlichenZustand() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));

        WorldSnapshot world = new WorldSnapshot(farm, 287_000L, Instant.now(), Instant.now());
        world.addVehicle(new VehicleSnapshot("John Deere 8R 410", "Traktoren", 410.0, 128.5, 92.0, "OWNED", 245_000L));
        world.addVehicle(new VehicleSnapshot("Anhaenger", "Sonstiges", null, null, null, "UNKNOWN", 42_000L));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.of(world));

        VehiclesResponse response = service.getVehicles();

        assertThat(response.count()).isEqualTo(2);
        assertThat(response.totalSellValue()).isEqualTo(245_000L + 42_000L);
        assertThat(response.averageConditionPercent()).isEqualTo(92.0);
        assertThat(response.items()).hasSize(2);
        assertThat(response.items().get(0).name()).isEqualTo("John Deere 8R 410");
        assertThat(response.items().get(0).category()).isEqualTo("Traktoren");
        assertThat(response.items().get(0).horsepowerHp()).isEqualTo(410.0);
        assertThat(response.items().get(0).ownershipStatus()).isEqualTo("OWNED");
        assertThat(response.items().get(1).horsepowerHp()).isNull();
        assertThat(response.items().get(1).ownershipStatus()).isEqualTo("UNKNOWN");
    }
}
