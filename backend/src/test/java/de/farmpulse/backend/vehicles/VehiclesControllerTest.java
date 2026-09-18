package de.farmpulse.backend.vehicles;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import de.farmpulse.backend.vehicles.dto.VehicleDetail;
import de.farmpulse.backend.vehicles.dto.VehiclesResponse;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(VehiclesController.class)
class VehiclesControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private VehiclesService vehiclesService;

    @Test
    void getLiefertFahrzeugeUndZusammenfassung() throws Exception {
        VehiclesResponse response = new VehiclesResponse(1, 245_000L, 92.0,
                List.of(new VehicleDetail("John Deere 8R 410", "Traktoren", 410.0, 128.5, 92.0, "OWNED", 245_000L)));
        when(vehiclesService.getVehicles()).thenReturn(response);

        mockMvc.perform(get("/api/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(1))
                .andExpect(jsonPath("$.items[0].name").value("John Deere 8R 410"))
                .andExpect(jsonPath("$.items[0].category").value("Traktoren"))
                .andExpect(jsonPath("$.items[0].horsepowerHp").value(410.0))
                .andExpect(jsonPath("$.items[0].ownershipStatus").value("OWNED"));
    }
}
