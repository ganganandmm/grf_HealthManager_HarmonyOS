export class StepRecord {
  id?: string; // 修改为string类型，保持一致
  userId: number;
  date: string;
  steps: number;

  constructor(userId: number, date: string, steps: number, id?: string) {
    this.userId = userId;
    this.date = date;
    this.steps = steps;
    this.id = id;
  }
}

// 确保StepTimeRecord实现正确
export class StepTimeRecord {
  id?: number;
  stepRecordId: number; // 关联到总步数记录
  time: string;
  steps: number;

  constructor(stepRecordId: number, time: string, steps: number) {
    this.stepRecordId = stepRecordId;
    this.time = time;
    this.steps = steps;
  }
}

// 确保正确定义StepTimeInput接口
export interface StepTimeInput {
  time: string;
  steps: number;
}
// 心率记录模型
export class HeartRateRecord {
  id?: number;
  userId: number;
  date: string;  // 格式：YYYY-MM-DD
  time: string;  // 格式：HH:MM
  rate: number;  // 心率值

  constructor(userId: number, date: string, time: string, rate: number, id?: number) {
    this.userId = userId;
    this.date = date;
    this.time = time;
    this.rate = rate;
    this.id = id;
  }
}

// 睡眠记录模型
export class SleepRecord {
  id?: number;
  userId: number;
  date: string;    // 格式：YYYY-MM-DD
  duration: number; // 睡眠时长（分钟）

  constructor(userId: number, date: string, duration: number, id?: number) {
    this.userId = userId;
    this.date = date;
    this.duration = duration;
    this.id = id;
  }

  // 将分钟转换为小时和分钟的格式
  getDurationText(): string {
    const hours = Math.floor(this.duration / 60);
    const minutes = this.duration % 60;
    return `${hours}小时${minutes}分钟`;
  }
}

// 饮水记录模型
export class WaterRecord {
  id?: number;
  userId: number;
  date: string;   // 格式：YYYY-MM-DD
  time: string;   // 格式：HH:MM
  amount: number; // 饮水量（毫升）

  constructor(userId: number, date: string, time: string, amount: number, id?: number) {
    this.userId = userId;
    this.date = date;
    this.time = time;
    this.amount = amount;
    this.id = id;
  }
}