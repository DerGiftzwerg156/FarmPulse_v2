package de.farmpulse.backend.vehicles;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.VehicleSnapshot;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import de.farmpulse.backend.vehicles.dto.VehicleDetail;
import de.farmpulse.backend.vehicles.dto.VehiclesResponse;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Liest die Fahrzeuge der aktiven Farm (siehe {@link VehicleSnapshot}) fuer
 * die Flotten-Seite im Frontend. Anders als bei Feldern liefert die Bridge
 * bereits nur Fahrzeuge der aktuellen Farm (siehe
 * {@code FarmPulseBridge.readVehicles(farmId)}) - eine zusaetzliche
 * Besitzer-Filterung ist hier deshalb nicht noetig.
 */
@Service
public class VehiclesService {

    private final FarmRepository farmRepository;
    private final WorldSnapshotRepository worldSnapshotRepository;

    public VehiclesService(FarmRepository farmRepository, WorldSnapshotRepository worldSnapshotRepository) {
        this.farmRepository = farmRepository;
        this.worldSnapshotRepository = worldSnapshotRepository;
    }

    @Transactional(readOnly = true)
    public VehiclesResponse getVehicles() {
        Farm farm = farmRepository.findTopByOrderByUpdatedAtDesc()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Es liegt noch keine Farm vor."));

        Optional<WorldSnapshot> world = worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(farm.getId());
        if (world.isEmpty()) {
            return new VehiclesResponse(0, 0L, null, List.of());
        }

        List<VehicleDetail> items = world.get().getVehicles().stream()
                .map(VehiclesService::toVehicleDetail)
                .toList();

        long totalSellValue = items.stream().mapToLong(VehicleDetail::sellPrice).sum();
        List<Double> knownConditions = items.stream()
                .map(VehicleDetail::conditionPercent)
                .filter(Objects::nonNull)
                .toList();
        Double averageConditionPercent = knownConditions.isEmpty()
                ? null
                : knownConditions.stream().mapToDouble(Double::doubleValue).sum() / knownConditions.size();

        return new VehiclesResponse(items.size(), totalSellValue, averageConditionPercent, items);
    }

    private static VehicleDetail toVehicleDetail(VehicleSnapshot vehicle) {
        return new VehicleDetail(vehicle.getName(), vehicle.getCategory(), vehicle.getHorsepowerHp(),
                vehicle.getOperatingHours(), vehicle.getConditionPercent(), vehicle.getOwnershipStatus(),
                vehicle.getSellPrice());
    }
}
