package de.farmpulse.backend.fields;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.FieldSnapshot;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.fields.dto.FieldsResponse;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

class FieldsServiceTest {

    private FarmRepository farmRepository;
    private WorldSnapshotRepository worldSnapshotRepository;
    private FieldsService service;

    @BeforeEach
    void setUp() {
        farmRepository = mock(FarmRepository.class);
        worldSnapshotRepository = mock(WorldSnapshotRepository.class);
        service = new FieldsService(farmRepository, worldSnapshotRepository);
    }

    private Farm farmMitId(long id) {
        return new Farm(id, Instant.now());
    }

    @Test
    void wirft404WennKeineFarmVorliegt() {
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getFields()).isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void liefertLeereZusammenfassungOhneWorldSnapshot() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.empty());

        FieldsResponse response = service.getFields();

        assertThat(response.count()).isZero();
        assertThat(response.items()).isEmpty();
    }

    @Test
    void filtertNurEigeneFelderUndAggregiertAnbaudaten() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));

        WorldSnapshot world = new WorldSnapshot(farm, 100_000L, Instant.now(), Instant.now());
        world.addField(new FieldSnapshot(1, 1, 4.53, 32_000L, "WHEAT", 0.65, 10430.0));
        world.addField(new FieldSnapshot(2, 1, 6.1, 45_000L, null, null, null));
        world.addField(new FieldSnapshot(3, 0, 3.2, 28_000L, null, null, null));
        when(worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L)).thenReturn(Optional.of(world));

        FieldsResponse response = service.getFields();

        assertThat(response.count()).isEqualTo(2);
        assertThat(response.totalAreaHa()).isEqualTo(4.53 + 6.1);
        assertThat(response.totalValue()).isEqualTo(32_000L + 45_000L);
        assertThat(response.totalEstimatedYieldLiters()).isEqualTo(10430.0);
        assertThat(response.items()).hasSize(2);
        assertThat(response.items().get(0).fruitType()).isEqualTo("WHEAT");
        assertThat(response.items().get(0).growthState()).isEqualTo(0.65);
        assertThat(response.items().get(1).fruitType()).isNull();
    }
}
