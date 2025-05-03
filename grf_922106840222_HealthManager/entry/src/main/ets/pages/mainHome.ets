import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';
import common from '@ohos.app.ability.common';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord, StepTimeRecord } from '../common/HealthDataModel';
import Want from '@ohos.app.ability.Want'
import promptAction from '@ohos.promptAction';
import {HeartRateInputDialog, StepInputDialog, WaterInputDialog} from './Dialog'
import {HealthDataCard,HeartRateRecordItem,WaterRecordItem,DataInputRow,StepTimeRecordItem} from './myComponents'

export const TAG: string = 'mainHome';
@Extend(Text) function titleText() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .margin({ top: 10, bottom: 20 })
}

@Extend(Text) function subtitleText() {
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .margin({ bottom: 10 })
}

@Extend(Text) function labelText() {
  .fontSize(16)
  .fontColor('#666')
}

@Extend(Text) function valueText() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
}

@Extend(Column) function cardContainer() {
  .width('90%')
  .padding(15)
  .borderRadius(8)
  .backgroundColor('#f7f7f7')
  .margin({ bottom: 10 })
}

@Extend(Button) function primaryButton() {
  .width('100%')
  .height(40)
  .backgroundColor('#27AE60')
  .margin({ bottom: 10 })
}

@Extend(Button) function secondaryButton(bgColor: string = '#3498DB') {
  .width('100%')
  .height(40)
  .backgroundColor(bgColor)
  .margin({ bottom: 10 })
}

@Extend(Row) function menuItem() {
  .width('100%')
  .padding(15)
  .backgroundColor('#ffffff')
  .borderRadius(8)
  .margin({ bottom: 10 })
}

// 定义接口
interface RouteParams {
  username?: string;
  userId?: number;
  newLogin?: boolean;
}

interface HealthData {
  userId: number;
  username: string;
  date: string;
  steps: number;
  heartRate: number;
  sleepHours: number;
  waterAmount: number;
}

interface RouterParams {
  username: string;
  userId: string;
  steps: string;
  heartRate: string;
  sleepHours: string;
  waterAmount: string;
  date: string;
}

interface MetadataParams {
  healthData?: string;
}

interface ChartDataItem {
  label: string;
  value: number;
}

interface StepTimeInput {
  time: string;
  steps: number;
}

@Entry
@Component
struct MainHome {
  @State username: string = '';
  @State userId: number = -1;
  @State steps: number = 0;
  @State heartRate: number = 0;
  @State sleepHours: number = 0;
  @State waterAmount: number = 0;
  @State waterRecords: WaterRecord[] = [];
  @State currentDate: string = new Date().toISOString().split('T')[0];
  @State receivedHealthData: string = '';
  @State currentIndex: number = 0;
  @State isNewLogin: boolean = false; // Track if this is a new login
  @State lastUpdateTime: number = 0; // Track the last update time
  @State tempWaterAmount: number = 0; // Temporary variable for water input
  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));
  private context = getContext(this) as common.UIAbilityContext;
  private refreshInterval: number = 0; // For periodic refresh
  @State heartRateRecords: HeartRateRecord[] = [];//心率记录
  @State heartRateInputTimes: string[] = ['08:00']; // 默认添加一个时间
  @State heartRateInputValues: string[] = ['0']; // 默认添加一个心率值
  @State waterInputTimes: string[] = ['08:00']; // 默认添加一个时间
  @State waterInputValues: string[] = ['0']; // 默认添加一个饮水量值
  @State myWeight: number =  0;//体重
  @State myHeight:number = 0;// 身高
  @State bmi:number = 0;
  // 新增状态变量用于步数图表
  @State stepChartData: ChartDataItem[] = [];
  @State chartMode: string = '日'; // '日', '周', '月'
  @State dateRangeText: string = '';
  @State totalSteps: number = 0;
  @State avgDailySteps: number = 0;
  @State maxDisplayValue: number = 15000;
  @State canvasContext: CanvasRenderingContext2D | null = null;
  @State selectedDate: Date = new Date();
  @State isCalendarVisible: boolean = false;

  @State stepInputTimes: string[] = ['08:00'];
  @State stepInputValues: string[] = ['0'];
  @State stepTimeRecords: StepTimeRecord[] = [];
  heartRateDialogController: CustomDialogController = new CustomDialogController({
    builder: HeartRateInputDialog({
      heartRateInputTimes: this.heartRateInputTimes,
      heartRateInputValues: this.heartRateInputValues,
      addHeartRateInputRow: this.addHeartRateInputRow.bind(this),
      removeHeartRateInputRow: this.removeHeartRateInputRow.bind(this),
      saveMultiHeartRates: this.saveMultiHeartRates.bind(this)
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  waterDialogController: CustomDialogController = new CustomDialogController({
    builder: WaterInputDialog({
      waterInputTimes: this.waterInputTimes,
      waterInputValues: this.waterInputValues,
      addWaterInputRow: this.addWaterInputRow.bind(this),
      removeWaterInputRow: this.removeWaterInputRow.bind(this),
      saveMultiWaterRecords: this.saveMultiWaterRecords.bind(this)
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  });
  stepDialogController: CustomDialogController = new CustomDialogController({
    builder: StepInputDialog({
      stepInputTimes: this.stepInputTimes,
      stepInputValues: this.stepInputValues,
      addStepInputRow: this.addStepInputRow.bind(this),
      removeStepInputRow: this.removeStepInputRow.bind(this),
      saveMultiStepRecords: this.saveMultiStepRecords.bind(this)
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  aboutToAppear() {
    const params = router.getParams() as RouteParams;
    if (params) {
      if (params.username) {
        this.username = params.username;
      }
      if (params.userId) {
        this.userId = params.userId;
      }
      if (params.newLogin) {
        this.isNewLogin = true;
        hilog.info(0x0000, TAG, 'New login detected, refreshing data');
      }
    }
    this.initData();
    this.checkReceivedData();
    this.refreshInterval = setInterval(() => {
      this.refreshData();
    }, 30000);
  }

  aboutToDisappear() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }
    this.dbHelper.closeDatabase();
    this.heartRateDialogController.close();
    this.waterDialogController.close();
    this.stepDialogController.close(); // Add this line
  }

  async initData() {
    try {
      await this.dbHelper.initDatabase();

      if (this.userId < 0 && this.username) {
        const users = await this.dbHelper.queryUserByUsername(this.username);
        if (users.length > 0) {
          this.userId = users[0].id || -1;
        }
      }
      if (this.userId > 0) {
        // 获取用户个人信息（身高和体重）
        const userInfo = await this.dbHelper.getUserById(this.userId);
        if (userInfo) {
          this.myHeight = userInfo.height || 0;
          this.myWeight = userInfo.weight || 0;
          if (this.myHeight > 0 && this.myWeight > 0) {
            this.bmi = this.myWeight / Math.pow(this.myHeight / 100, 2);
          }
        }
        await this.loadHealthData();
        await this.updateStepChartData();
      }
      const stepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
      if (stepRecords.length > 0) {
        this.steps = stepRecords[0].steps;

        // 加载步数时间记录
        if (stepRecords[0].id) {
          this.stepTimeRecords = await this.dbHelper.getStepTimeRecords(Number(stepRecords[0].id));
        } else {
          this.stepTimeRecords = [];
        }
      } else {
        this.steps = 0;
        this.stepTimeRecords = [];
      }
      this.isNewLogin = false;
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to initialize data: ${errorMessage}`);
    }
  }

  async refreshData() {
    try {
      hilog.info(0x0000, TAG, 'Checking for data updates');
      if (this.userId > 0) {
        const userInfo = await this.dbHelper.getUserById(this.userId);
        if (userInfo) {
          this.myHeight = userInfo.height || 0;
          this.myWeight = userInfo.weight || 0;
          if (this.myHeight > 0 && this.myWeight > 0) {
            this.bmi = this.myWeight / Math.pow(this.myHeight / 100, 2);
          }
        }
        await this.loadHealthData();
        await this.updateStepChartData(); // 刷新步数图表数据
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to refresh data: ${errorMessage}`);
    }
  }

  async loadHealthData() {
    try {
      const stepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
      if (stepRecords.length > 0) {
        this.steps = stepRecords[0].steps;
      } else {
        this.steps = 0;
      }

      const heartRateRecords = await this.dbHelper.getHeartRateRecords(this.userId, this.currentDate);
      this.heartRateRecords = heartRateRecords;

      if (heartRateRecords.length > 0) {
        this.heartRate = heartRateRecords[heartRateRecords.length - 1].rate;
      } else {
        this.heartRate = 0;
      }
      const sleepRecords = await this.dbHelper.getSleepRecords(this.userId, this.currentDate);
      if (sleepRecords.length > 0) {
        this.sleepHours = sleepRecords[0].duration / 60;
      } else {
        this.sleepHours = 0;
      }

      const waterRecords = await this.dbHelper.getWaterRecords(this.userId, this.currentDate);
      this.waterRecords = waterRecords;
      this.waterAmount = waterRecords.reduce((total, record) => total + record.amount, 0);

      this.lastUpdateTime = Date.now();
      hilog.info(0x0000, TAG, 'Health data loaded successfully');


    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to load health data: ${errorMessage}`);
    }
  }

  async updateStepChartData() {
    try {
      let data: ChartDataItem[] = [];
      let total = 0;
      let dateDisplay = '';

      const currentDateObj = new Date(this.currentDate);

      switch (this.chartMode) {
        case '日':
          const timeSlots = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];

          const dayStepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
          let dayTotalSteps = dayStepRecords.length > 0 ? dayStepRecords[0].steps : 0;
          total = dayTotalSteps;

          const hourlyDistribution = [0.05, 0.05, 0.15, 0.30, 0.35, 0.10]; // Distribution percentages

          for (let i = 0; i < timeSlots.length; i++) {
            const slotSteps = Math.round(dayTotalSteps * hourlyDistribution[i]);
            data.push({
              label: timeSlots[i],
              value: slotSteps
            });
          }

          this.maxDisplayValue = Math.max(15000, dayTotalSteps * 0.4);
          dateDisplay = this.currentDate;
          this.avgDailySteps = dayTotalSteps;
          break;

        case '周':
          const today = new Date(this.currentDate);
          const currentDayOfWeek = today.getDay() || 7; // Convert Sunday from 0 to 7
          const mondayOfWeek = new Date(today);
          mondayOfWeek.setDate(today.getDate() - currentDayOfWeek + 1);

          let weekTotal = 0;
          let dayCount = 0;

          for (let i = 0; i < 7; i++) {
            const date = new Date(mondayOfWeek);
            date.setDate(mondayOfWeek.getDate() + i);
            const dateStr = date.toISOString().split('T')[0];

            // Get actual data from database
            const stepRecords = await this.dbHelper.getStepRecords(this.userId, dateStr);
            const daySteps = stepRecords.length > 0 ? stepRecords[0].steps : 0;

            data.push({
              label: `${date.getMonth() + 1}/${date.getDate()}`,
              value: daySteps
            });

            weekTotal += daySteps;
            if (daySteps > 0) dayCount++;
          }

          total = weekTotal;
          this.maxDisplayValue = Math.max(15000, Math.ceil(weekTotal / 7) * 1.5);

          const endOfWeek = new Date(mondayOfWeek);
          endOfWeek.setDate(mondayOfWeek.getDate() + 6);
          dateDisplay = `${mondayOfWeek.getFullYear()}年${mondayOfWeek.getMonth() + 1}月${mondayOfWeek.getDate()}日至${endOfWeek.getDate()}日`;
          this.avgDailySteps = dayCount > 0 ? Math.round(weekTotal / dayCount) : 0;
          break;

        case '月':
          const year = currentDateObj.getFullYear();
          const month = currentDateObj.getMonth();
          const daysInMonth = new Date(year, month + 1, 0).getDate();

          let monthTotal = 0;
          let activeDays = 0;


          for (let i = 1; i <= daysInMonth; i++) {
            // Format date string YYYY-MM-DD
            const monthStr = (month + 1).toString().padStart(2, '0');
            const dayStr = i.toString().padStart(2, '0');
            const dateStr = `${year}-${monthStr}-${dayStr}`;

            // Get actual data from database
            const stepRecords = await this.dbHelper.getStepRecords(this.userId, dateStr);
            const daySteps = stepRecords.length > 0 ? stepRecords[0].steps : 0;

            data.push({
              label: `${i}`,
              value: daySteps
            });

            monthTotal += daySteps;
            if (daySteps > 0) activeDays++;
          }

          total = monthTotal;
          this.maxDisplayValue = Math.max(15000, Math.ceil(monthTotal / daysInMonth) * 1.5);
          dateDisplay = `${year}年${month + 1}月`;
          this.avgDailySteps = activeDays > 0 ? Math.round(monthTotal / activeDays) : 0;
          break;
      }

      this.stepChartData = data;
      this.totalSteps = total;
      this.dateRangeText = dateDisplay;
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to update step chart data: ${errorMessage}`);
    }
  }

  async openCalendar() {
    try {
      const want: Want = {
        deviceId: "",
        bundleName: "com.huawei.calendar",
        abilityName: "com.huawei.calendar.LauncherAbility"
      };

      let context = getContext(this) as common.UIAbilityContext;
      await context.startAbility(want);
      console.info("grf_成功打开系统日历");
    } catch (error) {
      console.info(`grf_打开系统日历失败：${error}`);
    }
  }

  async selectDate() {
    try {
    } catch (err) {
      console.error(`Select date failed with error: ${err}`);
    }
  }

  calculateBarHeight(value: number): number {
    const maxHeight = 120;
    const calculatedHeight = (value / this.maxDisplayValue) * maxHeight;
    return Math.max(calculatedHeight, value > 0 ? 5 : 0);
  }

  async checkReceivedData() {
    try {
      if (this.context && this.context.abilityInfo && this.context.abilityInfo.metadata) {
        const parameters = this.context.abilityInfo.metadata as MetadataParams;
        const healthDataParam = parameters.healthData;
        if (typeof healthDataParam === 'string') {
          this.receivedHealthData = healthDataParam;
          hilog.info(0x0000, TAG, `Received health data: ${this.receivedHealthData}`);

          this.refreshData();
        }
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Error getting parameters: ${errorMessage}`);
    }
  }

  async shareHealthData() {
    try {
      await this.refreshData();

      const healthData: HealthData = {
        userId: this.userId,
        username: this.username,
        date: this.currentDate,
        steps: this.steps,
        heartRate: this.heartRate,
        sleepHours: this.sleepHours,
        waterAmount: this.waterAmount,
      };

      // 将数据转换为JSON字符串
      const dataString = JSON.stringify(healthData);
      const want: Want = {
        bundleName: 'com.example.target',
        abilityName: 'EntryAbility',
        moduleName: 'entry',
        parameters: {
          healthData: dataString
        }
      };
      this.context.startAbility(want)
        .then(() => {
          hilog.info(0x0000, TAG, 'Health data shared successfully');
        })
        .catch((err: Error) => {
          hilog.error(0x0000, TAG, `Failed to start ability: ${err.message}`);
        });
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to share health data: ${errorMessage}`);
    }
  }

  ClickJumpToShowData() {
    this.refreshData().then(() => {
      const routerParams: RouterParams = {
        username: this.username,
        userId: this.userId.toString(),
        steps: this.steps.toString(),
        heartRate: this.heartRate.toString(),
        sleepHours: this.sleepHours.toString(),
        waterAmount: this.waterAmount.toString(),
        date: this.currentDate // 添加日期参数
      };

      router.pushUrl({
        url: 'pages/dataShow',
        params: routerParams
      }, router.RouterMode.Standard, (err) => {
        if (err) {
          console.error(`error_jump_failed code: ${err.code}, message: ${err.message}`);
          return;
        }
        console.info('Navigate to ShowData success');
      });
    });
  }

  manualRefresh() {
    hilog.info(0x0000, TAG, 'Manual refresh triggered');
    this.refreshData();
  }

  addHeartRateInputRow() {
    this.heartRateInputTimes.push('');
    this.heartRateInputValues.push('');
  }

  removeHeartRateInputRow(index: number) {
    if (this.heartRateInputTimes.length > 1) {
      this.heartRateInputTimes.splice(index, 1);
      this.heartRateInputValues.splice(index, 1);
    }
  }

  addWaterInputRow() {
    this.waterInputTimes.push('');
    this.waterInputValues.push('');
  }

  removeWaterInputRow(index: number) {
    if (this.waterInputTimes.length > 1) {
      this.waterInputTimes.splice(index, 1);
      this.waterInputValues.splice(index, 1);
    }
  }
  addStepInputRow() {
    this.stepInputTimes.push('08:00');
    this.stepInputValues.push('0');
  }

  removeStepInputRow(index: number) {
    if (this.stepInputTimes.length > 1) {
      this.stepInputTimes.splice(index, 1);
      this.stepInputValues.splice(index, 1);
    }
  }


  async saveMultiHeartRates() {
    if (this.userId <= 0) {
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }

    try {
      let successCount = 0;
      // 遍历所有输入行
      for (let i = 0; i < this.heartRateInputTimes.length; i++) {
        const time = this.heartRateInputTimes[i].trim();
        const rate = parseInt(this.heartRateInputValues[i]) || 0;

        if (!time || !this.isValidTimeFormat(time) || rate <= 0) {
          continue;
        }

        const record = new HeartRateRecord(this.userId, this.currentDate, time, rate);
        if (await this.dbHelper.insertHeartRateRecord(record)) {
          successCount++;
        }
      }

      if (successCount > 0) {
        promptAction.showToast({ message: `成功保存 ${successCount} 条心率记录` });
        this.refreshData(); // 刷新数据
      } else {
        promptAction.showToast({ message: '没有有效的心率记录被保存' });
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to save heart rate records: ${errorMessage}`);
      promptAction.showToast({ message: '保存心率记录失败' });
    }
  }

  async saveMultiWaterRecords() {
    if (this.userId <= 0) {
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }
    try {
      let successCount = 0;
      for (let i = 0; i < this.waterInputTimes.length; i++) {
        const time = this.waterInputTimes[i].trim();
        const amount = parseInt(this.waterInputValues[i]) || 0;
        if (!time || !this.isValidTimeFormat(time) || amount <= 0) {
          continue;
        }
        const record = new WaterRecord(this.userId, this.currentDate, time, amount);
        if (await this.dbHelper.insertWaterRecord(record)) {
          successCount++;
        }
      }

      if (successCount > 0) {
        promptAction.showToast({ message: `成功保存 ${successCount} 条饮水记录` });
        this.refreshData();
      } else {
        promptAction.showToast({ message: '没有有效的饮水记录被保存' });
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to save water records: ${errorMessage}`);
      promptAction.showToast({ message: '保存饮水记录失败' });
    }
  }

  // 在mainHome.ets中增强saveMultiStepRecords方法
  async saveMultiStepRecords(): Promise<void> {
    if (this.userId <= 0) {
      hilog.error(0x0000, TAG, `Invalid userId: ${this.userId}`);
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }

    try {
      hilog.info(0x0000, TAG, `Starting to save multi step records for user ${this.userId}`);
      let successCount = 0;

      // 收集有效的时间步数记录
      const validRecords: StepTimeInput[] = [];

      // 记录数据验证过程
      hilog.info(0x0000, TAG, `Total input rows: ${this.stepInputTimes.length}`);

      // 遍历所有输入行
      for (let i = 0; i < this.stepInputTimes.length; i++) {
        const time = this.stepInputTimes[i].trim();
        const stepsStr = this.stepInputValues[i];
        const steps = parseInt(stepsStr) || 0;

        hilog.info(0x0000, TAG, `Validating row ${i}: time=${time}, steps=${steps}`);

        // 验证时间格式和步数
        if (!time) {
          hilog.warn(0x0000, TAG, `Row ${i}: Empty time`);
          continue;
        }

        if (!this.isValidTimeFormat(time)) {
          hilog.warn(0x0000, TAG, `Row ${i}: Invalid time format: ${time}`);
          continue;
        }

        if (steps <= 0) {
          hilog.warn(0x0000, TAG, `Row ${i}: Invalid steps value: ${steps}`);
          continue;
        }

        // 创建记录对象并添加到数组
        const record: StepTimeInput = {
          time: time,
          steps: steps
        };

        validRecords.push(record);
        successCount++;
        hilog.info(0x0000, TAG, `Row ${i}: Valid record added: time=${time}, steps=${steps}`);
      }

      hilog.info(0x0000, TAG, `Collected ${successCount} valid records out of ${this.stepInputTimes.length} inputs`);

      if (successCount > 0) {
        // 使用批量保存方法
        hilog.info(0x0000, TAG, `Calling batchSaveStepRecords with ${validRecords.length} records`);

        const result = await this.dbHelper.batchSaveStepRecords(
          this.userId,
          this.currentDate,
          validRecords
        );

        if (result) {
          // 计算总步数
          const totalSteps = validRecords.reduce((sum, record) => sum + record.steps, 0);
          hilog.info(0x0000, TAG, `Successfully saved ${successCount} records with total steps: ${totalSteps}`);

          promptAction.showToast({
            message: `成功保存 ${successCount} 条步数记录，总步数: ${totalSteps}`
          });

          // 刷新数据
          hilog.info(0x0000, TAG, 'Refreshing data after saving');
          await this.refreshData();
        } else {
          hilog.error(0x0000, TAG, 'batchSaveStepRecords returned false');
          promptAction.showToast({ message: '保存步数记录失败' });
        }
      } else {
        hilog.warn(0x0000, TAG, 'No valid records to save');
        promptAction.showToast({ message: '没有有效的步数记录被保存' });
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Exception in saveMultiStepRecords: ${errorMessage}`);
      hilog.error(0x0000, TAG, `Stack trace: ${error instanceof Error ? error.stack : 'No stack trace'}`);
      promptAction.showToast({ message: '保存步数记录失败: ' + errorMessage });
    }
  }

  isValidTimeFormat(time: string): boolean {
    const regex = /^([01]?[0-9]|2[0-3]):([0-5][0-9])$/;
    return regex.test(time);
  }

  build() {
    Column() {
      Row() {
        Text("个人健康管理系统")
          .fontSize(24)
          .fontColor('#1698CE')
          .fontWeight(FontWeight.Bold)
        Blank()
        if (this.username) {
          Text(`欢迎，${this.username}`)
            .fontSize(18)
            .fontColor('#333')
        }
      }
      .width('90%')
      .height('10%')
      .padding({ top: 10, bottom: 10 })

      Divider()
        .width('90%')
        .height(1)
        .backgroundColor('#ddd')

      // 主要内容区域
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          Scroll() {
            Column() {
              Text('今日健康数据概览')
                .titleText()

              Row() {
                HealthDataCard({
                  title: '步数',
                  value: this.steps.toString(),
                  color: '#1698CE'
                })

                HealthDataCard({
                  title: '最近心率',
                  value: this.heartRate.toString(),
                  unit: 'bpm',
                  color: '#E74C3C'
                })
              }
              .width('90%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ top: 10, bottom: 20 })

              Row() {
                HealthDataCard({
                  title: '睡眠时长',
                  value: this.sleepHours.toFixed(1),
                  unit: '小时',
                  color: '#9B59B6'
                })

                HealthDataCard({
                  title: '饮水量',
                  value: this.waterAmount.toString(),
                  unit: 'ml',
                  color: '#3498DB'
                })
              }
              .width('90%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ top: 10, bottom: 20 })

              // 分享和查看详情按钮
              Row() {
                Button('分享健康数据')
                  .width('45%')
                  .height(40)
                  .backgroundColor('#27AE60')
                  .margin({ right: 10 })
                  .onClick(() => {
                    this.shareHealthData();
                  })

                Button('查看详细数据')
                  .width('45%')
                  .height(40)
                  .backgroundColor('#3498DB')
                  .onClick(() => {
                    this.ClickJumpToShowData();
                  })
              }
              .width('90%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ top: 20, bottom: 20 })

              // Pull to refresh text
              Text('下拉刷新数据')
                .fontSize(14)
                .fontColor('#888')
                .margin({ top: 5, bottom: 15 })

              // 显示接收到的健康数据
              if (this.receivedHealthData) {
                Column() {
                  Text('接收到的健康数据')
                    .subtitleText()
                    .alignSelf(ItemAlign.Start)

                  Text(this.receivedHealthData)
                    .fontSize(14)
                    .fontColor('#666')
                    .width('100%')
                }
                .cardContainer()
                .margin({ top: 10, bottom: 20 })
              }

              // 最近饮水记录
              Column() {
                Text('今日饮水记录')
                  .subtitleText()
                  .alignSelf(ItemAlign.Start)

                List() {
                  ForEach(this.waterRecords, (item: WaterRecord) => {
                    ListItem() {
                      WaterRecordItem({ record: item })
                    }
                  })
                }
                .width('100%')
                .height(150)
                .divider({ strokeWidth: 1, color: '#eeeeee' })
              }
              .cardContainer()
              .margin({ top: 10, bottom: 20 })

              Divider()
                .width('90%')
                .height(1)
                .backgroundColor('#ddd')

              //心率记录
              Column() {
                Text('今日心率记录')
                  .subtitleText()
                  .alignSelf(ItemAlign.Start)

                List() {
                  ForEach(this.heartRateRecords, (item: HeartRateRecord) => {
                    ListItem() {
                      HeartRateRecordItem({ record: item })
                    }
                  })
                }
                .width('100%')
                .height(150)
                .divider({ strokeWidth: 1, color: '#eeeeee' })
              }
              .cardContainer()
              .margin({ top: 10, bottom: 20 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .scrollBar(BarState.Auto)
          .onScrollFrameBegin((offset: number) => {
            // Implement pull-to-refresh functionality
            if (offset <= -100) { // If pulled down more than 100px
              this.refreshData();
              return { offsetRemain: 0 };
            }
            return { offsetRemain: offset };
          })
        }
        .tabBar({ text: '首页'})

        // 数据输入页面
        TabContent() {
          Column() {
            Text('健康数据录入')
              .titleText()
            Scroll() {
              Column() {
                // 步数输入
                Column() {
                  Text('步数录入')
                    .subtitleText()
                    .alignSelf(ItemAlign.Start)

                  Row(){
                    TextInput({ text: this.steps.toString() })
                      .type(InputType.Number)
                      .width('60%')
                      .height(50)
                      .margin({ bottom: 10 })
                      .onChange((value: string) => {
                        this.steps = parseInt(value) || 0;
                      })

                    Button('保存步数')
                      .width('40%')
                      .height(50)
                      .backgroundColor('#1698CE')
                      .margin({ bottom: 10, left:'5%'})
                      .onClick(async () => {
                        if (this.userId > 0) {
                          try {
                            // 查询是否已有当日记录
                            const stepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
                            if (stepRecords.length > 0) {
                              // 更新现有记录
                              const record = stepRecords[0];
                              record.steps = this.steps;
                              if (await this.dbHelper.updateStepRecord(record)) {
                                promptAction.showToast({ message: '步数更新成功' });
                              } else {
                                promptAction.showToast({ message: '步数更新失败' });
                              }
                            } else {
                              // 创建新记录
                              const record = new StepRecord(this.userId, this.currentDate, this.steps);
                              if (await this.dbHelper.insertStepRecord(record)) {
                                promptAction.showToast({ message: '步数保存成功' });
                              } else {
                                promptAction.showToast({ message: '步数保存失败' });
                              }
                            }
                            // 刷新数据
                            this.refreshData();
                          } catch (error) {
                            const errorMessage: string = error instanceof Error ? error.message : String(error);
                            hilog.error(0x0000, TAG, `Failed to save step data: ${errorMessage}`);
                            promptAction.showToast({ message: '操作失败' });
                          }
                        } else {
                          promptAction.showToast({ message: '用户ID无效' });
                        }
                      })
                  }

                  // Add batch input steps button
                  Button('批量输入步数')
                    .width('90%')
                    .height(40)
                    .backgroundColor('#1698CE')
                    .margin({ bottom: 10 })
                    .onClick(() => {
                      this.stepInputTimes = ['08:00'];
                      this.stepInputValues = ['0'];
                      this.stepDialogController.open();
                    })
                }
                .cardContainer()

                // 心率输入
                Column() {
                  Text('心率录入')
                    .subtitleText()
                    .alignSelf(ItemAlign.Start)

                  // 使用自定义的DataInputRow组件
                  DataInputRow({
                    title: '心率录入',
                    placeholder: '输入心率',
                    unit: 'bpm',
                    buttonText: '保存心率',
                    buttonColor: '#E74C3C',
                    onInputChange: (value: string) => {
                      this.heartRate = parseInt(value) || 0;
                    },
                    onButtonClick: async () => {
                      if (this.userId > 0) {
                        try {
                          // 获取当前时间
                          const now = new Date();
                          const timeStr = now.toTimeString().split(' ')[0].substring(0, 5); // Format: HH:MM

                          // 创建新的心率记录（心率可以有多条记录）
                          const record = new HeartRateRecord(this.userId, this.currentDate, timeStr, this.heartRate);
                          if (await this.dbHelper.insertHeartRateRecord(record)) {
                            promptAction.showToast({ message: '心率保存成功' });
                          } else {
                            promptAction.showToast({ message: '心率保存失败' });
                          }
                          // 刷新数据
                          this.refreshData();
                        } catch (error) {
                          const errorMessage: string = error instanceof Error ? error.message : String(error);
                          hilog.error(0x0000, TAG, `Failed to save heart rate data: ${errorMessage}`);
                          promptAction.showToast({ message: '操作失败' });
                        }
                      } else {
                        promptAction.showToast({ message: '用户ID无效' });
                      }
                    }
                  })

                  // 添加批量输入心率按钮
                  Button('批量输入心率')
                    .secondaryButton('#E74C3C')
                    .opacity(0.8)
                    .onClick(() => {
                      this.heartRateInputTimes = ['08:00'];
                      this.heartRateInputValues = ['0'];
                      this.heartRateDialogController.open();
                    })
                }
                .cardContainer()

                // 睡眠时长输入
                Column() {
                  Text('睡眠记录')
                    .subtitleText()
                    .alignSelf(ItemAlign.Start)

                  // 使用自定义的DataInputRow组件
                  DataInputRow({
                    title: '睡眠记录',
                    placeholder: '请输入睡眠时长',
                    unit: '小时',
                    buttonText: '保存时长',
                    buttonColor: '#9B59B6',
                    onInputChange: (value: string) => {
                      let sleepValue = parseFloat(value) || 0;
                      if (sleepValue < 0) sleepValue = 0;
                      if (sleepValue > 24) sleepValue = 24;
                      this.sleepHours = sleepValue;
                    },
                    onButtonClick: async () => {
                      if (this.userId > 0) {
                        if (this.sleepHours < 0 || this.sleepHours > 24) {
                          promptAction.showToast({ message: '睡眠时长必须在0-24小时之间' });
                          return;
                        }

                        try {
                          // 查询是否已有当日记录
                          const sleepRecords = await this.dbHelper.getSleepRecords(this.userId, this.currentDate);
                          const sleepMinutes = Math.round(this.sleepHours * 60); // 转换为分钟

                          if (sleepRecords.length > 0) {
                            // 更新现有记录
                            const record = sleepRecords[0];
                            record.duration = sleepMinutes;
                            if (await this.dbHelper.updateSleepRecord(record)) {
                              promptAction.showToast({ message: '睡眠时长更新成功' });
                            } else {
                              promptAction.showToast({ message: '睡眠时长更新失败' });
                            }
                          } else {
                            // 创建新记录
                            const record = new SleepRecord(this.userId, this.currentDate, sleepMinutes);
                            if (await this.dbHelper.insertSleepRecord(record)) {
                              promptAction.showToast({ message: '睡眠时长保存成功' });
                            } else {
                              promptAction.showToast({ message: '睡眠时长保存失败' });
                            }
                          }
                          // 刷新数据
                          this.refreshData();
                        } catch (error) {
                          const errorMessage: string = error instanceof Error ? error.message : String(error);
                          hilog.error(0x0000, TAG, `Failed to save sleep data: ${errorMessage}`);
                          promptAction.showToast({ message: '操作失败' });
                        }
                      } else {
                        promptAction.showToast({ message: '用户ID无效' });
                      }
                    }
                  })

                  Text('睡眠时长范围: 0-24小时')
                    .fontSize(14)
                    .fontColor('#888')
                    .margin({ bottom: 10 })
                }
                .cardContainer()

                // 饮水量输入
                Column() {
                  Text('饮水记录')
                    .subtitleText()
                    .alignSelf(ItemAlign.Start)

                  // 使用自定义的DataInputRow组件
                  DataInputRow({
                    title: '饮水记录',
                    placeholder: '请输入饮水量(ml)',
                    unit: 'ml',
                    buttonText: '添加记录',
                    buttonColor: '#3498DB',
                    onInputChange: (value: string) => {
                      this.tempWaterAmount = parseInt(value) || 0;
                    },
                    onButtonClick: async () => {
                      if (this.userId > 0 && this.tempWaterAmount > 0) {
                        try {
                          // 获取当前时间
                          const now = new Date();
                          const timeStr = now.toTimeString().split(' ')[0].substring(0, 5); // Format: HH:MM

                          // 创建新的饮水记录
                          const record = new WaterRecord(this.userId, this.currentDate, timeStr, this.tempWaterAmount);
                          if (await this.dbHelper.insertWaterRecord(record)) {
                            promptAction.showToast({ message: '饮水记录添加成功' });
                            // 重置临时水量
                            this.tempWaterAmount = 0;
                          } else {
                            promptAction.showToast({ message: '饮水记录添加失败' });
                          }
                          // 刷新数据
                          this.refreshData();
                        } catch (error) {
                          const errorMessage: string = error instanceof Error ? error.message : String(error);
                          hilog.error(0x0000, TAG, `Failed to save water data: ${errorMessage}`);
                          promptAction.showToast({ message: '操作失败' });
                        }
                      } else if (this.tempWaterAmount <= 0) {
                        promptAction.showToast({ message: '请输入有效的饮水量' });
                      } else {
                        promptAction.showToast({ message: '用户ID无效' });
                      }
                    }
                  })

                  // 添加批量输入饮水量按钮
                  Button('批量输入饮水量')
                    .secondaryButton('#3498DB')
                    .opacity(0.8)
                    .onClick(() => {
                      this.waterInputTimes = ['08:00'];
                      this.waterInputValues = ['0'];
                      this.waterDialogController.open();
                    })

                  // 显示今日总饮水量
                  Text(`今日总饮水量: ${this.waterAmount} ml`)
                    .fontSize(16)
                    .fontColor('#3498DB')
                    .margin({ top: 10 })
                }
                .cardContainer()
                .margin({ bottom: 20 })

                // 数据刷新按钮
                Column() {
                  Button('刷新所有数据')
                    .primaryButton()
                    .backgroundColor('#2ECC71')
                    .onClick(() => {
                      this.refreshData();
                      promptAction.showToast({ message: '数据已刷新' });
                    })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
                .margin({ bottom: 20 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
            }
            .scrollBar(BarState.Auto)
            .width('100%')
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar({ text: '数据输入' })

        //运动界面
        TabContent() {
          Scroll() {
              Column() {
                Row() {
                  Text('步数')
                    .titleText()
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                }
                Row() {
                  Text(this.dateRangeText)
                    .labelText()
                    .textAlign(TextAlign.Center)
                }
                .justifyContent(FlexAlign.Center)
                .width('100%')


                Divider();

                // 图表模式切换
                Row() {
                  ForEach(['日', '周', '月'], (mode: string) => {
                    Text(mode)
                      .fontSize(16)
                      .fontWeight(this.chartMode === mode ? FontWeight.Bold : FontWeight.Normal)
                      .fontColor(this.chartMode === mode ? '#000' : '#666')
                      .backgroundColor(this.chartMode === mode ? '#fff' : '#f5f5f5')
                      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                      .borderRadius(20)
                      .onClick(() => {
                        this.chartMode = mode;
                        this.updateStepChartData();
                      })
                  })
                }
                .width('100%')
                .margin({top : '10%'})
                .justifyContent(FlexAlign.SpaceEvenly)
                .margin({ bottom: 20 })

                // 步数显示
                Column() {
                  Row() {
                    Text(this.totalSteps.toString())
                      .valueText()
                    Text('步')
                      .fontSize(20)
                      .margin({ left: 5 })
                  }

                  Text(this.dateRangeText)
                    .fontSize(14)
                    .fontColor('#666')
                    .margin({ top: 5 })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .margin({ bottom: 20 })

                // 柱状图组件 - 修复柱状图覆盖日期的问题
                Column() {
                  // Y轴标签和网格线
                  Stack() {
                    // Y轴刻度 - 动态调整以适应数据
                    Column() {
                      ForEach([1, 0.8, 0.6, 0.4, 0.2, 0], (ratio: number) => {
                        Row() {
                          Text(Math.round(this.maxDisplayValue * ratio).toString())
                            .fontSize(12)
                            .fontColor('#999')
                            .width(50)
                            .textAlign(TextAlign.End)
                            .margin({ right: 10 })

                          // 网格线
                          Divider()
                            .width('100%')
                            .color('#eee')
                        }
                        .width('100%')
                        .height(25)
                      })
                    }
                    .height(150)
                    .width('100%')
                    .alignItems(HorizontalAlign.Start)

                    Column() {
                      List({ space: 0 }) {
                        ForEach(this.stepChartData, (item: ChartDataItem) => {
                          ListItem() {
                            Column() {
                              // 柱子部分 - 确保柱子位于上方，不会延伸到下方标签区域
                              Column() {
                                if (item.value > 0) {
                                  Column()
                                    .width(this.chartMode === '月' ? 20 : 40)
                                    .height(this.calculateBarHeight(item.value))
                                    .backgroundColor('#FFD700')
                                    .borderRadius(this.chartMode === '月' ? 3 : 5)
                                }
                              }
                              .height(130)
                              .width('100%')
                              .justifyContent(FlexAlign.End)
                            }
                            .alignItems(HorizontalAlign.Center)
                          }
                          .width(this.chartMode === '月' ? 40 : 60)
                        })
                      }
                      .listDirection(Axis.Horizontal) // 水平列表
                      .scrollBar(BarState.Auto) // 显示滚动条
                      .scrollBarColor(Color.Gray)
                      .scrollBarWidth(2)
                      .edgeEffect(EdgeEffect.Spring) // 滚动到边缘时的弹性效果
                      .width('100%')
                      .height(130) // 减小高度，与柱子容器一致
                    }
                    .width('100%')
                    .height(150)
                    .margin({ left: 60 })
                  }

                  // 将日期标签单独放在下方，确保不被柱状图覆盖
                  List() {
                    ForEach(this.stepChartData, (item: ChartDataItem) => {
                      ListItem() {
                        Text(item.label)
                          .fontSize(14)
                          .fontColor('#333')
                          .textAlign(TextAlign.Center)
                          .width('100%')
                          .padding({ top: 5, bottom: 5 })
                      }
                      .width(this.chartMode === '月' ? 40 : 60)
                    })
                  }
                  .listDirection(Axis.Horizontal)
                  .scrollBar(BarState.Off) // 隐藏日期部分的滚动条
                  .width('100%')
                  .height(30)
                  .margin({ left: 60 }) // 与上方柱状图对齐
                  .onScrollIndex((firstIndex: number) => {
                    // 同步两个List的滚动位置
                    // 注意：需要添加引用以实现此功能
                  //this.chartListController.scrollTo({ index: firstIndex });
                  })

                  // 分隔线，明确分隔图表和日期区域
                  Divider()
                    .width('90%')
                    .strokeWidth(1)
                    .color('#ddd')
                    .margin({ top: 5 })

                  // 图表说明
                  Text('← 左右滑动查看更多数据 →')
                    .fontSize(12)
                    .fontColor('#666')
                    .textAlign(TextAlign.Center)
                    .width('100%')
                    .margin({ top: 5 })
                }
                .width('100%')
                .margin({ bottom: 20 })

                // 概览部分
                Row() {
                  Image($r('app.media.target'))
                    .width(24)
                    .height(24)
                    .margin({ right: 10 })

                  Text('本周概览')
                    .subtitleText()
                }
                .width('100%')
                .margin({ bottom: 10 })

                Row() {
                  Column() {
                    Text(this.totalSteps.toString())
                      .valueText()
                    Text('总步数')
                      .labelText()
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)

                  Column() {
                    Text((this.totalSteps / 3 / 1000).toFixed(2))
                      .valueText()
                    Text('总距离(公里)')
                      .labelText()
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 20 })

                Row() {
                  Column() {
                    Text(this.avgDailySteps.toString())
                      .valueText()
                    Text('日均步数')
                      .labelText()
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)

                  Column() {
                    // 使用正确的换算: 三步=一米，再转换为公里
                    Text((this.avgDailySteps / 3 / 1000).toFixed(2))
                      .valueText()
                    Text('日均距离(公里)')
                      .labelText()
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)
                }
                .width('100%')

                // 在运动选项卡中找到"今日步数详细记录"区域，修改为：
                Column() {
                  Row() {
                    Image($r('app.media.target'))
                      .width(24)
                      .height(24)
                      .margin({ right: 10 })

                    Text('今日步数详细记录')
                      .subtitleText()
                  }
                  .width('100%')
                  .margin({ bottom: 10 })

                  if (this.stepTimeRecords.length > 0) {
                    List() {
                      ForEach(this.stepTimeRecords, (item: StepTimeRecord) => {
                        ListItem() {
                          StepTimeRecordItem({ record: item })
                        }
                      })
                    }
                    .width('100%')
                    .height(this.stepTimeRecords.length > 3 ? 200 : undefined)
                    .divider({ strokeWidth: 1, color: '#eeeeee' })
                  } else {
                    Text('暂无详细步数记录')
                      .fontSize(14)
                      .fontColor('#999')
                      .padding(10)
                  }
                }
                .width('100%')
                .padding(15)
                .borderRadius(8)
                .backgroundColor('#f5f5f5')
                .margin({ top: 10, bottom: 20 })

                // 添加批量输入步数按钮
                Button('批量输入步数')
                  .width('90%')
                  .height(40)
                  .backgroundColor('#1698CE')
                  .margin({ top: 10, bottom: 20 })
                  .onClick(() => {
                    this.stepInputTimes = ['08:00'];
                    this.stepInputValues = ['0'];
                    this.stepDialogController.open();
                  })
                // 分割线
                Divider()
                  .width('90%')
                  .height(1)
                  .backgroundColor('#ddd')
                  .margin({ top: 10, bottom: 10 })

                // 身体成分分析部分
                Row() {
                  Image($r('app.media.bmi'))
                    .width(24)
                    .height(24)
                    .margin({ right: 10 })

                  Text('身体成分分析')
                    .subtitleText()
                }
                .width('100%')
                .margin({ bottom: 10 })

                Row() {
                  Column(){
                    Text(this.myWeight.toString())
                      .valueText()
                    Text('体重 (kg)')
                      .labelText()
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)

                  Column() {
                    Text(this.myHeight.toString())
                      .valueText()
                    Text('身高 (cm)')
                      .labelText()
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 10 })

                Row() {
                  Column(){
                    Text(this.bmi.toFixed(1))
                      .valueText()
                    Text('BMI')
                      .labelText()
                      .margin({ top: 5 })
                  }
                  .layoutWeight(1)

                  Column() {
                    Text('    ')
                      .valueText()
                  }
                  .layoutWeight(1)
                }
                .width('100%')
                .margin({ bottom: 10 })
              }
              .width('100%')
              .padding(15)
              .borderRadius(8)
              .backgroundColor('#f5f5f5')
              .margin({ top: 10, bottom: 20 })
          }
          .scrollBar(BarState.Auto)
          .onScrollFrameBegin((offset: number) => {
            if (offset <= -100) {
              this.refreshData();
              return { offsetRemain: 0 };
            }
            return { offsetRemain: offset };
          })
        }
        .tabBar({ text: '我的运动'})

        // 个人中心页面
        TabContent() {
          Column() {
            Text('个人中心')
              .titleText()
            Column() {
              Row() {
                Column() {
                  // 用户头像
                  Image($r('app.media.image_1'))
                    .width(80)
                    .height(80)
                    .borderRadius(40)
                }
                .margin({ right: 20 })

                Column() {
                  Row() {
                    Text('用户名：')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .width('30%')
                    Text(this.username)
                      .fontSize(16)
                      .width('70%')
                  }
                  .width('100%')
                  .padding({ top: 5, bottom: 5 })

                  Row() {
                    Text('用户ID：')
                      .fontSize(12)
                      .fontWeight(FontWeight.Bold)
                      .width('30%')
                    Text(this.userId.toString())
                      .fontSize(16)
                      .width('70%')
                  }
                  .width('100%')
                  .padding({ top: 5, bottom: 5 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding(10)

              Button('编辑个人资料')
                .primaryButton()
                .onClick(() => {
                  hilog.info(0x0000, TAG, `Navigating to myInfo with username: ${this.username}, userId: ${this.userId}`);
                  router.pushUrl({
                    url: 'pages/myInfo',
                    params: {
                      username: this.username,
                      userId: this.userId,
                      isEdit: true
                    }
                  }, router.RouterMode.Standard, (err) => {
                    if (err) {
                      console.error(`跳转到个人信息页面失败: ${err.code}, ${err.message}`);
                      promptAction.showToast({ message: '跳转失败，请重试' });
                      return;
                    }
                    console.info('跳转到个人信息页面成功');
                  });
                })
            }
            .cardContainer()
            .margin({ bottom: 20 })


            Column() {
              // 健康数据分析菜单项
              Row() {
                Image($r('app.media.data'))
                  .width(30)
                  .height(30)
                  .margin({ right: 10 })
                Text('健康数据分析')
                  .fontSize(16)
                  .layoutWeight(1)
                Image($r('app.media.data'))
                  .width(20)
                  .height(20)
              }
              .menuItem()
              .onClick(() => {
                this.ClickJumpToShowData();
              })

              // 健康目标设置菜单项
              Row() {
                Image($r('app.media.target'))
                  .width(30)
                  .height(30)
                  .margin({ right: 10 })
                Text('健康目标设置')
                  .fontSize(16)
                  .layoutWeight(1)
                Image($r('app.media.target'))
                  .width(20)
                  .height(20)
              }
              .menuItem()
              .onClick(() => {
                promptAction.showToast({
                  message: '健康目标设置功能即将上线',
                  duration: 2000
                });
              })

              // 健康提醒菜单项
              Row() {
                Image($r('app.media.remind'))
                  .width(30)
                  .height(30)
                  .margin({ right: 10 })
                Text('健康提醒')
                  .fontSize(16)
                  .layoutWeight(1)
                Image($r('app.media.remind'))
                  .width(20)
                  .height(20)
              }
              .menuItem()
              .onClick(() => {
                promptAction.showToast({
                  message: '健康提醒功能即将上线',
                  duration: 2000
                });
              })

              // 设置菜单项
              Row() {
                Image($r('app.media.settings'))
                  .width(30)
                  .height(30)
                  .margin({ right: 10 })
                Text('设置')
                  .fontSize(16)
                  .layoutWeight(1)
                Image($r('app.media.settings'))
                  .width(20)
                  .height(20)
              }
              .menuItem()
              .onClick(() => {
                promptAction.showToast({
                  message: '设置功能即将上线',
                  duration: 2000
                });
              })

              // 退出登录菜单项
              Row() {
                Image($r('app.media.logout'))
                  .width(30)
                  .height(30)
                  .margin({ right: 10 })
                Text('退出登录')
                  .fontSize(16)
                  .layoutWeight(1)
                Image($r('app.media.logout'))
                  .width(20)
                  .height(20)
              }
              .menuItem()
              .onClick(() => {
                router.clear();
                router.pushUrl({
                  url: 'pages/Login'
                }, router.RouterMode.Standard, (err) => {
                  if (err) {
                    console.error(`退出登录失败 code: ${err.code}, message: ${err.message}`);
                    promptAction.showToast({ message: '退出登录失败，请重试' });
                    return;
                  }
                  console.info('退出登录成功');
                });
              })
            }
            .width('90%')
            .margin({ bottom: 20 })
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#f5f5f5')
        }
        .tabBar({ text: '个人中心' })
      }
      .width('100%')
      .layoutWeight(1)
      .barHeight(60)
      .onChange((index: number) => {
        this.currentIndex = index;
        this.refreshData();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}