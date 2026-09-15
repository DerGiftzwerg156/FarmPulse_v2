package de.farmpulse.backend.ingest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import de.farmpulse.backend.config.BridgeExchangeProperties;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.ingest.dto.FarmData;
import de.farmpulse.backend.processing.FarmProcessingStep;
import de.farmpulse.backend.repository.FarmRepository;
import java.nio.file.Path;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class FarmIngestServiceTest {

    @TempDir
    Path exchangeDir;

    private ExchangeFileReader fileReader;
    private FarmRepository farmRepository;
    private FarmIngestService service;

    @BeforeEach
    void setUp() {
        fileReader = mock(ExchangeFileReader.class);
        farmRepository = mock(FarmRepository.class);
        FarmProcessingStep passthrough = raw -> raw;
        BridgeExchangeProperties properties = new BridgeExchangeProperties(exchangeDir, 5000, 30000, 60000);

        service = new FarmIngestService(properties, fileReader, passthrough, farmRepository);
    }

    @Test
    void ueberspringtPollWennNochKeineFarmBekannt() {
        FarmData data = new FarmData("Sonnenhof", "Keno");
        when(fileReader.readIfNewer(any(), any(), eq(FarmData.class)))
                .thenReturn(Optional.of(new ExchangeFile<>(data, Instant.now())));
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.empty());

        Optional<Farm> result = service.ingestIfChanged();

        assertThat(result).isEmpty();
    }

    @Test
    void aktualisiertNameUndSpielernameDerZuletztAktivenFarm() {
        FarmData data = new FarmData("Sonnenhof", "Keno");
        when(fileReader.readIfNewer(any(), any(), eq(FarmData.class)))
                .thenReturn(Optional.of(new ExchangeFile<>(data, Instant.now())));
        Farm farm = new Farm(1L, Instant.parse("2024-01-01T00:00:00Z"));
        when(farmRepository.findTopByOrderByUpdatedAtDesc()).thenReturn(Optional.of(farm));

        Optional<Farm> result = service.ingestIfChanged();

        assertThat(result).isPresent();
        assertThat(result.get().getName()).isEqualTo("Sonnenhof");
        assertThat(result.get().getPlayerName()).isEqualTo("Keno");
    }
}
