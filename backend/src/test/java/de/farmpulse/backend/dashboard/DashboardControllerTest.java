package de.farmpulse.backend.dashboard;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import de.farmpulse.backend.dashboard.dto.Alert;
import de.farmpulse.backend.dashboard.dto.DashboardResponse;
import de.farmpulse.backend.dashboard.dto.FarmInfo;
import de.farmpulse.backend.dashboard.dto.FieldsSummary;
import de.farmpulse.backend.dashboard.dto.GameTime;
import de.farmpulse.backend.dashboard.dto.HistoryPoint;
import de.farmpulse.backend.dashboard.dto.WeatherInfo;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(DashboardController.class)
class DashboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DashboardService dashboardService;

    @Test
    void getLiefertDenAggregiertenZustand() throws Exception {
        DashboardResponse response = new DashboardResponse(
                new FarmInfo(1L, "Sonnenhof", "Keno"),
                new GameTime(2025, 6, 12, 8, 30, 30),
                new WeatherInfo("SUN", 11.4),
                50_000L,
                250_000L,
                new FieldsSummary(1, 5.0, 20_000L, List.of()),
                List.of(),
                List.of(new Alert(Alert.Severity.WARNING, "Der Kontostand ist negativ.")));
        when(dashboardService.getDashboard()).thenReturn(response);

        mockMvc.perform(get("/api/dashboard"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.farm.name").value("Sonnenhof"))
                .andExpect(jsonPath("$.money").value(50_000))
                .andExpect(jsonPath("$.fleetValue").value(250_000))
                .andExpect(jsonPath("$.fields.count").value(1))
                .andExpect(jsonPath("$.weather.type").value("SUN"))
                .andExpect(jsonPath("$.weather.temperature").value(11.4))
                .andExpect(jsonPath("$.alerts[0].message").value("Der Kontostand ist negativ."));
    }

    @Test
    void getLiefert404WennKeineFarmVorliegt() throws Exception {
        when(dashboardService.getDashboard()).thenThrow(new NoActiveFarmException("Es liegt noch keine Farm vor."));

        mockMvc.perform(get("/api/dashboard"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Es liegt noch keine Farm vor."));
    }

    @Test
    void historyLiefertDenKontostandVerlauf() throws Exception {
        when(dashboardService.getMoneyHistory(20)).thenReturn(List.of(
                new HistoryPoint(Instant.parse("2025-01-01T10:00:00Z"), new GameTime(2025, 1, 1, 10, 0, 30), 100L)));

        mockMvc.perform(get("/api/dashboard/history"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].money").value(100));
    }

    @Test
    void historyNutztLimitParameter() throws Exception {
        when(dashboardService.getMoneyHistory(5)).thenReturn(List.of());

        mockMvc.perform(get("/api/dashboard/history").param("limit", "5"))
                .andExpect(status().isOk());
    }
}
