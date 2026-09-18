export type VehicleOwnershipStatus = 'OWNED' | 'LEASED' | 'MISSION' | 'SHOP_CONFIG' | 'UNKNOWN';

export interface VehicleDetail {
  name: string;
  category: string;
  horsepowerHp: number | null;
  operatingHours: number | null;
  conditionPercent: number | null;
  ownershipStatus: VehicleOwnershipStatus;
  sellPrice: number;
}

export interface VehiclesResponse {
  count: number;
  totalSellValue: number;
  averageConditionPercent: number | null;
  items: VehicleDetail[];
}
