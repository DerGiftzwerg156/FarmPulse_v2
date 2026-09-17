package de.farmpulse.backend.progression;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.FarmValues;
import de.farmpulse.backend.domain.SeasonGoal;
import de.farmpulse.backend.domain.SeasonGoalStatus;
import de.farmpulse.backend.progression.dto.ProgressionResponse;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.FarmValuesRepository;
import de.farmpulse.backend.repository.SeasonGoalRepository;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.invocation.InvocationOnMock;
import org.springframework.web.server.ResponseStatusException;

class ProgressionServiceTest {

    private FarmRepository farmRepository;
    private FarmValuesRepository farmValuesRepository;
    private SeasonGoalRepository seasonGoalRepository;
    private ProgressionService service;

    @BeforeEach
    void setUp() {
        farmRepository = mock(FarmRepository.class);
        farmValuesRepository = mock(FarmValuesRepository.class);
        seasonGoalRepository = mock(SeasonGoalRepository.class);
        // Echter ObjectMapper: laedt zugleich die tatsaechliche
        // season-goal-templates.json mit - validiert damit deren Syntax.
        service = new ProgressionService(farmRepository, farmValuesRepository, seasonGoalRepository,
                new ObjectMapper());
    }

    private Farm farmMitId(long id) {
        return new Farm(id, Instant.now());
    }

    @Test
    void wirft404WennKeineFarmVorliegt() {
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getProgression()).isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void legtBeimErstenAufrufNeutralePlatzhalterwerteAn() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        when(farmValuesRepository.findById(1L)).thenReturn(Optional.empty());
        when(farmValuesRepository.save(any(FarmValues.class))).thenAnswer((InvocationOnMock inv) -> inv.getArgument(0));
        when(seasonGoalRepository.findFirstByFarmIdAndStatusOrderByCreatedAtDesc(1L, SeasonGoalStatus.ACTIVE))
                .thenReturn(Optional.empty());
        when(seasonGoalRepository.save(any(SeasonGoal.class))).thenAnswer((InvocationOnMock inv) -> inv.getArgument(0));

        ProgressionResponse response = service.getProgression();

        assertThat(response.reputationPercent()).isEqualTo(50);
        assertThat(response.employeeSatisfactionPercent()).isEqualTo(50);
        assertThat(response.seasonGoal()).isNotNull();
        assertThat(response.seasonGoal().currentValue()).isZero();
        assertThat(response.seasonGoal().status()).isEqualTo(SeasonGoalStatus.ACTIVE);

        ArgumentCaptor<FarmValues> valuesCaptor = ArgumentCaptor.forClass(FarmValues.class);
        verify(farmValuesRepository).save(valuesCaptor.capture());
        assertThat(valuesCaptor.getValue().getFarm()).isSameAs(farm);

        verify(seasonGoalRepository).save(any(SeasonGoal.class));
    }

    @Test
    void liestVorhandeneWerteUndAktivesZielUnveraendertAus() {
        Farm farm = farmMitId(1L);
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));
        FarmValues values = new FarmValues(farm, 72, 81, Instant.now());
        when(farmValuesRepository.findById(1L)).thenReturn(Optional.of(values));
        SeasonGoal goal = new SeasonGoal(farm, de.farmpulse.backend.domain.SeasonGoalType.HARVEST_AMOUNT,
                "500 t Weizen ernten", "t", 500, 184.5, "WHEAT", null, SeasonGoalStatus.ACTIVE, Instant.now());
        when(seasonGoalRepository.findFirstByFarmIdAndStatusOrderByCreatedAtDesc(1L, SeasonGoalStatus.ACTIVE))
                .thenReturn(Optional.of(goal));

        ProgressionResponse response = service.getProgression();

        assertThat(response.reputationPercent()).isEqualTo(72);
        assertThat(response.employeeSatisfactionPercent()).isEqualTo(81);
        assertThat(response.seasonGoal().title()).isEqualTo("500 t Weizen ernten");
        assertThat(response.seasonGoal().targetValue()).isEqualTo(500);
        assertThat(response.seasonGoal().currentValue()).isEqualTo(184.5);
        assertThat(response.seasonGoal().fillType()).isEqualTo("WHEAT");

        verify(farmValuesRepository, never()).save(any());
        verify(seasonGoalRepository, never()).save(any());
    }
}
