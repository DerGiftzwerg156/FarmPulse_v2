import { Component, computed, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { CurrencyPipe } from '@angular/common';
import { LucideTrendingDown, LucideTrendingUp } from '@lucide/angular';
import { FinanceService } from '../../core/services/finance.service';
import { SparklineComponent } from '../../shared/components/sparkline/sparkline.component';
import { FinanceResponse } from '../../core/models/finance.model';

const EMPTY_FINANCE: FinanceResponse = { balance: 0, balanceDeltaInPeriod: 0, incomeInPeriod: 0, expenseInPeriod: 0, history: [] };

@Component({
  selector: 'app-finance',
  standalone: true,
  imports: [CurrencyPipe, SparklineComponent, LucideTrendingDown, LucideTrendingUp],
  templateUrl: './finance.component.html',
})
export class FinanceComponent {
  private readonly financeService = inject(FinanceService);

  protected readonly finance = toSignal(this.financeService.finance$, { initialValue: EMPTY_FINANCE });
  protected readonly balanceValues = computed(() => this.finance().history.map((point) => point.money));
}
