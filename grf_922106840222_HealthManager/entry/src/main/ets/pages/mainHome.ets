// MainHome.ets
import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';
import common from '@ohos.app.ability.common';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from '../common/HealthDataModel';
import Want from '@ohos.app.ability.Want'
import promptAction from '@ohos.promptAction';
import { HomeTabComponent } from './HomeTabComponent';
import { InputTabComponent } from './InputTabComponent';
import { SportsTabComponent } from './SportsTabComponent';
import { ProfileTabComponent } from './ProfileTabComponent';
import { RefreshDataFunc, ShareHealthDataFunc, UpdateStepChartFunc } from './FunctionInterfaces';

export const TAG: string = 'mainHome';

interface RouteParams {
  username?: string;
  userId?: number;
  newLogin?: boolean; // 检查是否是新用户登录
}

// 健康数据的接口
interface HealthData {
  userId: number;
  username: string;
  date: string;
  steps: number;
  heartRate: number;
  sleepHours: number;
  waterAmount: number;
}

// Define explicit type for Want parameters without indexed signature
interface WantParams {
  healthData?: string;
}

interface AbilityStartParams {
  bundleName: string;
  abilityName: string;
  moduleName?: string;
  parameters?: WantParams;
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

// 定义柱状图数据结构
interface ChartDataItem {
  label: string;
  value: number;
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

  // 需要添加这些新的状态变量到MainHome类中，用来进行多个数据的录入
  @State heartRateInputTimes: string[] = ['08:00']; // 默认添加一个时间
  @State heartRateInputValues: string[] = ['0']; // 默认添加一个心率值
  @State waterInputTimes: string[] = ['08:00']; // 默认添加一个时间
  @State waterInputValues: string[] = ['0']; // 默认添加一个饮水量值

  // 新增状态变量用于步数图表
  @State stepChartData: ChartDataItem[] = [];
  @State chartMode: string = '日'; // '日', '周', '月'
  @State dateRangeText: string = '';
  @State totalSteps: number = 0;
  @State avgDailySteps: number = 0;
  @State maxDisplayValue: number = 15000; // 图表纵坐标最大值

  // 函数接口实现
  refreshDataFunc: RefreshDataFunc = {
    refreshData: this.refreshData.bind(this)
  };

  shareHealthDataFunc: ShareHealthDataFunc = {
    shareHealthData: this.shareHealthData.bind(this)
  };

  updateStepChartFunc: UpdateStepChartFunc = {
    updateStepChartData: this.updateStepChartData.bind(this)
  };

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
        await this.loadHealthData();
        await this.updateStepChartData(); // 加载步数图表数据
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

  // 新增方法：更新步数图表数据
  async updateStepChartData() {
    try {
      let data: ChartDataItem[] = [];
      let total = 0;
      let dateDisplay = '';

      // Parse current date
      const currentDateObj = new Date(this.currentDate);

      switch (this.chartMode) {
        case '日':
          // Create 6 time slots for the day (every 4 hours)
          const timeSlots = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];

          // Get all step records for the day
          const dayStepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
          let dayTotalSteps = dayStepRecords.length > 0 ? dayStepRecords[0].steps : 0;
          total = dayTotalSteps;

          // Distribute steps across time slots based on typical activity patterns
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
          // Get start of week (Monday)
          const today = new Date(this.currentDate);
          const currentDayOfWeek = today.getDay() || 7; // Convert Sunday from 0 to 7
          const mondayOfWeek = new Date(today);
          mondayOfWeek.setDate(today.getDate() - currentDayOfWeek + 1);

          let weekTotal = 0;
          let dayCount = 0;

          // Get data for each day of the week
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
          // Get current month data
          const year = currentDateObj.getFullYear();
          const month = currentDateObj.getMonth();
          const daysInMonth = new Date(year, month + 1, 0).getDate();

          let monthTotal = 0;
          let activeDays = 0;

          // Only process first 15 days to avoid too many database calls
          const daysToShow = Math.min(daysInMonth, 15);

          for (let i = 1; i <= daysToShow; i++) {
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
          this.maxDisplayValue = Math.max(15000, Math.ceil(monthTotal / daysToShow) * 1.5);
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

  // 检查是否有通过Want接收到的数据 - 更新为Stage模式API
  async checkReceivedData() {
    try {
      // 在Stage模式中，通过abilityInfo获取传递的参数
      if (this.context && this.context.abilityInfo && this.context.abilityInfo.metadata) {
        const parameters = this.context.abilityInfo.metadata as MetadataParams;
        const healthDataParam = parameters.healthData;
        if (typeof healthDataParam === 'string') {
          this.receivedHealthData = healthDataParam;
          hilog.info(0x0000, TAG, `Received health data: ${this.receivedHealthData}`);

          // When new data is received, refresh our own data
          this.refreshData();
        }
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Error getting parameters: ${errorMessage}`);
    }
  }

  // 准备健康数据并通过Want分享 - 更新为Stage模式API
  async shareHealthData() {
    try {
      // Before sharing, refresh data to ensure it's up to date
      await this.refreshData();

      // 创建健康数据对象
      const healthData: HealthData = {
        userId: this.userId,
        username: this.username,
        date: this.currentDate,
        steps: this.steps,
        heartRate: this.heartRate,
        sleepHours: this.sleepHours,
        waterAmount: this.waterAmount
      };

      // 将数据转换为JSON字符串
      const dataString = JSON.stringify(healthData);
      const want: Want = {
        bundleName: 'com.example.target', // Replace with target app
        abilityName: 'EntryAbility',      // Replace with target ability
        moduleName: 'entry',              // Optional module name
        parameters: {                     // Use a plain object for parameters
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

  build() {
    Column() {
      // 标题和用户信息
      Row() {
        Text("个人健康管理系统")
          .fontSize(24)
          .fontColor('#1698CE')
          .fontWeight(FontWeight.Bold)

        Blank()

        // 显示当前登录用户名
        if (this.username) {
          Text(`欢迎，${this.username}`)
            .fontSize(18)
            .fontColor('#333')
        }
      }
      .width('90%')
      .height('10%')
      .padding({ top: 10, bottom: 10 })

      // 分割线
      Divider()
        .width('90%')
        .height(1)
        .backgroundColor('#ddd')

      // 主要内容区域
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          // 首页组件
          HomeTabComponent({
            username: $username,
            userId: $userId,
            steps: $steps,
            heartRate: $heartRate,
            sleepHours: $sleepHours,
            waterAmount: $waterAmount,
            waterRecords: $waterRecords,
            currentDate: $currentDate,
            receivedHealthData: $receivedHealthData,
            heartRateRecords: $heartRateRecords,
            lastUpdateTime: $lastUpdateTime,
            refreshDataFunc: this.refreshDataFunc,
            shareHealthDataFunc: this.shareHealthDataFunc
          })
        }
        .tabBar({ text: '首页' })

        // 数据输入页面
        TabContent() {
          // 数据输入组件
          InputTabComponent({
            username: $username,
            userId: $userId,
            steps: $steps,
            heartRate: $heartRate,
            sleepHours: $sleepHours,
            waterAmount: $waterAmount,
            currentDate: $currentDate,
            tempWaterAmount: $tempWaterAmount,
            heartRateInputTimes: $heartRateInputTimes,
            heartRateInputValues: $heartRateInputValues,
            waterInputTimes: $waterInputTimes,
            waterInputValues: $waterInputValues,
            dbHelper: this.dbHelper,
            refreshDataFunc: this.refreshDataFunc
          })
        }
        .tabBar({ text: '数据输入' })

        // 运动界面
        TabContent() {
          // 运动数据组件
          SportsTabComponent({
            username: $username,
            userId: $userId,
            currentDate: $currentDate,
            stepChartData: $stepChartData,
            chartMode: $chartMode,
            dateRangeText: $dateRangeText,
            totalSteps: $totalSteps,
            avgDailySteps: $avgDailySteps,
            maxDisplayValue: $maxDisplayValue,
            refreshDataFunc: this.refreshDataFunc,
            updateStepChartFunc: this.updateStepChartFunc
          })
        }
        .tabBar({ text: '我的运动' })

        // 个人中心页面
        TabContent() {
          // 个人中心组件
          ProfileTabComponent({
            username: $username,
            userId: $userId,
            refreshDataFunc: this.refreshDataFunc
          })
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