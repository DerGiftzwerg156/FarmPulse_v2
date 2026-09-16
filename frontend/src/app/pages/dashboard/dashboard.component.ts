import { Component, computed, inject } from '@angular/core';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { toSignal } from '@angular/core/rxjs-interop';
import {
  LucideActivity,
  LucideClock,
  LucideLayoutDashboard,
  LucideMail,
  LucideRefreshCw,
  LucideServer,
  LucideSettings,
  LucideSprout,
  LucideTractor,
  LucideTriangleAlert,
  LucideWallet,
  LucideWarehouse,
} from '@lucide/angular';
import { DashboardService } from '../../core/services/dashboard.service';
import { HeroStatComponent } from '../../shared/components/hero-stat/hero-stat.component';
import { SparklineComponent } from '../../shared/components/sparkline/sparkline.component';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [
    CurrencyPipe,
    DecimalPipe,
    HeroStatComponent,
    SparklineComponent,
    LucideActivity,
    LucideClock,
    LucideLayoutDashboard,
    LucideMail,
    LucideRefreshCw,
    LucideServer,
    LucideSettings,
    LucideSprout,
    LucideTractor,
    LucideTriangleAlert,
    LucideWallet,
    LucideWarehouse,
  ],
  templateUrl: './dashboard.component.html',
})
export class DashboardComponent {
  private readonly dashboardService = inject(DashboardService);

  protected readonly dashboard = toSignal(this.dashboardService.dashboard$, { initialValue: null });
  protected readonly history = toSignal(this.dashboardService.moneyHistory$, { initialValue: [] });

  protected readonly moneyValues = computed(() => this.history().map((point) => point.money));

  protected readonly gameTimeLabel = computed(() => {
    const time = this.dashboard()?.gameTime;
    if (!time) {
      return '—';
    }
    const day = String(time.day).padStart(2, '0');
    const hour = String(time.hour).padStart(2, '0');
    const minute = String(time.minute).padStart(2, '0');
    return `Jahr ${time.year} · Monat ${time.month}, Tag ${day} · ${hour}:${minute}`;
  });

  protected readonly storageFillPercent = computed(() => {
    const storages = this.dashboard()?.storages ?? [];
    if (storages.length === 0) {
      return null;
    }
    const totalCapacity = storages.reduce((sum, s) => sum + s.capacity, 0);
    const totalAmount = storages.reduce((sum, s) => sum + s.amount, 0);
    if (totalCapacity === 0) {
      return 0;
    }
    return Math.round((totalAmount / totalCapacity) * 100);
  });

  refresh(): void {
    this.dashboardService.refreshNow();
  }
}
