import { Component, computed, inject } from '@angular/core';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { toSignal } from '@angular/core/rxjs-interop';
import { LucideTrendingUp, LucideWarehouse } from '@lucide/angular';
import { DashboardService } from '../../core/services/dashboard.service';
import { StorageItem } from '../../core/models/dashboard.model';

const NEARLY_FULL_THRESHOLD_PERCENT = 90;

@Component({
  selector: 'app-storage',
  standalone: true,
  imports: [CurrencyPipe, DecimalPipe, LucideTrendingUp, LucideWarehouse],
  templateUrl: './storage.component.html',
})
export class StorageComponent {
  private readonly dashboardService = inject(DashboardService);

  protected readonly dashboard = toSignal(this.dashboardService.dashboard$, { initialValue: null });
  protected readonly storages = computed(() => this.dashboard()?.storages ?? []);
  protected readonly nearlyFullCount = computed(
    () => this.storages().filter((storage) => storage.fillPercentage >= NEARLY_FULL_THRESHOLD_PERCENT).length,
  );

  isNearlyFull(fillPercentage: number): boolean {
    return fillPercentage >= NEARLY_FULL_THRESHOLD_PERCENT;
  }

  storageValue(storage: StorageItem): number | null {
    if (storage.currentPricePer1000L === null) {
      return null;
    }
    return (storage.amount * storage.currentPricePer1000L) / 1000;
  }
}
