package de.farmpulse.backend.ingest.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import de.farmpulse.backend.ingest.dto.FarmData;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class ExchangeFileReaderTest {

    private final ExchangeFileReader reader = new ExchangeFileReader(new ObjectMapper());

    @TempDir
    Path tempDir;

    @Test
    void liefertLeerOptionalWennDateiFehlt() {
        Path missing = tempDir.resolve("farm.json");

        Optional<ExchangeFile<FarmData>> result = reader.readIfNewer(missing, null, FarmData.class);

        assertThat(result).isEmpty();
    }

    @Test
    void liestDateiWennKeinVorherigerZeitpunktBekannt() throws IOException {
        Path file = writeFarmJson("Sonnenhof", "Keno");

        Optional<ExchangeFile<FarmData>> result = reader.readIfNewer(file, null, FarmData.class);

        assertThat(result).isPresent();
        assertThat(result.get().data().farmName()).isEqualTo("Sonnenhof");
        assertThat(result.get().data().playerName()).isEqualTo("Keno");
    }

    @Test
    void ueberspringtUnveraenderteDatei() throws IOException {
        Path file = writeFarmJson("Sonnenhof", "Keno");
        Instant mtime = Files.getLastModifiedTime(file).toInstant();

        Optional<ExchangeFile<FarmData>> result = reader.readIfNewer(file, mtime, FarmData.class);

        assertThat(result).isEmpty();
    }

    @Test
    void liestDateiWennNeuerAlsVorherigerZeitpunkt() throws IOException {
        Path file = writeFarmJson("Sonnenhof", "Keno");
        Instant before = Files.getLastModifiedTime(file).toInstant().minus(1, ChronoUnit.HOURS);

        Optional<ExchangeFile<FarmData>> result = reader.readIfNewer(file, before, FarmData.class);

        assertThat(result).isPresent();
    }

    @Test
    void liefertLeerOptionalBeiUngueltigemJson() throws IOException {
        Path file = tempDir.resolve("farm.json");
        Files.writeString(file, "{das ist kein json");

        Optional<ExchangeFile<FarmData>> result = reader.readIfNewer(file, null, FarmData.class);

        assertThat(result).isEmpty();
    }

    private Path writeFarmJson(String farmName, String playerName) throws IOException {
        Path file = tempDir.resolve("farm.json");
        Files.writeString(file, "{\"farmName\":\"" + farmName + "\",\"playerName\":\"" + playerName + "\"}");
        return file;
    }
}
