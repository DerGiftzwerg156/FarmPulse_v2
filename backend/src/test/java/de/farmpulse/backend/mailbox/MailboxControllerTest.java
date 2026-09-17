package de.farmpulse.backend.mailbox;

import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import de.farmpulse.backend.domain.MailboxPriority;
import de.farmpulse.backend.mailbox.dto.MailboxMessageResponse;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpStatus;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.server.ResponseStatusException;

@WebMvcTest(MailboxController.class)
class MailboxControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private MailboxService mailboxService;

    @Test
    void getLiefertLeereListeOhneFarm() throws Exception {
        when(mailboxService.getMessages()).thenReturn(List.of());

        mockMvc.perform(get("/api/mailbox"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    void getLiefertNachrichtenDerAktivenFarm() throws Exception {
        MailboxMessageResponse response = new MailboxMessageResponse(1L, "Wetterdienst", "Unwetterwarnung", "Text",
                "WEATHER", MailboxPriority.HIGH, 2025, 6, 12, 8, 30, false, Instant.now());
        when(mailboxService.getMessages()).thenReturn(List.of(response));

        mockMvc.perform(get("/api/mailbox"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].sender").value("Wetterdienst"))
                .andExpect(jsonPath("$[0].priority").value("HIGH"))
                .andExpect(jsonPath("$[0].read").value(false));
    }

    @Test
    void postReadLiefert404WennNachrichtFehlt() throws Exception {
        doThrow(new ResponseStatusException(HttpStatus.NOT_FOUND, "Nachricht nicht gefunden."))
                .when(mailboxService).markRead(99L);

        mockMvc.perform(post("/api/mailbox/99/read"))
                .andExpect(status().isNotFound());
    }

    @Test
    void postReadMarkiertNachrichtAlsGelesen() throws Exception {
        mockMvc.perform(post("/api/mailbox/1/read"))
                .andExpect(status().isNoContent());
    }
}
