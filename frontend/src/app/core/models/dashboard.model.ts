export interface FarmInfo {
  id: number;
  name: string | null;
  playerName: string | null;
}

export interface GameTime {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  daysPerMonth: number;
}

export interface FieldItem {
  fieldId: number;
  sizeHa: number;
  price: number;
}

export interface FieldsSummary {
  count: number;
  totalAreaHa: number;
  totalValue: number;
  items: FieldItem[];
}

export interface StorageItem {
  fillType: string;
  amount: number;
  capacity: number;
  fillPercentage: number;
}

export type AlertSeverity = 'WARNING';

export interface DashboardAlert {
  severity: AlertSeverity;
  message: string;
}

export interface DashboardResponse {
  farm: FarmInfo;
  gameTime: GameTime;
  money: number;
  fleetValue: number;
  fields: FieldsSummary;
  storages: StorageItem[];
  alerts: DashboardAlert[];
}

export interface HistoryPoint {
  recordedAt: string;
  gameTime: GameTime;
  money: number;
}
