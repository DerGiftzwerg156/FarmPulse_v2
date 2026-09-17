package de.farmpulse.backend.fields;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import de.farmpulse.backend.fields.dto.FieldDetail;
import de.farmpulse.backend.fields.dto.FieldsResponse;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(FieldsController.class)
class FieldsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private FieldsService fieldsService;

    @Test
    void getLiefertFelderUndZusammenfassung() throws Exception {
        FieldsResponse response = new FieldsResponse(1, 4.53, 32_000L, 10430.0,
                List.of(new FieldDetail(1, 4.53, 32_000L, "WHEAT", 0.65, 10430.0)));
        when(fieldsService.getFields()).thenReturn(response);

        mockMvc.perform(get("/api/fields"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(1))
                .andExpect(jsonPath("$.items[0].fruitType").value("WHEAT"))
                .andExpect(jsonPath("$.items[0].growthState").value(0.65));
    }
}
