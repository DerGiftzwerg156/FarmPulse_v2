import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { DecimalPipe } from '@angular/common';
import { LucideMapPin, LucideSprout } from '@lucide/angular';
import { FieldsService } from '../../core/services/fields.service';
import { FieldsResponse } from '../../core/models/fields.model';
import { fieldCropLabel, fieldGrowthPercent, fieldPhaseLabel, fieldStatus, fieldStatusLabel } from '../../core/utils/field-status.util';

const EMPTY_FIELDS: FieldsResponse = { count: 0, totalAreaHa: 0, totalValue: 0, totalEstimatedYieldLiters: 0, items: [] };

@Component({
  selector: 'app-fields',
  standalone: true,
  imports: [DecimalPipe, LucideMapPin, LucideSprout],
  templateUrl: './fields.component.html',
})
export class FieldsComponent {
  private readonly fieldsService = inject(FieldsService);

  protected readonly fields = toSignal(this.fieldsService.fields$, { initialValue: EMPTY_FIELDS });

  protected readonly cropLabel = fieldCropLabel;
  protected readonly status = fieldStatus;
  protected readonly statusLabel = fieldStatusLabel;
  protected readonly phaseLabel = fieldPhaseLabel;
  protected readonly growthPercent = fieldGrowthPercent;
}
