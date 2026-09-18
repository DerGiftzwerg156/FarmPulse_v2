import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { CurrencyPipe, DecimalPipe } from '@angular/common';
import { LucideCoins, LucideTimer, LucideTractor, LucideWrench } from '@lucide/angular';
import { VehiclesService } from '../../core/services/vehicles.service';
import { VehiclesResponse } from '../../core/models/vehicles.model';
import { vehicleCondition, vehicleConditionLabel, vehicleConditionPercentRounded } from '../../core/utils/vehicle-status.util';

const EMPTY_VEHICLES: VehiclesResponse = { count: 0, totalSellValue: 0, averageConditionPercent: null, items: [] };

@Component({
  selector: 'app-vehicles',
  standalone: true,
  imports: [CurrencyPipe, DecimalPipe, LucideCoins, LucideTimer, LucideTractor, LucideWrench],
  templateUrl: './vehicles.component.html',
})
export class VehiclesComponent {
  private readonly vehiclesService = inject(VehiclesService);

  protected readonly vehicles = toSignal(this.vehiclesService.vehicles$, { initialValue: EMPTY_VEHICLES });

  protected readonly condition = vehicleCondition;
  protected readonly conditionLabel = vehicleConditionLabel;
  protected readonly conditionPercent = vehicleConditionPercentRounded;
}
