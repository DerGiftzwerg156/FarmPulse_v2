import { Component, computed, inject } from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { toSignal } from '@angular/core/rxjs-interop';
import { LucideWarehouse } from '@lucide/angular';
import { DashboardService } from '../../core/services/dashboard.service';

const NEARLY_FULL_THRESHOLD_PERCENT = 90;

@Component({
  selector: 'app-storage',
  standalone: true,
  imports: [DecimalPipe, LucideWarehouse],
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
}
