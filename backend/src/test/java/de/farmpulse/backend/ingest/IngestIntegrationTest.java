package de.farmpulse.backend.ingest;

import static org.assertj.core.api.Assertions.assertThat;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.ingest.service.FarmIngestService;
import de.farmpulse.backend.ingest.service.TelemetryIngestService;
import de.farmpulse.backend.ingest.service.WorldIngestService;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
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
 * End-to-End-Test gegen eine echte MariaDB (Testcontainers): prueft, dass
 * die Flyway-Migrationen (src/main/resources/db/migration) anstandslos
 * anwenden und die drei Ingest-Services die Austauschdateien korrekt in
 * historisierte Entitaeten abbilden und persistieren.
 *
 * <p>{@code @Transactional} haelt die Hibernate-Session ueber den gesamten
 * Testmethodenaufruf offen, damit die lazy geladenen Collections
 * ({@link WorldSnapshot#getFields()}/{@link WorldSnapshot#getStorages()})
 * nach dem erneuten Laden ueber das Repository noch initialisiert werden
 * koennen (Anwendung selbst laeuft bewusst mit {@code open-in-view: false},
 * siehe application.yml) - die Ingest-Services bleiben dabei unveraendert
 * eigenstaendig transaktional (Propagation.REQUIRED reiht sich hier nur in
 * die Test-Transaktion ein).
 */
@SpringBootTest
@Testcontainers
@Transactional
class IngestIntegrationTest {

    @Container
    static final MariaDBContainer<?> MARIADB = new MariaDBContainer<>("mariadb:11")
            .withDatabaseName("farmpulse")
            .withUsername("farmpulse")
            .withPassword("farmpulse");

    static Path exchangeDir;

    @BeforeAll
    static void createExchangeDir() throws IOException {
        exchangeDir = Files.createTempDirectory("farmpulse-exchange-test");
    }

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MARIADB::getJdbcUrl);
        registry.add("spring.datasource.username", MARIADB::getUsername);
        registry.add("spring.datasource.password", MARIADB::getPassword);
        registry.add("farmpulse.bridge.exchange-dir", () -> exchangeDir.toString());
    }

    @Autowired
    private TelemetryIngestService telemetryIngestService;

    @Autowired
    private WorldIngestService worldIngestService;

    @Autowired
    private FarmIngestService farmIngestService;

    @Autowired
    private FarmRepository farmRepository;

    @Autowired
    private TelemetrySnapshotRepository telemetrySnapshotRepository;

    @Autowired
    private WorldSnapshotRepository worldSnapshotRepository;

    @Test
    void liestAlleDreiAustauschdateienEinUndHistorisiertSieInMariaDb() throws IOException {
        Files.writeString(exchangeDir.resolve("telemetry.json"),
                "{\"hour\":8,\"minute\":30,\"day\":4,\"month\":6,\"year\":2,\"daysPerMonth\":3,\"money\":84250,"
                        + "\"farmId\":1,\"weatherType\":\"SUN\",\"temperature\":11.4}");
        Files.writeString(exchangeDir.resolve("world.json"),
                "{\"fleetValue\":125000,"
                        + "\"vehicles\":[{\"name\":\"John Deere 8R 410\",\"horsepowerHp\":410,"
                        + "\"operatingHours\":128.5,\"conditionPercent\":92,\"sellPrice\":245000}],"
                        + "\"fields\":[{\"fieldId\":1,\"ownerFarmId\":1,\"sizeHa\":4.53,\"price\":32000}],"
                        + "\"storages\":[{\"fillType\":\"WHEAT\",\"amount\":5000,\"capacity\":20000}]}");
        Files.writeString(exchangeDir.resolve("farm.json"),
                "{\"farmName\":\"Sonnenhof\",\"playerName\":\"Keno\"}");

        assertThat(telemetryIngestService.ingestIfChanged()).isPresent();
        assertThat(worldIngestService.ingestIfChanged()).isPresent();
        assertThat(farmIngestService.ingestIfChanged()).isPresent();

        Farm farm = farmRepository.findById(1L).orElseThrow();
        assertThat(farm.getName()).isEqualTo("Sonnenhof");
        assertThat(farm.getPlayerName()).isEqualTo("Keno");

        assertThat(telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L))
                .hasValueSatisfying(snapshot -> assertThat(snapshot.getMoney()).isEqualTo(84250));

        WorldSnapshot worldSnapshot = worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(1L).orElseThrow();
        assertThat(worldSnapshot.getFleetValue()).isEqualTo(125000);
        assertThat(worldSnapshot.getVehicles()).hasSize(1);
        assertThat(worldSnapshot.getFields()).hasSize(1);
        assertThat(worldSnapshot.getStorages()).hasSize(1);

        // erneuter Poll ohne Aenderung an den Dateien darf keine weiteren Zeilen anlegen
        assertThat(telemetryIngestService.ingestIfChanged()).isEmpty();
        assertThat(worldIngestService.ingestIfChanged()).isEmpty();
        assertThat(farmIngestService.ingestIfChanged()).isEmpty();
    }
}
