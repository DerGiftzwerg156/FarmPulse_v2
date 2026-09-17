export type SeasonGoalType = 'MONEY_BALANCE' | 'HARVEST_AMOUNT' | 'EMPLOYEE_COUNT' | 'CUSTOM';

export type SeasonGoalStatus = 'ACTIVE' | 'COMPLETED' | 'FAILED';

export interface SeasonGoal {
  type: SeasonGoalType;
  title: string;
  unit: string;
  targetValue: number;
  currentValue: number;
  fillType: string | null;
  deadlineLabel: string | null;
  status: SeasonGoalStatus;
}

export interface ProgressionResponse {
  reputationPercent: number;
  employeeSatisfactionPercent: number;
  seasonGoal: SeasonGoal | null;
}
