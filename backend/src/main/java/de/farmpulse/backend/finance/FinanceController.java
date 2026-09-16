package de.farmpulse.backend.finance;

import de.farmpulse.backend.finance.dto.FinanceResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-Schnittstelle fuer die Finanzen-Seite im Frontend (Vorlage
 * MockDashboard/Finances.html).
 */
@RestController
@RequestMapping("/api/finance")
public class FinanceController {

    private static final int DEFAULT_HISTORY_LIMIT = 20;

    private final FinanceService financeService;

    public FinanceController(FinanceService financeService) {
        this.financeService = financeService;
    }

    @GetMapping
    public FinanceResponse finance(@RequestParam(name = "limit", defaultValue = "" + DEFAULT_HISTORY_LIMIT) int limit) {
        return financeService.getFinance(limit);
    }
}
