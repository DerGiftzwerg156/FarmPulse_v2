package de.farmpulse.backend.fields;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.FieldSnapshot;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.fields.dto.FieldDetail;
import de.farmpulse.backend.fields.dto.FieldsResponse;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import java.util.List;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Liest die der aktiven Farm gehoerenden Felder samt Anbaudaten (siehe
 * {@link FieldSnapshot}) fuer die Felder-Seite im Frontend (Vorlage
 * MockDashboard/Fields.html).
 */
@Service
public class FieldsService {

    private final FarmRepository farmRepository;
    private final WorldSnapshotRepository worldSnapshotRepository;

    public FieldsService(FarmRepository farmRepository, WorldSnapshotRepository worldSnapshotRepository) {
        this.farmRepository = farmRepository;
        this.worldSnapshotRepository = worldSnapshotRepository;
    }

    @Transactional(readOnly = true)
    public FieldsResponse getFields() {
        Farm farm = farmRepository.findTopByOrderByUpdatedAtDesc()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Es liegt noch keine Farm vor."));

        Optional<WorldSnapshot> world = worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(farm.getId());
        if (world.isEmpty()) {
            return new FieldsResponse(0, 0.0, 0L, 0.0, List.of());
        }

        List<FieldDetail> items = world.get().getFields().stream()
                .filter(field -> field.getOwnerFarmId() == farm.getId())
                .map(FieldsService::toFieldDetail)
                .toList();

        double totalAreaHa = items.stream().mapToDouble(FieldDetail::sizeHa).sum();
        long totalValue = items.stream().mapToLong(FieldDetail::price).sum();
        double totalEstimatedYieldLiters = items.stream()
                .map(FieldDetail::estimatedYieldLiters)
                .filter(java.util.Objects::nonNull)
                .mapToDouble(Double::doubleValue)
                .sum();

        return new FieldsResponse(items.size(), totalAreaHa, totalValue, totalEstimatedYieldLiters, items);
    }

    private static FieldDetail toFieldDetail(FieldSnapshot field) {
        return new FieldDetail(field.getFieldId(), field.getSizeHa(), field.getPrice(), field.getFruitType(),
                field.getGrowthState(), field.getEstimatedYieldLiters());
    }
}
