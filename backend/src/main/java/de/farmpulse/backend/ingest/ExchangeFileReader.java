package de.farmpulse.backend.ingest;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Liest eine von der Bridge geschriebene Austauschdatei (telemetry.json,
 * world.json, farm.json) ein, sofern sie seit dem zuletzt verarbeiteten
 * Zeitpunkt tatsaechlich neu geschrieben wurde. Als realer Zeitstempel des
 * Exports dient die Datei-mtime, da die Bridge selbst keinen Wall-Clock-
 * Zeitstempel in die Dateien schreibt (nur In-Game-Datum/-Uhrzeit, siehe
 * Bridge/README.md, Abschnitt "Dateiformat: telemetry.json").
 *
 * <p>Fehlt die Datei (z.B. Bridge noch nicht aktiviert) oder laesst sie sich
 * nicht parsen, wird das - analog zum Resilienz-Prinzip der Bridge selbst
 * (siehe Bridge/README.md, "Jeder dieser Zugriffe ist trotzdem ueber
 * pcall() abgesichert") - nur geloggt statt eine Exception zu werfen; der
 * naechste Poll versucht es erneut.
 */
@Component
public class ExchangeFileReader {

    private static final Logger log = LoggerFactory.getLogger(ExchangeFileReader.class);

    private final ObjectMapper objectMapper;

    public ExchangeFileReader(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * @param file       Pfad der Austauschdatei
     * @param after      nur einlesen, wenn die Datei-mtime nach diesem Zeitpunkt liegt (null = immer einlesen)
     * @param type       Zieltyp fuer das JSON-Parsing
     * @return die geparsten Daten samt mtime, oder leer, wenn die Datei fehlt, unveraendert ist oder nicht geparst werden konnte
     */
    public <T> Optional<ExchangeFile<T>> readIfNewer(Path file, Instant after, Class<T> type) {
        if (!Files.isRegularFile(file)) {
            log.debug("Austauschdatei {} existiert (noch) nicht - ueberspringe.", file);
            return Optional.empty();
        }

        Instant mtime;
        try {
            mtime = Files.getLastModifiedTime(file).toInstant();
        } catch (IOException e) {
            log.warn("Konnte mtime von {} nicht lesen: {}", file, e.getMessage());
            return Optional.empty();
        }

        if (after != null && !mtime.isAfter(after)) {
            log.debug("Austauschdatei {} unveraendert seit {} (mtime={}) - ueberspringe.", file, after, mtime);
            return Optional.empty();
        }

        try {
            T data = objectMapper.readValue(file.toFile(), type);
            log.debug("Austauschdatei {} als {} gelesen (mtime={}).", file, type.getSimpleName(), mtime);
            return Optional.of(new ExchangeFile<>(data, mtime));
        } catch (IOException e) {
            log.warn("Konnte {} nicht als {} parsen: {}", file, type.getSimpleName(), e.getMessage());
            return Optional.empty();
        }
    }
}
