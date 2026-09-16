export interface FieldDetail {
  fieldId: number;
  sizeHa: number;
  price: number;
  fruitType: string | null;
  growthState: number | null;
  estimatedYieldLiters: number | null;
}

export interface FieldsResponse {
  count: number;
  totalAreaHa: number;
  totalValue: number;
  totalEstimatedYieldLiters: number;
  items: FieldDetail[];
}
