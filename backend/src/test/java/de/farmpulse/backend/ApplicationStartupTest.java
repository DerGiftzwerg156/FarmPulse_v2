package de.farmpulse.backend;

import static org.assertj.core.api.Assertions.assertThat;

import de.farmpulse.backend.config.BridgeExchangeProperties;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.MariaDBContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Startet die Anwendung mit einem echten eingebetteten Webserver (nicht nur
 * einem MockServletContext) und laesst die Default-Konfiguration aus
 * application.yml unveraendert - insbesondere
 * {@code farmpulse.bridge.exchange-dir: ../mock-exchange}.
 *
 * <p>Deckt damit gezielt eine Bug-Klasse ab, die ein
 * {@code @SpringBootTest} im (impliziten) MOCK-Webumfeld nicht aufdeckt:
 * Spring bindet {@link java.nio.file.Path}-Properties in einer echten
 * Webanwendung ueber die Servlet-{@code Resource}-Aufloesung statt per
 * einfachem {@code Paths.get(...)} - ein relativer Pfad mit {@code ..} liess
 * sich darueber nicht ueber die Servlet-Context-Wurzel hinaus aufloesen
 * ("has been normalized to [null] which is not valid"). Siehe
 * {@link BridgeExchangeProperties}, dort seitdem bewusst {@code String}
 * statt {@code Path}.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class ApplicationStartupTest {

    @Container
    static final MariaDBContainer<?> MARIADB = new MariaDBContainer<>("mariadb:11")
            .withDatabaseName("farmpulse")
            .withUsername("farmpulse")
            .withPassword("farmpulse");

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", MARIADB::getJdbcUrl);
        registry.add("spring.datasource.username", MARIADB::getUsername);
        registry.add("spring.datasource.password", MARIADB::getPassword);
    }

    @Autowired
    private BridgeExchangeProperties properties;

    @Test
    void kontextStartetMitUnveraenderterDefaultKonfiguration() {
        assertThat(properties.exchangeDirPath()).isNotNull();
    }
}
