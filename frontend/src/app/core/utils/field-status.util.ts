export type FieldStatus = 'FALLOW' | 'SOWN' | 'GROWING' | 'READY';

interface FieldCropInfo {
  fruitType: string | null;
  growthState: number | null;
}

/**
 * FS25 liefert keine benannten Wachstumsphasen ueber die Bridge-API (siehe
 * MOCK_DASHBOARD_DATENLUECKEN.md) - Status/Phase werden daher naeherungsweise
 * aus dem Fortschrittswert (growthState, 0..1) abgeleitet. Gemeinsam genutzt
 * von der Felder-Seite und der Felder-Vorschau im Dashboard.
 */
export function fieldStatus(field: FieldCropInfo): FieldStatus {
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

export function fieldStatusLabel(field: FieldCropInfo): string {
  switch (fieldStatus(field)) {
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

export function fieldPhaseLabel(field: FieldCropInfo): string {
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

export function fieldCropLabel(field: FieldCropInfo): string {
  return field.fruitType ?? 'Brache';
}

export function fieldGrowthPercent(field: FieldCropInfo): number {
  return Math.round((field.growthState ?? 0) * 100);
}
