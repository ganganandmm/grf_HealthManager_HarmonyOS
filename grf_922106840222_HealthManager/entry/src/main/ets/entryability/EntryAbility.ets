import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { hilog } from '@kit.PerformanceAnalysisKit';
import Want from '@ohos.app.ability.Want';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { JSON } from '@kit.ArkTS';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from '../common/HealthDataModel';

const TAG: string = 'MainAbility';

// Define an interface for the health data structure
interface HealthData {
  id: number;
  date: string;
  steps?: number;
  heartRate?: number;
  sleepHours?: number;
  waterAmount?: number;
}

export default class EntryAbility extends UIAbility {
  private dbHelper: DatabaseHelper | null = null;
  private sharedData: HealthData | null = null;

  onCreate(want: Want) {
    hilog.info(0x0000, TAG, `EntryAbility onCreate, want: ${JSON.stringify(want)}`);

    // 初始化数据库
    this.dbHelper = new DatabaseHelper(this.context);
    this.dbHelper.initDatabase().then(success => {
      if (success) {
        hilog.info(0x0000, TAG, 'Database initialized successfully in EntryAbility');
      } else {
        hilog.error(0x0000, TAG, 'Failed to initialize database in EntryAbility');
      }
    });

    // 处理接收到的数据
    this.processReceivedData(want);
  }

  onDestroy() {
    hilog.info(0x0000, TAG, 'EntryAbility onDestroy');

    // 关闭数据库
    if (this.dbHelper) {
      this.dbHelper.closeDatabase();
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(0x0000, TAG, 'EntryAbility onWindowStageCreate');

    // 加载主页面
    windowStage.loadContent('pages/Login', (err) => {
      if (err.code) {
        hilog.error(0x0000, TAG, `Failed to load content. Error: ${JSON.stringify(err)}`);
        return;
      }
      hilog.info(0x0000, TAG, 'Content loaded successfully');
    });
  }

  onWindowStageDestroy() {
    hilog.info(0x0000, TAG, 'EntryAbility onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(0x0000, TAG, 'EntryAbility onForeground');
  }

  onBackground() {
    hilog.info(0x0000, TAG, 'EntryAbility onBackground');
  }

  // 处理通过Want接收到的数据
  processReceivedData(want: Want) {
    if (want && want.action === 'ohos.action.want.sendData' && want.parameters) {
      try {
        // 从want中提取健康数据
        const healthDataString = want.parameters.healthData as string;
        if (healthDataString) {
          this.sharedData = JSON.parse(healthDataString) as HealthData;
          hilog.info(0x0000, TAG, `Received health data: ${JSON.stringify(this.sharedData)}`);

          // 保存接收到的数据到关系型数据库
          this.saveReceivedData();
        }
      } catch (error) {
        hilog.error(0x0000, TAG, `Error processing received data: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  // 保存接收到的数据到关系型数据库
  async saveReceivedData() {
    if (!this.sharedData || !this.dbHelper) {
      return;
    }

    try {
      // 不使用解构赋值，而是直接访问属性
      const id = this.sharedData.id;
      const date = this.sharedData.date;
      const steps = this.sharedData.steps;
      const heartRate = this.sharedData.heartRate;
      const sleepHours = this.sharedData.sleepHours;
      const waterAmount = this.sharedData.waterAmount;

      // 验证必要的字段
      if (!id || !date) {
        hilog.error(0x0000, TAG, 'Invalid shared data: missing required fields');
        return;
      }

      // 保存步数记录
      if (steps !== undefined) {
        const stepRecord = new StepRecord(id, date, steps);
        await this.dbHelper.insertStepRecord(stepRecord);
        hilog.info(0x0000, TAG, `Step record saved: userId=${id}, date=${date}, steps=${steps}`);
      }

      // 保存心率记录
      if (heartRate !== undefined) {
        const time = new Date().toTimeString().split(' ')[0].substring(0, 5);
        const heartRateRecord = new HeartRateRecord(id, date, time, heartRate);
        await this.dbHelper.insertHeartRateRecord(heartRateRecord);
        hilog.info(0x0000, TAG, `Heart rate record saved: userId=${id}, date=${date}, rate=${heartRate}`);
      }

      // 保存睡眠记录
      if (sleepHours !== undefined) {
        const durationMinutes = Math.round(sleepHours * 60); // 转换为分钟
        const sleepRecord = new SleepRecord(id, date, durationMinutes);
        await this.dbHelper.insertSleepRecord(sleepRecord);
        hilog.info(0x0000, TAG, `Sleep record saved: userId=${id}, date=${date}, duration=${sleepHours} hours`);
      }

      // 保存饮水记录
      if (waterAmount !== undefined) {
        const time = new Date().toTimeString().split(' ')[0].substring(0, 5);
        const waterRecord = new WaterRecord(id, date, time, waterAmount);
        await this.dbHelper.insertWaterRecord(waterRecord);
        hilog.info(0x0000, TAG, `Water record saved: userId=${id}, date=${date}, amount=${waterAmount} ml`);
      }

      hilog.info(0x0000, TAG, 'All received health data saved to database successfully');
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to save received data: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}