package de.farmpulse.backend.progression;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import de.farmpulse.backend.domain.SeasonGoalStatus;
import de.farmpulse.backend.domain.SeasonGoalType;
import de.farmpulse.backend.progression.dto.ProgressionResponse;
import de.farmpulse.backend.progression.dto.SeasonGoalResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(ProgressionController.class)
class ProgressionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProgressionService progressionService;

    @Test
    void getLiefertWerteUndSaisonziel() throws Exception {
        SeasonGoalResponse goal = new SeasonGoalResponse(SeasonGoalType.HARVEST_AMOUNT, "500 t Weizen ernten", "t",
                500, 184.5, "WHEAT", null, SeasonGoalStatus.ACTIVE);
        ProgressionResponse response = new ProgressionResponse(72, 81, goal);
        when(progressionService.getProgression()).thenReturn(response);

        mockMvc.perform(get("/api/progression"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reputationPercent").value(72))
                .andExpect(jsonPath("$.employeeSatisfactionPercent").value(81))
                .andExpect(jsonPath("$.seasonGoal.title").value("500 t Weizen ernten"))
                .andExpect(jsonPath("$.seasonGoal.targetValue").value(500))
                .andExpect(jsonPath("$.seasonGoal.currentValue").value(184.5));
    }
}
