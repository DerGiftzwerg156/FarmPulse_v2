package de.farmpulse.backend.savegame;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import de.farmpulse.backend.ingest.service.FarmIngestService;
import de.farmpulse.backend.ingest.service.TelemetryIngestService;
import de.farmpulse.backend.ingest.service.WorldIngestService;
import de.farmpulse.backend.savegame.dto.SavegameStatusResponse;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.MariaDBContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * End-to-End-Test gegen eine echte MariaDB (Testcontainers, siehe
 * IngestIntegrationTest): prueft, dass das Savegame erst als gestartet
 * gilt, wenn Vorgeschichte und alle drei Austauschdateien mindestens
 * einmal vorliegen - inklusive der nachtraeglichen Verknuepfung der
 * Vorgeschichte mit der Farm, wenn diese erst nach der Vorgeschichte
 * (via telemetry.json) bekannt wird.
 */
@SpringBootTest
@Testcontainers
@Transactional
class SavegameIntegrationTest {

    @Container
    static final MariaDBContainer<?> MARIADB = new MariaDBContainer<>("mariadb:11")
            .withDatabaseName("farmpulse")
            .withUsername("farmpulse")
            .withPassword("farmpulse");

    static Path exchangeDir;

    @BeforeAll
    static void createExchangeDir() throws IOException {
        exchangeDir = Files.createTempDirectory("farmpulse-savegame-test");
    }

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MARIADB::getJdbcUrl);
        registry.add("spring.datasource.username", MARIADB::getUsername);
        registry.add("spring.datasource.password", MARIADB::getPassword);
        registry.add("farmpulse.bridge.exchange-dir", () -> exchangeDir.toString());
    }

    @Autowired
    private SavegameService savegameService;

    @Autowired
    private TelemetryIngestService telemetryIngestService;

    @Autowired
    private WorldIngestService worldIngestService;

    @Autowired
    private FarmIngestService farmIngestService;

    @Test
    void savegameStartetErstNachVorgeschichteUndAllenDreiPolls() throws IOException {
        SavegameStatusResponse initial = savegameService.getStatus();
        assertThat(initial.started()).isFalse();
        assertThat(initial.backstorySubmitted()).isFalse();

        // Vorgeschichte wird eingegeben, bevor ueberhaupt ein Poll stattgefunden hat.
        SavegameStatusResponse afterBackstory = savegameService.submitBackstory("Es war einmal ein kleiner Hof.");
        assertThat(afterBackstory.backstorySubmitted()).isTrue();
        assertThat(afterBackstory.started()).isFalse();

        assertThatThrownBy(() -> savegameService.submitBackstory("Zweite Vorgeschichte"))
                .isInstanceOf(BackstoryAlreadySubmittedException.class);

        Files.writeString(exchangeDir.resolve("telemetry.json"),
                "{\"hour\":8,\"minute\":30,\"day\":4,\"month\":6,\"year\":2,\"daysPerMonth\":3,\"money\":84250,"
                        + "\"farmId\":1,\"weatherType\":\"SUN\",\"temperature\":11.4}");
        assertThat(telemetryIngestService.ingestIfChanged()).isPresent();

        SavegameStatusResponse afterTelemetry = savegameService.getStatus();
        assertThat(afterTelemetry.telemetryPolled()).isTrue();
        assertThat(afterTelemetry.worldPolled()).isFalse();
        assertThat(afterTelemetry.farmDataPolled()).isFalse();
        assertThat(afterTelemetry.started()).isFalse();

        Files.writeString(exchangeDir.resolve("world.json"),
                "{\"fleetValue\":125000,\"fields\":[],\"storages\":[]}");
        assertThat(worldIngestService.ingestIfChanged()).isPresent();

        Files.writeString(exchangeDir.resolve("farm.json"),
                "{\"farmName\":\"Sonnenhof\",\"playerName\":\"Keno\"}");
        assertThat(farmIngestService.ingestIfChanged()).isPresent();

        SavegameStatusResponse finalStatus = savegameService.getStatus();
        assertThat(finalStatus.started()).isTrue();
        assertThat(finalStatus.backstorySubmitted()).isTrue();
        assertThat(finalStatus.telemetryPolled()).isTrue();
        assertThat(finalStatus.worldPolled()).isTrue();
        assertThat(finalStatus.farmDataPolled()).isTrue();
    }
}
