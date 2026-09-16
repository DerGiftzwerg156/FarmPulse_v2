package de.farmpulse.backend.savegame;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import de.farmpulse.backend.savegame.dto.SavegameStatusResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(SavegameController.class)
class SavegameControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private SavegameService savegameService;

    @Test
    void getLiefertDenAktuellenStatus() throws Exception {
        when(savegameService.getStatus()).thenReturn(new SavegameStatusResponse(false, true, true, false, false));

        mockMvc.perform(get("/api/savegame"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.started").value(false))
                .andExpect(jsonPath("$.backstorySubmitted").value(true))
                .andExpect(jsonPath("$.worldPolled").value(false));
    }

    @Test
    void postSpeichertVorgeschichteUndLiefert201() throws Exception {
        when(savegameService.submitBackstory("Es war einmal ein Hof."))
                .thenReturn(new SavegameStatusResponse(false, true, false, false, false));

        mockMvc.perform(post("/api/savegame/backstory")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"backstory\":\"Es war einmal ein Hof.\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.backstorySubmitted").value(true));
    }

    @Test
    void postLiefert409WennBereitsVorgeschichteVorhanden() throws Exception {
        when(savegameService.submitBackstory(eq("Neue Vorgeschichte")))
                .thenThrow(new BackstoryAlreadySubmittedException("bereits vorhanden"));

        mockMvc.perform(post("/api/savegame/backstory")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"backstory\":\"Neue Vorgeschichte\"}"))
                .andExpect(status().isConflict())
                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").value("bereits vorhanden"));
    }

    @Test
    void postLiefert400BeiLeererVorgeschichte() throws Exception {
        when(savegameService.submitBackstory(eq("")))
                .thenThrow(new InvalidBackstoryException("darf nicht leer sein"));

        mockMvc.perform(post("/api/savegame/backstory")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"backstory\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("darf nicht leer sein"));
    }
}
