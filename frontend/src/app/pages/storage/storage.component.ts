import { Component, computed, inject, signal } from '@angular/core';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { toSignal } from '@angular/core/rxjs-interop';
import { LucideSearch, LucideTrendingUp, LucideWarehouse } from '@lucide/angular';
import { DashboardService } from '../../core/services/dashboard.service';
import { StorageItem } from '../../core/models/dashboard.model';

const NEARLY_FULL_THRESHOLD_PERCENT = 90;

@Component({
  selector: 'app-storage',
  standalone: true,
  imports: [CurrencyPipe, DecimalPipe, FormsModule, LucideSearch, LucideTrendingUp, LucideWarehouse],
  templateUrl: './storage.component.html',
})
export class StorageComponent {
  private readonly dashboardService = inject(DashboardService);

  protected readonly dashboard = toSignal(this.dashboardService.dashboard$, { initialValue: null });
  protected readonly storages = computed(() => this.dashboard()?.storages ?? []);
  protected readonly nearlyFullCount = computed(
    () => this.storages().filter((storage) => storage.fillPercentage >= NEARLY_FULL_THRESHOLD_PERCENT).length,
  );

  protected readonly search = signal('');
  /** Standardmaessig nur befuellte Lager anzeigen - die world.json liefert auch alle leeren fillTypes, was bei vielen Mods die Uebersicht sprengt. */
  protected readonly onlyFilled = signal(true);

  protected readonly filteredStorages = computed(() => {
    const search = this.search().trim().toLowerCase();
    const onlyFilled = this.onlyFilled();

    return this.storages().filter((storage) => {
      if (onlyFilled && storage.amount <= 0) {
        return false;
      }
      if (search && !storage.fillType.toLowerCase().includes(search)) {
        return false;
      }
      return true;
    });
  });

  isNearlyFull(fillPercentage: number): boolean {
    return fillPercentage >= NEARLY_FULL_THRESHOLD_PERCENT;
  }

  toggleOnlyFilled(value: boolean): void {
    this.onlyFilled.set(value);
  }

  storageValue(storage: StorageItem): number | null {
    if (storage.currentPricePer1000L === null) {
      return null;
    }
    return (storage.amount * storage.currentPricePer1000L) / 1000;
  }
}
