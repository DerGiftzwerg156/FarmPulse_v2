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
  currentPricePer1000L: number | null;
  bestPricePer1000L: number | null;
  bestPricePeriod: number | null;
  bestPricePeriodLabel: string | null;
}

export type WeatherType =
  | 'SUN'
  | 'PARTIALLY_CLOUDY'
  | 'CLOUDY'
  | 'RAIN'
  | 'SNOW'
  | 'HAIL'
  | 'THUNDER'
  | 'TWISTER'
  | 'UNKNOWN';

export interface WeatherInfo {
  type: WeatherType;
  temperature: number;
}

export type AlertSeverity = 'WARNING';

export interface DashboardAlert {
  severity: AlertSeverity;
  message: string;
}

export interface DashboardResponse {
  farm: FarmInfo;
  gameTime: GameTime;
  weather: WeatherInfo;
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
