import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';
import common from '@ohos.app.ability.common';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from '../common/HealthDataModel';
import Want from '@ohos.app.ability.Want'
import promptAction from '@ohos.promptAction';
import { HeartRateInputDialog, StepInputDialog, WaterInputDialog } from './Dialog'
import reminderAgent from '@ohos.reminderAgentManager';
import { HealthDataCard, HeartRateRecordItem, WaterRecordItem, DataInputRow, StepRecordItem } from './myComponents'
import {
  ChartDataItem,
  HealthData,
  MetadataParams,
  RouteParams,
  RouterParams,
  StepTimeInput
} from './mainhomeInterface';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HomeTab } from './HomeTab';
import {DataInputTab} from './DataInputTab'
import {ProfileTab} from './ProfileTab'
import {MyMovementTab} from './MyMovementTab'
export const TAG: string = 'mainHome';
const DOMAIN_NUMBER: number = 0xFF00;

@Extend(Text)
function titleText() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .margin({ top: 10, bottom: 20 })
}

@Extend(Text)
function subtitleText() {
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .margin({ bottom: 10 })
}

@Extend(Text)
function labelText() {
  .fontSize(16)
  .fontColor('#666')
}

@Extend(Text)
function valueText() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
}

@Extend(Column)
function cardContainer() {
  .width('90%')
  .padding(15)
  .borderRadius(8)
  .backgroundColor('#f7f7f7')
  .margin({ bottom: 10 })
}

@Extend(Button)
function primaryButton() {
  .width('100%')
  .height(40)
  .backgroundColor('#27AE60')
  .margin({ bottom: 10 })
}

@Extend(Button)
function secondaryButton(bgColor: string = '#3498DB') {
  .width('100%')
  .height(40)
  .backgroundColor(bgColor)
  .margin({ bottom: 10 })
}

@Extend(Row)
function menuItem() {
  .width('100%')
  .padding(15)
  .backgroundColor('#ffffff')
  .borderRadius(8)
  .margin({ bottom: 10 })
}

@Entry
@Component
struct MainHome {
  private context = getContext(this) as common.UIAbilityContext;
  private hasNotified: boolean = false; // 用于记录是否已经发送过通知
  @State lastNotifiedSteps: number = 0; // 用于记录上次通知时的步数
  @State lastNotifyWater : number = 0; // 用于记录上次饮水量的饮水量
  @State username: string = ''; // 用户名
  @State userId: number = -1; // 用户Id,初始化为-1，用户Id从1开始
  @State steps: number = 0; //步数
  @State heartRate: number = 0; //心率
  @State sleepHours: number = 0; // 睡眠时间
  @State waterAmount: number = 0; // 饮水量
  @State waterRecords: WaterRecord[] = []; // 饮水记录
  @State currentDate: string = new Date().toISOString().split('T')[0]; // 当前时间
  @State receivedHealthData: string = ''; // 接收到的数据
  @State currentIndex: number = 0;
  @State isNewLogin: boolean = false; // 检查是否是新用户登录
  @State lastUpdateTime: number = 0; //记录上次更新时间，用来弹出系统通知
  @State tempWaterAmount: number = 0; // 记录输入的饮水数据
  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));
  private refreshInterval: number = 0; // For periodic refresh
  @State heartRateRecords: HeartRateRecord[] = []; //心率记录
  @State heartRateInputTimes: string[] = ['08:00']; // 默认添加一个时间
  @State heartRateInputValues: string[] = ['0']; // 默认添加一个心率值
  @State waterInputTimes: string[] = ['08:00']; // 默认添加一个时间
  @State waterInputValues: string[] = ['0']; // 默认添加一个饮水量值
  @State myWeight: number = 0; //体重
  @State myHeight: number = 0; // 身高
  @State bmi: number = 0; // bmi指数
  @State stepChartData: ChartDataItem[] = []; //步数柱状图日期
  @State chartMode: string = '日'; // '日', '周', '月'
  @State dateRangeText: string = '';
  @State totalSteps: number = 0; // 总步数
  @State avgDailySteps: number = 0; //日平均步数
  @State maxDisplayValue: number = 15000;  // 最大值，用于柱状图的纵坐标
  @State canvasContext: CanvasRenderingContext2D | null = null;
  @State selectedDate: Date = new Date(); //所选日期
  @State isCalendarVisible: boolean = false;
  @State isChartScrolling: boolean = false;
  @State isDateScrolling: boolean = false;
  @State currentOffset: number = 0;
  @State notificationSent: boolean = false; // 标记是否已发送通知
  @State stepInputTimes: string[] = ['08:00'];
  @State stepInputValues: string[] = ['0'];
  @State stepTimeRecords: StepRecord[] = [];
  @State message: string = '通知示例';
  @State userAvatarPath: string = ''; // 添加一个状态来保存用户头像路径

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

  private async checkNotificationPermission(): Promise<void> {
    try {
      hilog.info(DOMAIN_NUMBER, TAG, '正在检查通知权限...');

      // 获取通知权限状态
      const isNotificationEnabled = await notificationManager.isNotificationEnabled();
      hilog.info(DOMAIN_NUMBER, TAG, `通知权限状态: ${isNotificationEnabled}`);

      if (!isNotificationEnabled) {
        hilog.warn(DOMAIN_NUMBER, TAG, '通知权限未启用，请确保在设置中启用通知权限');
        // 提示用户去设置页面开启权限
        promptAction.showToast({
          message: '请在设置中开启通知权限以接收健康提醒'
        });
      } else {
        hilog.info(DOMAIN_NUMBER, TAG, '通知权限已启用');
        // 发送测试通知以验证通知功能
        this.sendTestNotification();
      }
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN_NUMBER, TAG, `权限检查失败: ${errMsg}`);
    }
  }

  private sendTestNotification(): void {
    try {
      // 创建通知内容
      let notificationRequest: notificationManager.NotificationRequest = {
        id: 0,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '健康管理系统',
            text: '通知功能已启用',
            additionalText: '您将收到健康相关提醒'
          }
        }
      };

      notificationManager.publish(notificationRequest, (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN_NUMBER, TAG, `测试通知发送失败. 错误码: ${err.code}, 错误信息: ${err.message}`);
          return;
        }
        hilog.info(DOMAIN_NUMBER, TAG, '测试通知发送成功');
      });
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN_NUMBER, TAG, `发送测试通知失败: ${errMsg}`);
    }
  }

 private  checkWaterAndNotify(waterAmount:number) : void {
   hilog.info(DOMAIN_NUMBER, TAG, `检查饮水总量通知条件: 当前饮水量=${waterAmount}, 上次饮水量=${this.lastNotifyWater}`);

   if (waterAmount >= 2000 && waterAmount !== this.lastNotifyWater) {
     hilog.info(DOMAIN_NUMBER, TAG, `饮水量已达到通知条件: ${waterAmount}ml >= 2000ml`);

     try {
       let notificationRequest: notificationManager.NotificationRequest = {
         id: 2,
         content: {
           notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
           normal: {
             title: '健康饮水提醒',
             text: `恭喜! 您今日的饮水量为${waterAmount}ml，已超过2000ml目标！`,
             additionalText: '继续保持健康生活方式!'
           }
         },
         isOngoing: false
       };

       // 使用单一API发送通知
       notificationManager.publish(notificationRequest, (err) => {
         if (err) {
           hilog.error(DOMAIN_NUMBER, TAG, `发送步数通知失败. 错误码: ${err.code}, 错误信息: ${err.message}`);
           return;
         }
         hilog.info(DOMAIN_NUMBER, TAG, `成功发送步数通知：当前步数 ${waterAmount}`);

         // 更新最后通知的步数
         this.lastNotifyWater = waterAmount;

         // 提示用户检查通知栏
         promptAction.showToast({
           message: '已发送步数达标通知，请检查通知栏'
         });
       });

     } catch (error) {
       const errMsg = error instanceof Error ? error.message : String(error);
       hilog.error(DOMAIN_NUMBER, TAG, `步数通知处理异常: ${errMsg}`);
     }
   } else {
     if (waterAmount < 8000) {
       hilog.info(DOMAIN_NUMBER, TAG, `饮水量未达到通知条件: ${waterAmount}ml < 2000ml`);
     } else if (waterAmount === this.lastNotifyWater) {
       hilog.info(DOMAIN_NUMBER, TAG, `已经为当前饮水量(${waterAmount})发送过通知，不重复发送`);
     }
   }
 }

  private checkStepsAndNotify(steps: number): void {
    hilog.info(DOMAIN_NUMBER, TAG, `检查步数通知条件: 当前步数=${steps}, 上次通知步数=${this.lastNotifiedSteps}`);

    if (steps >= 8000 && steps !== this.lastNotifiedSteps) {
      hilog.info(DOMAIN_NUMBER, TAG, `步数已达到通知条件: ${steps}步 >= 8000步`);

      try {
        let notificationRequest: notificationManager.NotificationRequest = {
          id: 1,
          content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
              title: '健康步数提醒',
              text: `恭喜! 您今日的步数为${steps}步，已超过8000步目标！`,
              additionalText: '继续保持健康生活方式!'
            }
          },
          isOngoing: false
        };

        // 使用单一API发送通知
        notificationManager.publish(notificationRequest, (err) => {
          if (err) {
            hilog.error(DOMAIN_NUMBER, TAG, `发送步数通知失败. 错误码: ${err.code}, 错误信息: ${err.message}`);
            return;
          }
          hilog.info(DOMAIN_NUMBER, TAG, `成功发送步数通知：当前步数 ${steps}`);

          // 更新最后通知的步数
          this.lastNotifiedSteps = steps;

          // 提示用户检查通知栏
          promptAction.showToast({
            message: '已发送步数达标通知，请检查通知栏'
          });
        });
      } catch (error) {
        const errMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN_NUMBER, TAG, `步数通知处理异常: ${errMsg}`);
      }
    } else {
      if (steps < 8000) {
        hilog.info(DOMAIN_NUMBER, TAG, `步数未达到通知条件: ${steps}步 < 8000步`);
      } else if (steps === this.lastNotifiedSteps) {
        hilog.info(DOMAIN_NUMBER, TAG, `已经为当前步数(${steps})发送过通知，不重复发送`);
      }
    }
  }
  // 在 MainHome 类的 aboutToAppear 方法中添加（仅开发测试使用！）
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
        this.lastNotifiedSteps = 0;
      }
    }
    // 设置当前日期
    this.currentDate = new Date().toISOString().split('T')[0];
    // 初始化
    this.initData().then(() => {
      this.checkNotificationPermission();
    });

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
    this.stepDialogController.close();
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
          this.userAvatarPath = userInfo.avatarPath || ''; // 保存用户头像路径
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
          this.stepTimeRecords = await this.dbHelper.getStepRecords(Number(stepRecords[0].id));
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
          this.userAvatarPath = userInfo.avatarPath || ''; // 更新用户头像路
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
      // 获取当日步数记录
      const stepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
      this.stepTimeRecords = stepRecords; // 直接使用stepRecords

      // 计算总步数
      this.totalSteps = stepRecords.reduce((sum, record) => sum + record.steps, 0);

      if (stepRecords.length > 0) {
        // 显示最近一条记录的步数
        this.steps = stepRecords[stepRecords.length - 1].steps;
      } else {
        this.steps = 0;
        this.totalSteps = 0;
      }

      // 检查步数是否达到8000并发送通知
      this.checkStepsAndNotify(this.totalSteps);

      // 其他健康数据加载保持不变...
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
          // 使用步数时间记录计算今日总步数
          total = this.totalSteps; // 使用已计算好的今日总步数

          // 使用时间段分布数据
          const timeSlots = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];

          if (this.stepTimeRecords.length > 0) {
            const slotData: number[] = new Array(timeSlots.length).fill(0);

            for (const record of this.stepTimeRecords) {
              const recordHour = parseInt(record.time.split(':')[0]);
              let slotIndex = 0;

              // 确定记录属于哪个时间段
              for (let i = 1; i < timeSlots.length; i++) {
                const slotHour = parseInt(timeSlots[i].split(':')[0]);
                if (recordHour < slotHour) {
                  break;
                }
                slotIndex = i;
              }

              slotData[slotIndex] += record.steps;
            }

            // 创建图表数据
            for (let i = 0; i < timeSlots.length; i++) {
              data.push({
                label: timeSlots[i],
                value: slotData[i]
              });
            }
          } else {
            // 如果没有详细时间记录，使用默认分布
            const hourlyDistribution = [0.05, 0.05, 0.15, 0.30, 0.35, 0.10]; // 分布百分比

            for (let i = 0; i < timeSlots.length; i++) {
              const slotSteps = Math.round(total * hourlyDistribution[i]);
              data.push({
                label: timeSlots[i],
                value: slotSteps
              });
            }
          }

          this.maxDisplayValue = Math.max(15000, total * 0.4);
          dateDisplay = this.currentDate;
          this.avgDailySteps = total;
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
            if (daySteps > 0) {
              dayCount++;
            }
          }

          total = weekTotal;
          this.maxDisplayValue = Math.max(15000, Math.ceil(weekTotal / 7) * 1.5);

          const endOfWeek = new Date(mondayOfWeek);
          endOfWeek.setDate(mondayOfWeek.getDate() + 6);
          dateDisplay = `${mondayOfWeek.getFullYear()}年${mondayOfWeek.getMonth() +
            1}月${mondayOfWeek.getDate()}日至${endOfWeek.getDate()}日`;
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
            if (daySteps > 0) {
              activeDays++;
            }
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

  // async checkReceivedData() {
  //   try {
  //     if (this.context && this.context.abilityInfo && this.context.abilityInfo.metadata) {
  //       const parameters = this.context.abilityInfo.metadata as MetadataParams;
  //       const healthDataParam = parameters.healthData;
  //       if (typeof healthDataParam === 'string') {
  //         this.receivedHealthData = healthDataParam;
  //         hilog.info(0x0000, TAG, `Received health data: ${this.receivedHealthData}`);
  //
  //         this.refreshData();
  //       }
  //     }
  //   } catch (error) {
  //     const errorMessage: string = error instanceof Error ? error.message : String(error);
  //     hilog.error(0x0000, TAG, `Error getting parameters: ${errorMessage}`);
  //   }
  // }

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
        this.checkWaterAndNotify(this.waterAmount);
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

  // mainHome.ets 中修改saveMultiStepRecords方法
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
          this.checkStepsAndNotify(totalSteps);
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

      // 主要内容区域 - 使用抽离的组件
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          HomeTab({
            username: $username,
            userId: $userId,
            totalSteps: $totalSteps,
            heartRate: $heartRate,
            sleepHours: $sleepHours,
            waterAmount: $waterAmount,
            currentDate: $currentDate,
            receivedHealthData: $receivedHealthData,
            heartRateRecords: $heartRateRecords,
            waterRecords: $waterRecords,
            steps: $steps,
            refreshData: this.refreshData.bind(this),
            shareHealthData: this.shareHealthData.bind(this),
            ClickJumpToShowData: this.ClickJumpToShowData.bind(this)
          })
        }
        .tabBar({ text: '首页' })

        TabContent() {
          DataInputTab({
            userId: $userId,
            username: $username,
            currentDate: $currentDate,
            totalSteps: $totalSteps,
            steps: $steps,
            heartRate: $heartRate,
            sleepHours: $sleepHours,
            waterAmount: $waterAmount,
            tempWaterAmount: $tempWaterAmount,
            lastNotifiedSteps: $lastNotifiedSteps,
            lastNotifyWater: $lastNotifyWater,
            heartRateInputTimes: $heartRateInputTimes,
            heartRateInputValues: $heartRateInputValues,
            waterInputTimes: $waterInputTimes,
            waterInputValues: $waterInputValues,
            stepInputTimes: $stepInputTimes,
            stepInputValues: $stepInputValues,
            dbHelper: this.dbHelper,
            refreshData: this.refreshData.bind(this),
            checkStepsAndNotify: this.checkStepsAndNotify.bind(this),
            checkWaterAndNotify: this.checkWaterAndNotify.bind(this),
            heartRateDialogController: this.heartRateDialogController,
            waterDialogController: this.waterDialogController,
            stepDialogController: this.stepDialogController
          })
        }
        .tabBar({ text: '数据输入' })

        TabContent() {
          MyMovementTab({
            username: $username,
            userId: $userId,
            stepChartData: $stepChartData,
            chartMode: $chartMode,
            dateRangeText: $dateRangeText,
            totalSteps: $totalSteps,
            avgDailySteps: $avgDailySteps,
            maxDisplayValue: $maxDisplayValue,
            stepTimeRecords: $stepTimeRecords,
            myWeight: $myWeight,
            myHeight: $myHeight,
            bmi: $bmi,
            refreshData: this.refreshData.bind(this),
            updateStepChartData: this.updateStepChartData.bind(this)
          })
        }
        .tabBar({ text: '我的运动' })

        TabContent() {
          ProfileTab({
            username: $username,
            userId: $userId,
            userAvatarPath: $userAvatarPath,
            ClickJumpToShowData: this.ClickJumpToShowData.bind(this)
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