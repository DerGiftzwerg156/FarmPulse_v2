package de.farmpulse.backend.repository;

import de.farmpulse.backend.domain.SavegameBackstory;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SavegameBackstoryRepository extends JpaRepository<SavegameBackstory, Long> {

    /**
     * Es existiert zu jedem Zeitpunkt hoechstens eine Vorgeschichte (siehe
     * {@link SavegameBackstory}) - {@code findFirst...} liefert also
     * schlicht "die" Vorgeschichte, sofern schon eine eingegeben wurde.
     */
    Optional<SavegameBackstory> findFirstByOrderByIdAsc();

    /**
     * Die Vorgeschichte, falls sie eingegeben wurde, bevor die erste Farm
     * bekannt war (siehe {@link SavegameBackstory#getFarm()}) - wird
     * verwendet, um sie nachtraeglich mit der Farm zu verknuepfen, sobald
     * diese angelegt wird.
     */
    Optional<SavegameBackstory> findFirstByFarmIsNullOrderByIdAsc();
}
