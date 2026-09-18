import { Component, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { LucideCoins, LucideSearch, LucideTimer, LucideTractor, LucideWrench } from '@lucide/angular';
import { VehiclesService } from '../../core/services/vehicles.service';
import { VehicleOwnershipStatus, VehiclesResponse } from '../../core/models/vehicles.model';
import { vehicleCondition, vehicleConditionLabel, vehicleConditionPercentRounded, vehicleOwnershipLabel } from '../../core/utils/vehicle-status.util';

const EMPTY_VEHICLES: VehiclesResponse = { count: 0, totalSellValue: 0, averageConditionPercent: null, items: [] };

interface OwnershipFilter {
  label: string;
  value: VehicleOwnershipStatus | null;
}

const OWNERSHIP_FILTERS: OwnershipFilter[] = [
  { label: 'Alle', value: null },
  { label: 'Gekauft', value: 'OWNED' },
  { label: 'Geleast', value: 'LEASED' },
  { label: 'Vertrag', value: 'MISSION' },
];

@Component({
  selector: 'app-vehicles',
  standalone: true,
  imports: [CurrencyPipe, DecimalPipe, FormsModule, LucideCoins, LucideSearch, LucideTimer, LucideTractor, LucideWrench],
  templateUrl: './vehicles.component.html',
})
export class VehiclesComponent {
  private readonly vehiclesService = inject(VehiclesService);

  protected readonly vehicles = toSignal(this.vehiclesService.vehicles$, { initialValue: EMPTY_VEHICLES });

  protected readonly ownershipFilters = OWNERSHIP_FILTERS;

  protected readonly search = signal('');
  protected readonly activeCategory = signal<string | null>(null);
  protected readonly activeOwnership = signal<VehicleOwnershipStatus | null>(null);

  /** Kategorien werden aus den tatsaechlich vorhandenen Fahrzeugen abgeleitet, statt fest verdrahtet zu werden - FS25-Mods koennen beliebige Kategorien mitbringen. */
  protected readonly availableCategories = computed(() => {
    const categories = new Set(this.vehicles().items.map((v) => v.category));
    return Array.from(categories).sort((a, b) => a.localeCompare(b, 'de'));
  });

  protected readonly filteredVehicles = computed(() => {
    const search = this.search().trim().toLowerCase();
    const category = this.activeCategory();
    const ownership = this.activeOwnership();

    return this.vehicles().items.filter((vehicle) => {
      if (category && vehicle.category !== category) {
        return false;
      }
      if (ownership && vehicle.ownershipStatus !== ownership) {
        return false;
      }
      if (search && !vehicle.name.toLowerCase().includes(search)) {
        return false;
      }
      return true;
    });
  });

  protected readonly condition = vehicleCondition;
  protected readonly conditionLabel = vehicleConditionLabel;
  protected readonly conditionPercent = vehicleConditionPercentRounded;
  protected readonly ownershipLabel = vehicleOwnershipLabel;

  selectCategory(value: string | null): void {
    this.activeCategory.set(value);
  }

  selectOwnership(value: VehicleOwnershipStatus | null): void {
    this.activeOwnership.set(value);
  }
}
