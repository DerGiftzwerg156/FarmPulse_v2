package de.farmpulse.backend.progression;

import com.fasterxml.jackson.databind.ObjectMapper;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.FarmValues;
import de.farmpulse.backend.domain.SeasonGoal;
import de.farmpulse.backend.domain.SeasonGoalStatus;
import de.farmpulse.backend.progression.dto.ProgressionResponse;
import de.farmpulse.backend.progression.dto.SeasonGoalResponse;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.FarmValuesRepository;
import de.farmpulse.backend.repository.SeasonGoalRepository;
import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Random;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Liefert die "weichen" Farm-Kennzahlen (Reputation, Mitarbeiterzufriedenheit)
 * sowie das aktuelle Saisonziel fuer die Finanzen-Seite im Frontend (Vorlage
 * MockDashboard/Finances.html, Panels "Werte" und "Saisonziel").
 *
 * <p><b>Wichtig:</b> Beide Konzepte stammen nicht aus der Bridge - FS25 kennt
 * weder Reputation/Mitarbeiterzufriedenheit noch Saisonziele (siehe
 * {@link FarmValues}/{@link SeasonGoal}). Diese Klasse legt beim ersten
 * Aufruf je Farm einmalig Platzhalterwerte an (neutrale 50% fuer die Werte,
 * ein zufaellig aus {@code season-goal-templates.json} gewaehltes Saisonziel
 * mit {@code currentValue = 0}) und liest sie danach unveraendert aus einer
 * Tabelle. Die eigentliche Berechnungslogik (wie sich Reputation/
 * Mitarbeiterzufriedenheit veraendern, wie der Fortschritt eines Saisonziels
 * aus dem tatsaechlichen Farm-Zustand ermittelt wird) ist bewusst noch nicht
 * implementiert - diese Klasse ist die vorgesehene Stelle dafuer.
 */
@Service
public class ProgressionService {

    private static final Logger log = LoggerFactory.getLogger(ProgressionService.class);
    private static final String TEMPLATES_RESOURCE = "progression/season-goal-templates.json";
    private static final int DEFAULT_REPUTATION_PERCENT = 50;
    private static final int DEFAULT_EMPLOYEE_SATISFACTION_PERCENT = 50;

    private final FarmRepository farmRepository;
    private final FarmValuesRepository farmValuesRepository;
    private final SeasonGoalRepository seasonGoalRepository;
    private final List<SeasonGoalTemplate> templates;
    private final Random random = new Random();

    public ProgressionService(FarmRepository farmRepository, FarmValuesRepository farmValuesRepository,
            SeasonGoalRepository seasonGoalRepository, ObjectMapper objectMapper) {
        this.farmRepository = farmRepository;
        this.farmValuesRepository = farmValuesRepository;
        this.seasonGoalRepository = seasonGoalRepository;
        this.templates = loadTemplates(objectMapper);
    }

    private static List<SeasonGoalTemplate> loadTemplates(ObjectMapper objectMapper) {
        try {
            SeasonGoalTemplate[] templates = objectMapper.readValue(
                    new ClassPathResource(TEMPLATES_RESOURCE).getInputStream(), SeasonGoalTemplate[].class);
            return List.of(templates);
        } catch (IOException e) {
            log.error("Konnte {} nicht laden - es wird kein Saisonziel angelegt.", TEMPLATES_RESOURCE, e);
            return List.of();
        }
    }

    @Transactional
    public ProgressionResponse getProgression() {
        Farm farm = farmRepository.findTopByOrderByUpdatedAtDesc()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Es liegt noch keine Farm vor."));

        FarmValues values = farmValuesRepository.findById(farm.getId()).orElseGet(() -> initializeFarmValues(farm));
        SeasonGoal goal = seasonGoalRepository
                .findFirstByFarmIdAndStatusOrderByCreatedAtDesc(farm.getId(), SeasonGoalStatus.ACTIVE)
                .or(() -> initializeSeasonGoal(farm))
                .orElse(null);

        return new ProgressionResponse(values.getReputationPercent(), values.getEmployeeSatisfactionPercent(),
                goal != null ? toSeasonGoalResponse(goal) : null);
    }

    private FarmValues initializeFarmValues(Farm farm) {
        FarmValues values = new FarmValues(farm, DEFAULT_REPUTATION_PERCENT, DEFAULT_EMPLOYEE_SATISFACTION_PERCENT,
                Instant.now());
        FarmValues saved = farmValuesRepository.save(values);
        log.debug("Farm-Werte initialisiert (farmId={})", farm.getId());
        return saved;
    }

    private Optional<SeasonGoal> initializeSeasonGoal(Farm farm) {
        if (templates.isEmpty()) {
            return Optional.empty();
        }
        SeasonGoalTemplate template = templates.get(random.nextInt(templates.size()));
        SeasonGoal goal = new SeasonGoal(farm, template.type(), template.title(), template.unit(),
                template.targetValue(), 0.0, template.fillType(), template.deadlineLabel(), SeasonGoalStatus.ACTIVE,
                Instant.now());
        SeasonGoal saved = seasonGoalRepository.save(goal);
        log.debug("Saisonziel angelegt (farmId={}, type={}, title={})", farm.getId(), template.type(),
                template.title());
        return Optional.of(saved);
    }

    private SeasonGoalResponse toSeasonGoalResponse(SeasonGoal goal) {
        return new SeasonGoalResponse(goal.getType(), goal.getTitle(), goal.getUnit(), goal.getTargetValue(),
                goal.getCurrentValue(), goal.getFillType(), goal.getDeadlineLabel(), goal.getStatus());
    }
}
