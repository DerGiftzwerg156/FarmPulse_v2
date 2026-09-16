package de.farmpulse.backend.dashboard;

import de.farmpulse.backend.dashboard.dto.Alert;
import de.farmpulse.backend.dashboard.dto.DashboardResponse;
import de.farmpulse.backend.dashboard.dto.FarmInfo;
import de.farmpulse.backend.dashboard.dto.FieldItem;
import de.farmpulse.backend.dashboard.dto.FieldsSummary;
import de.farmpulse.backend.dashboard.dto.GameTime;
import de.farmpulse.backend.dashboard.dto.HistoryPoint;
import de.farmpulse.backend.dashboard.dto.StorageItem;
import de.farmpulse.backend.dashboard.dto.WeatherInfo;
import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.FieldSnapshot;
import de.farmpulse.backend.domain.StorageSnapshot;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.domain.WorldSnapshot;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import de.farmpulse.backend.repository.WorldSnapshotRepository;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Aggregiert die zuletzt gepollten Snapshots (Farm, Telemetrie, Welt) zu
 * einem Gesamtbild fuer das Dashboard. Liefert ausschliesslich Werte, die
 * tatsaechlich aus der Bridge stammen - siehe
 * backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md fuer Mock-Datenpunkte, die
 * mangels Bridge-Datenquelle (noch) nicht abgebildet werden.
 */
@Service
public class DashboardService {

    private static final int MAX_HISTORY_LIMIT = 200;

    private final FarmRepository farmRepository;
    private final TelemetrySnapshotRepository telemetrySnapshotRepository;
    private final WorldSnapshotRepository worldSnapshotRepository;

    public DashboardService(FarmRepository farmRepository, TelemetrySnapshotRepository telemetrySnapshotRepository,
            WorldSnapshotRepository worldSnapshotRepository) {
        this.farmRepository = farmRepository;
        this.telemetrySnapshotRepository = telemetrySnapshotRepository;
        this.worldSnapshotRepository = worldSnapshotRepository;
    }

    @Transactional(readOnly = true)
    public DashboardResponse getDashboard() {
        Farm farm = farmRepository.findTopByOrderByUpdatedAtDesc()
                .orElseThrow(() -> new NoActiveFarmException("Es liegt noch keine Farm vor."));

        TelemetrySnapshot telemetry = telemetrySnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(farm.getId())
                .orElseThrow(() -> new NoActiveFarmException("Es liegt noch keine Telemetrie vor."));
        Optional<WorldSnapshot> world = worldSnapshotRepository.findTopByFarmIdOrderByRecordedAtDesc(farm.getId());

        FarmInfo farmInfo = new FarmInfo(farm.getId(), farm.getName(), farm.getPlayerName());
        GameTime gameTime = toGameTime(telemetry);
        WeatherInfo weather = new WeatherInfo(telemetry.getWeatherType(), telemetry.getTemperature());
        long fleetValue = world.map(WorldSnapshot::getFleetValue).orElse(0L);
        FieldsSummary fields = toFieldsSummary(world.orElse(null), farm.getId());
        List<StorageItem> storages = world.map(this::toStorageItems).orElseGet(List::of);
        List<Alert> alerts = deriveAlerts(telemetry.getMoney());

        return new DashboardResponse(farmInfo, gameTime, weather, telemetry.getMoney(), fleetValue, fields, storages,
                alerts);
    }

    @Transactional(readOnly = true)
    public List<HistoryPoint> getMoneyHistory(int limit) {
        int boundedLimit = Math.max(1, Math.min(limit, MAX_HISTORY_LIMIT));
        Farm farm = farmRepository.findTopByOrderByUpdatedAtDesc()
                .orElseThrow(() -> new NoActiveFarmException("Es liegt noch keine Farm vor."));

        List<TelemetrySnapshot> newestFirst = telemetrySnapshotRepository
                .findByFarmIdOrderByRecordedAtDesc(farm.getId(), PageRequest.of(0, boundedLimit));

        return newestFirst.stream()
                .sorted((a, b) -> a.getRecordedAt().compareTo(b.getRecordedAt()))
                .map(snapshot -> new HistoryPoint(snapshot.getRecordedAt(), toGameTime(snapshot), snapshot.getMoney()))
                .toList();
    }

    private GameTime toGameTime(TelemetrySnapshot snapshot) {
        return new GameTime(snapshot.getGameYear(), snapshot.getGameMonth(), snapshot.getGameDay(),
                snapshot.getGameHour(), snapshot.getGameMinute(), snapshot.getDaysPerMonth());
    }

    private FieldsSummary toFieldsSummary(WorldSnapshot world, long farmId) {
        if (world == null) {
            return new FieldsSummary(0, 0.0, 0L, List.of());
        }
        List<FieldItem> ownFields = world.getFields().stream()
                .filter(field -> field.getOwnerFarmId() == farmId)
                .map(field -> new FieldItem(field.getFieldId(), field.getSizeHa(), field.getPrice()))
                .toList();
        double totalAreaHa = ownFields.stream().mapToDouble(FieldItem::sizeHa).sum();
        long totalValue = ownFields.stream().mapToLong(FieldItem::price).sum();
        return new FieldsSummary(ownFields.size(), totalAreaHa, totalValue, ownFields);
    }

    private List<StorageItem> toStorageItems(WorldSnapshot world) {
        return world.getStorages().stream()
                .map(this::toStorageItem)
                .toList();
    }

    private StorageItem toStorageItem(StorageSnapshot storage) {
        double fillPercentage = storage.getCapacity() > 0
                ? (storage.getAmount() * 100.0) / storage.getCapacity()
                : 0.0;
        return new StorageItem(storage.getFillType(), storage.getAmount(), storage.getCapacity(), fillPercentage);
    }

    private List<Alert> deriveAlerts(long money) {
        List<Alert> alerts = new java.util.ArrayList<>();
        if (money < 0) {
            alerts.add(new Alert(Alert.Severity.WARNING, "Der Kontostand ist negativ."));
        }
        return alerts;
    }
}
