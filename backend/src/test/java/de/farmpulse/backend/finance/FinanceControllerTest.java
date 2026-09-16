package de.farmpulse.backend.finance;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import de.farmpulse.backend.finance.dto.FinanceHistoryPoint;
import de.farmpulse.backend.finance.dto.FinanceResponse;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(FinanceController.class)
class FinanceControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private FinanceService financeService;

    @Test
    void getLiefertFinanzUebersicht() throws Exception {
        FinanceResponse response = new FinanceResponse(84_250L, 4_150L, 7_062L, 3_580L,
                List.of(new FinanceHistoryPoint(Instant.parse("2024-06-04T08:30:00Z"), 4, 84_250L)));
        when(financeService.getFinance(20)).thenReturn(response);

        mockMvc.perform(get("/api/finance"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.balance").value(84_250))
                .andExpect(jsonPath("$.incomeInPeriod").value(7_062))
                .andExpect(jsonPath("$.expenseInPeriod").value(3_580))
                .andExpect(jsonPath("$.history[0].money").value(84_250));
    }
}
