package de.farmpulse.backend.finance;

import de.farmpulse.backend.domain.Farm;
import de.farmpulse.backend.domain.TelemetrySnapshot;
import de.farmpulse.backend.finance.dto.FinanceHistoryPoint;
import de.farmpulse.backend.finance.dto.FinanceResponse;
import de.farmpulse.backend.repository.FarmRepository;
import de.farmpulse.backend.repository.TelemetrySnapshotRepository;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

/**
 * Berechnet Kontostand-Verlauf sowie Einnahmen/Ausgaben im betrachteten
 * Zeitraum aus den periodisch aufgezeichneten {@link TelemetrySnapshot}s.
 * Die Bridge liefert keine einzelnen Transaktionen, daher werden
 * Einnahmen/Ausgaben aus den Kontostand-Deltas zwischen aufeinander
 * folgenden Snapshots naeherungsweise abgeleitet (siehe
 * backend/docs/MOCK_DASHBOARD_DATENLUECKEN.md).
 */
@Service
public class FinanceService {

    private static final int MAX_HISTORY_LIMIT = 200;

    private final FarmRepository farmRepository;
    private final TelemetrySnapshotRepository telemetrySnapshotRepository;

    public FinanceService(FarmRepository farmRepository, TelemetrySnapshotRepository telemetrySnapshotRepository) {
        this.farmRepository = farmRepository;
        this.telemetrySnapshotRepository = telemetrySnapshotRepository;
    }

    @Transactional(readOnly = true)
    public FinanceResponse getFinance(int limit) {
        int boundedLimit = Math.max(1, Math.min(limit, MAX_HISTORY_LIMIT));
        Farm farm = farmRepository.findTopByOrderByUpdatedAtDesc()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Es liegt noch keine Farm vor."));

        List<TelemetrySnapshot> oldestFirst = telemetrySnapshotRepository
                .findByFarmIdOrderByRecordedAtDesc(farm.getId(), PageRequest.of(0, boundedLimit)).stream()
                .sorted((a, b) -> a.getRecordedAt().compareTo(b.getRecordedAt()))
                .toList();

        if (oldestFirst.isEmpty()) {
            return new FinanceResponse(0L, 0L, 0L, 0L, List.of());
        }

        long balance = oldestFirst.get(oldestFirst.size() - 1).getMoney();
        long balanceDelta = balance - oldestFirst.get(0).getMoney();

        long income = 0L;
        long expense = 0L;
        for (int i = 1; i < oldestFirst.size(); i++) {
            long delta = oldestFirst.get(i).getMoney() - oldestFirst.get(i - 1).getMoney();
            if (delta > 0) {
                income += delta;
            } else if (delta < 0) {
                expense += -delta;
            }
        }

        List<FinanceHistoryPoint> history = oldestFirst.stream()
                .map(snapshot -> new FinanceHistoryPoint(snapshot.getRecordedAt(), snapshot.getGameDay(), snapshot.getMoney()))
                .toList();

        return new FinanceResponse(balance, balanceDelta, income, expense, history);
    }
}
