import { VehicleOwnershipStatus } from '../models/vehicles.model';

export type VehicleCondition = 'GOOD' | 'FAIR' | 'POOR' | 'UNKNOWN';

interface VehicleConditionInfo {
  conditionPercent: number | null;
}

/**
 * FS25 liefert den Fahrzeugzustand nur als Rohwert (0..100%, siehe
 * Bridge/README.md) - Stufen/Label werden daher naeherungsweise im Frontend
 * aus dem Prozentwert abgeleitet, analog zu field-status.util.ts.
 */
export function vehicleCondition(vehicle: VehicleConditionInfo): VehicleCondition {
  if (vehicle.conditionPercent === null) {
    return 'UNKNOWN';
  }
  if (vehicle.conditionPercent >= 80) {
    return 'GOOD';
  }
  if (vehicle.conditionPercent >= 50) {
    return 'FAIR';
  }
  return 'POOR';
}

export function vehicleConditionLabel(vehicle: VehicleConditionInfo): string {
  switch (vehicleCondition(vehicle)) {
    case 'GOOD':
      return 'Gut';
    case 'FAIR':
      return 'Mittel';
    case 'POOR':
      return 'Wartung nötig';
    default:
      return 'Unbekannt';
  }
}

export function vehicleConditionPercentRounded(vehicle: VehicleConditionInfo): number {
  return Math.round(vehicle.conditionPercent ?? 0);
}

/**
 * Eigentumsstatus-Label, siehe Bridge/README.md fuer die Herkunft der vier
 * bekannten Werte (VehiclePropertyState.OWNED/.LEASED/.MISSION/.SHOP_CONFIG).
 * SHOP_CONFIG sollte in der Praxis nicht vorkommen (nur Shop-Vorschauobjekte),
 * wird hier dennoch beschriftet statt als UNKNOWN zu erscheinen.
 */
export function vehicleOwnershipLabel(status: VehicleOwnershipStatus): string {
  switch (status) {
    case 'OWNED':
      return 'Gekauft';
    case 'LEASED':
      return 'Geleast';
    case 'MISSION':
      return 'Vertrag';
    case 'SHOP_CONFIG':
      return 'Shop';
    default:
      return 'Unbekannt';
  }
}
