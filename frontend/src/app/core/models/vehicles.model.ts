export interface VehicleDetail {
  name: string;
  horsepowerHp: number | null;
  operatingHours: number | null;
  conditionPercent: number | null;
  sellPrice: number;
}

export interface VehiclesResponse {
  count: number;
  totalSellValue: number;
  averageConditionPercent: number | null;
  items: VehicleDetail[];
}
