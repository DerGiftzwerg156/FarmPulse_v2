export interface FinanceHistoryPoint {
  recordedAt: string;
  gameDay: number;
  money: number;
}

export interface FinanceResponse {
  balance: number;
  balanceDeltaInPeriod: number;
  incomeInPeriod: number;
  expenseInPeriod: number;
  history: FinanceHistoryPoint[];
}
