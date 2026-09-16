package de.farmpulse.backend.mailbox;

import com.fasterxml.jackson.databind.ObjectMapper;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.MailboxMessage;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.MailboxMessageRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import java.io.IOException;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Random;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Erzeugt periodisch neue Postfach-Nachrichten (siehe {@link MailboxMessage}).
 *
 * <p>Es gibt noch keine KI-Anbindung: Inhalte stammen ausschliesslich aus der
 * mitgelieferten Mock-Vorlagendatei {@code mailbox-templates.json}
 * (classpath {@code mailbox/mailbox-templates.json}), rein zufaellig
 * ausgewaehlt in {@link #selectTemplate()}. Diese Methode ist bewusst die
 * einzige Stelle, die eine Nachricht "erfindet" - sobald eine echte
 * KI-Anbindung existiert, ersetzt sie ausschliesslich {@link #selectTemplate()}
 * (z.B. durch einen Prompt mit der Vorgeschichte aus
 * {@code de.farmpulse.backend.domain.SavegameBackstory} und dem aktuellen
 * Farm-Zustand aus {@code de.farmpulse.backend.dashboard.DashboardService})
 * - der restliche Ablauf (Farm/Spielzeit ermitteln, Nachricht speichern)
 * bleibt unveraendert.
 */
@Service
public class MailboxGenerationService {

    private static final Logger log = LoggerFactory.getLogger(MailboxGenerationService.class);
    private static final String TEMPLATES_RESOURCE = "mailbox/mailbox-templates.json";

    private final MailboxMessageRepository mailboxMessageRepository;
    private final FarmRepository farmRepository;
    private final TelemetrySnapshotRepository telemetrySnapshotRepository;
    private final List<MailboxTemplate> templates;
    private final Random random = new Random();

    public MailboxGenerationService(MailboxMessageRepository mailboxMessageRepository, FarmRepository farmRepository,
            TelemetrySnapshotRepository telemetrySnapshotRepository, ObjectMapper objectMapper) {
        this.mailboxMessageRepository = mailboxMessageRepository;
        this.farmRepository = farmRepository;
        this.telemetrySnapshotRepository = telemetrySnapshotRepository;
        this.templates = loadTemplates(objectMapper);
    }

    private static List<MailboxTemplate> loadTemplates(ObjectMapper objectMapper) {
        try {
            MailboxTemplate[] templates = objectMapper.readValue(
                    new ClassPathResource(TEMPLATES_RESOURCE).getInputStream(), MailboxTemplate[].class);
            return List.of(templates);
        } catch (IOException e) {
            log.error("Konnte {} nicht laden - Postfach bleibt ohne generierte Nachrichten.", TEMPLATES_RESOURCE, e);
            return List.of();
        }
    }

    @Scheduled(fixedDelayString = "${farmpulse.mailbox.generation-interval-ms:180000}")
    public void generateOnSchedule() {
        generate();
    }

    /**
     * Erzeugt (sofern eine Farm und mindestens eine Telemetrie-Momentaufnahme
     * vorliegen) eine neue Postfach-Nachricht und speichert sie.
     *
     * @return die gespeicherte Nachricht, oder leer, wenn noch keine Farm/
     *         Telemetrie vorliegt oder keine Vorlagen geladen werden konnten
     */
    @Transactional
    public Optional<MailboxMessage> generate() {
        if (templates.isEmpty()) {
            return Optional.empty();
        }

        Optional<Farm> farm = farmRepository.findTopByOrderByUpdatedAtDesc();
        if (farm.isEmpty()) {
            return Optional.empty();
        }

        Optional<TelemetrySnapshot> telemetry =
                telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(farm.get().getId());
        if (telemetry.isEmpty()) {
            return Optional.empty();
        }

        MailboxTemplate template = selectTemplate();
        TelemetrySnapshot snapshot = telemetry.get();
        MailboxMessage message = new MailboxMessage(farm.get(), template.sender(), template.subject(),
                template.body(), template.category(), template.priority(), snapshot.getGameYear(),
                snapshot.getGameMonth(), snapshot.getGameDay(), snapshot.getGameHour(), snapshot.getGameMinute(),
                Instant.now());

        MailboxMessage saved = mailboxMessageRepository.save(message);
        log.debug("Postfach-Nachricht generiert (farmId={}, category={})", farm.get().getId(), template.category());
        return Optional.of(saved);
    }

    /**
     * TODO(KI-Integration): Diese Methode waehlt aktuell nur zufaellig eine
     * statische Mock-Vorlage aus. Sobald eine echte KI-Anbindung existiert,
     * hier durch einen generierten Vorschlag ersetzen (z.B. LLM-Aufruf mit
     * der Vorgeschichte + aktuellem Farm-Zustand als Kontext) - die
     * Rueckgabe muss weiterhin sender/category/priority/subject/body liefern.
     */
    private MailboxTemplate selectTemplate() {
        return templates.get(random.nextInt(templates.size()));
    }
}
