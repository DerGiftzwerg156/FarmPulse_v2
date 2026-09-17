package de.farmpulse.backend.progression;

import de.farmpulse.backend.progression.dto.ProgressionResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-Schnittstelle fuer die "Werte"- und "Saisonziel"-Panels auf der
 * Finanzen-Seite im Frontend (Vorlage MockDashboard/Finances.html).
 */
@RestController
@RequestMapping("/api/progression")
public class ProgressionController {

    private final ProgressionService progressionService;

    public ProgressionController(ProgressionService progressionService) {
        this.progressionService = progressionService;
    }

    @GetMapping
    public ProgressionResponse progression() {
        return progressionService.getProgression();
    }
}
