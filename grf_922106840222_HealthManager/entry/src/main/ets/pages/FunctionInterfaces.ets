// FunctionInterfaces.ets

// 定义函数接口类

// 刷新数据的函数接口
@Observed
export class RefreshDataFunc {
  refreshData!: () => Promise<void>;
}

@Observed
// 分享健康数据的函数接口
export class ShareHealthDataFunc {
  shareHealthData!: () => Promise<void>;
}

@Observed
// 更新步数图表的函数接口
export class UpdateStepChartFunc {
  updateStepChartData!: () => Promise<void>;
}

@Observed
// 心率输入相关的函数接口
export class HeartRateInputFunc {
  addHeartRateInputRow!: () => void;
  removeHeartRateInputRow!: (index: number) => void;
  saveMultiHeartRates!: () => Promise<void>;
}

@Observed
// 饮水量输入相关的函数接口
export class WaterInputFunc {
  addWaterInputRow!: () => void;
  removeWaterInputRow!: (index: number) => void;
  saveMultiWaterRecords!: () => Promise<void>;
}