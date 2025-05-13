
export  interface RouteParams {
  username?: string;
  userId?: number;
  newLogin?: boolean;
}

export interface HealthData {
  userId: number;
  username: string;
  date: string;
  steps: number;
  heartRate: number;
  sleepHours: number;
  waterAmount: number;
}

export interface RouterParams {
  username: string;
  userId: string;
  steps: string;
  heartRate: string;
  sleepHours: string;
  waterAmount: string;
  date: string;
}

export interface MetadataParams {
  healthData?: string;
}

export interface ChartDataItem {
  label: string;
  value: number;
}

export interface StepTimeInput {
  time: string;
  steps: number;
}