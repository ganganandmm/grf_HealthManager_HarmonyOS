// 步数记录模型
export class StepRecord {
  id?: number;
  userId: number;
  date: string;
  steps: number;

  constructor(userId: number, date: string, steps: number, id?: number) {
    this.userId = userId;
    this.date = date;
    this.steps = steps;
    this.id = id;

  }
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