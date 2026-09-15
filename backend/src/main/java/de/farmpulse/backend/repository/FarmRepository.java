package de.farmpulse.backend.repository;

import de.farmpulse.backend.domain.Farm;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FarmRepository extends JpaRepository<Farm, Long> {

    /**
     * Liefert die zuletzt aktive Farm. world.json und farm.json enthalten
     * (anders als telemetry.json) selbst keine FarmID (siehe Bridge/README.md,
     * Abschnitte "Dateiformat: world.json"/"Dateiformat: farm.json") - die
     * aktuelle FarmPulse Bridge exportiert pro laufendem FS25-Client ohnehin
     * nur einen aktiven Spielstand, weshalb sich world.json/farm.json
     * eindeutig der zuletzt ueber telemetry.json gesehenen Farm zuordnen
     * lassen. Werden spaeter mehrere gleichzeitige Farmen/Spielstaende pro
     * Instanz benoetigt, muesste die Bridge world.json/farm.json um eine
     * farmId ergaenzen.
     */
    Optional<Farm> findTopByOrderByUpdatedAtDesc();
}
