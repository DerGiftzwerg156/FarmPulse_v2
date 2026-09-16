package de.farmpulse.backend.dashboard;

import de.farmpulse.backend.dashboard.dto.DashboardResponse;
import de.farmpulse.backend.dashboard.dto.ErrorResponse;
import de.farmpulse.backend.dashboard.dto.HistoryPoint;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-Schnittstelle fuer das Dashboard (Landingpage nach dem Savegame-Start,
 * siehe {@code de.farmpulse.backend.savegame.SavegameController}): aktueller
 * Zustand der Farm sowie der Kontostand-Verlauf fuer die Sparkline.
 */
@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private static final int DEFAULT_HISTORY_LIMIT = 20;

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    @GetMapping
    public DashboardResponse dashboard() {
        return dashboardService.getDashboard();
    }

    @GetMapping("/history")
    public List<HistoryPoint> history(@RequestParam(name = "limit", defaultValue = "" + DEFAULT_HISTORY_LIMIT) int limit) {
        return dashboardService.getMoneyHistory(limit);
    }

    @ExceptionHandler(NoActiveFarmException.class)
    public ResponseEntity<ErrorResponse> handleNoActiveFarm(NoActiveFarmException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(new ErrorResponse(exception.getMessage()));
    }
}
