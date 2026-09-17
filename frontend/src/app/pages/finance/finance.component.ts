import { Component, computed, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { LucideHeart, LucideStar, LucideTarget, LucideTrendingDown, LucideTrendingUp } from '@lucide/angular';
import { FinanceService } from '../../core/services/finance.service';
import { ProgressionService } from '../../core/services/progression.service';
import { SparklineComponent } from '../../shared/components/sparkline/sparkline.component';
import { FinanceResponse } from '../../core/models/finance.model';
import { ProgressionResponse } from '../../core/models/progression.model';

const EMPTY_FINANCE: FinanceResponse = { balance: 0, balanceDeltaInPeriod: 0, incomeInPeriod: 0, expenseInPeriod: 0, history: [] };
const EMPTY_PROGRESSION: ProgressionResponse = { reputationPercent: 0, employeeSatisfactionPercent: 0, seasonGoal: null };

@Component({
  selector: 'app-finance',
  standalone: true,
  imports: [CurrencyPipe, DecimalPipe, SparklineComponent, LucideHeart, LucideStar, LucideTarget, LucideTrendingDown, LucideTrendingUp],
  templateUrl: './finance.component.html',
})
export class FinanceComponent {
  private readonly financeService = inject(FinanceService);
  private readonly progressionService = inject(ProgressionService);

  protected readonly finance = toSignal(this.financeService.finance$, { initialValue: EMPTY_FINANCE });
  protected readonly balanceValues = computed(() => this.finance().history.map((point) => point.money));

  protected readonly progression = toSignal(this.progressionService.progression$, { initialValue: EMPTY_PROGRESSION });
  protected readonly seasonGoal = computed(() => this.progression().seasonGoal);
  protected readonly seasonGoalPercent = computed(() => {
    const goal = this.seasonGoal();
    if (!goal || goal.targetValue <= 0) {
      return 0;
    }
    return Math.min(100, Math.max(0, Math.round((goal.currentValue / goal.targetValue) * 100)));
  });
}
