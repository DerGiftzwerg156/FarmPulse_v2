import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { DecimalPipe } from '@angular/common';
import { LucideMapPin, LucideSprout } from '@lucide/angular';
import { FieldsService } from '../../core/services/fields.service';
import { FieldDetail, FieldsResponse } from '../../core/models/fields.model';

const EMPTY_FIELDS: FieldsResponse = { count: 0, totalAreaHa: 0, totalValue: 0, totalEstimatedYieldLiters: 0, items: [] };

type FieldStatus = 'FALLOW' | 'SOWN' | 'GROWING' | 'READY';

@Component({
  selector: 'app-fields',
  standalone: true,
  imports: [DecimalPipe, LucideMapPin, LucideSprout],
  templateUrl: './fields.component.html',
})
export class FieldsComponent {
  private readonly fieldsService = inject(FieldsService);

  protected readonly fields = toSignal(this.fieldsService.fields$, { initialValue: EMPTY_FIELDS });

  cropLabel(field: FieldDetail): string {
    return field.fruitType ?? 'Brache';
  }

  /**
   * FS25 liefert keine benannten Wachstumsphasen ueber die Bridge-API (siehe
   * MOCK_DASHBOARD_DATENLUECKEN.md) - Status/Phase werden daher naeherungsweise
   * aus dem Fortschrittswert (growthState, 0..1) abgeleitet.
   */
  status(field: FieldDetail): FieldStatus {
    if (!field.fruitType || field.growthState === null) {
      return 'FALLOW';
    }
    if (field.growthState >= 1) {
      return 'READY';
    }
    if (field.growthState > 0) {
      return 'GROWING';
    }
    return 'SOWN';
  }

  statusLabel(field: FieldDetail): string {
    switch (this.status(field)) {
      case 'READY':
        return 'Erntereif';
      case 'GROWING':
        return 'Wachstum';
      case 'SOWN':
        return 'Gesät';
      default:
        return 'Unbewirtschaftet';
    }
  }

  phaseLabel(field: FieldDetail): string {
    if (!field.fruitType || field.growthState === null) {
      return '—';
    }
    if (field.growthState >= 1) {
      return 'Erntereif';
    }
    if (field.growthState >= 0.5) {
      return 'Fortgeschritten';
    }
    if (field.growthState > 0) {
      return 'Frühes Wachstum';
    }
    return 'Gesät';
  }

  growthPercent(field: FieldDetail): number {
    return Math.round((field.growthState ?? 0) * 100);
  }
}
