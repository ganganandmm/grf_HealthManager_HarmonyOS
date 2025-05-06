import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';
import common from '@ohos.app.ability.common';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { StepRecord, HeartRateRecord, WaterRecord } from '../common/HealthDataModel';
import Want from '@ohos.app.ability.Want'
import promptAction from '@ohos.promptAction';
import { HeartRateInputDialog, StepInputDialog, WaterInputDialog } from './Dialog'
import {
  ChartDataItem,
  HealthData, RouteParams,
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

// 定义可复用的文本样式
@Extend(Text) function titleTextStyle() {
  .fontSize(24)
  .fontColor('#1698CE')
  .fontWeight(FontWeight.Bold)
}

@Extend(Text) function regularTextStyle() {
  .fontSize(18)
  .fontColor('#333')
}


@Styles function mainContainerStyle() {
  .width('100%')
  .height('100%')
  .backgroundColor('#f5f5f5')
}

@Styles function headerRowStyle() {
  .width('90%')
  .height('10%')
  .padding({ top: 10, bottom: 10 })
}


// 定义可复用的分隔线样式
@Styles function standardDividerStyle() {
  .width('90%')
  .height(1)
  .backgroundColor('#ddd')
}

// 定义可复用的Tab样式
@Styles function mainTabsStyle() {
  .width('100%')
  .layoutWeight(1)
  .height(60)
}

@Entry
@Component
struct MainHome {
  // 获取UI上下文，用于应用内操作
  private context = getContext(this) as common.UIAbilityContext;
  private hasNotified: boolean = false; // 用于记录是否已经发送过通知
  @State lastNotifiedSteps: number = 0; // 用于记录上次通知时的步数
  @State lastNotifyWater : number = 0; // 用于记录上次饮水量的饮水量
  @State lastNotifySleep : number = 0; // 用于记录上次通知的睡眠时长
  @State username: string = ''; // 用户名
  @State userId: number = -1; // 用户Id,初始化为-1，用户Id从1开始
  @State steps: number = 0; //步数
  @State heartRate: number = 0; //心率
  @State sleepHours: number = 0; // 睡眠时间
  @State waterAmount: number = 0; // 饮水量
  @State waterRecords: WaterRecord[] = []; // 饮水记录
  @State currentDate: string = new Date().toISOString().split('T')[0]; // 当前时间
  @State receivedHealthData: string = ''; // 接收到的数据
  @State currentIndex: number = 0; // 当前选中的Tab索引
  @State isNewLogin: boolean = false; // 检查是否是新用户登录
  @State lastUpdateTime: number = 0; //记录上次更新时间，用来弹出系统通知
  @State tempWaterAmount: number = 0; // 记录输入的饮水数据
  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this)); // 数据库操作辅助实例
  private refreshInterval: number = 0; // 用于周期性刷新的定时器ID
  @State heartRateRecords: HeartRateRecord[] = []; //心率记录
  @State heartRateInputTimes: string[] = ['08:00']; // 默认添加一个时间
  @State heartRateInputValues: string[] = ['0']; // 默认添加一个心率值
  @State waterInputTimes: string[] = ['08:00']; // 默认添加一个时间
  @State waterInputValues: string[] = ['0']; // 默认添加一个饮水量值
  @State myWeight: number = 0; //体重
  @State myHeight: number = 0; // 身高
  @State bmi: number = 0; // bmi指数
  @State stepChartData: ChartDataItem[] = []; //步数柱状图数据
  @State chartMode: string = '日'; // 图表模式：'日', '周', '月'
  @State dateRangeText: string = ''; // 图表所展示的日期范围文本
  @State totalSteps: number = 0; // 总步数
  @State avgDailySteps: number = 0; //日平均步数
  @State maxDisplayValue: number = 15000;  // 最大值，用于柱状图的纵坐标
  @State canvasContext: CanvasRenderingContext2D | null = null; // 画布上下文，用于绘制图表
  @State selectedDate: Date = new Date(); //所选日期
  @State isCalendarVisible: boolean = false; // 日历组件是否可见
  @State isChartScrolling: boolean = false; // 图表是否正在滚动
  @State isDateScrolling: boolean = false; // 日期选择器是否正在滚动
  @State currentOffset: number = 0; // 当前滚动偏移量
  @State notificationSent: boolean = false; // 标记是否已发送通知
  @State stepInputTimes: string[] = ['08:00']; // 步数输入时间初始值
  @State stepInputValues: string[] = ['0']; // 步数输入值初始值
  @State stepTimeRecords: StepRecord[] = []; // 步数时间记录
  @State message: string = '通知示例'; // 通知消息内容
  @State userAvatarPath: string = ''; // 添加一个状态来保存用户头像路径

  // 心率输入对话框控制器
  heartRateDialogController: CustomDialogController = new CustomDialogController({
    builder: HeartRateInputDialog({
      heartRateInputTimes: this.heartRateInputTimes,
      heartRateInputValues: this.heartRateInputValues,
      addHeartRateInputRow: this.addHeartRateInputRow.bind(this),
      removeHeartRateInputRow: this.removeHeartRateInputRow.bind(this),
      saveMultiHeartRates: this.saveMultiHeartRates.bind(this)
    }),
    autoCancel: false, // 不自动关闭对话框
    alignment: DialogAlignment.Center, // 对话框居中显示
    customStyle: true // 使用自定义样式
  });

  // 饮水记录输入对话框控制器
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

  // 步数输入对话框控制器
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

  /**
   * 检查通知权限方法
   * 检查应用是否有发送通知的权限，若没有则提示用户开启
   * @returns {Promise<void>} 无返回值的Promise
   */
  private async checkNotificationPermission(): Promise<void> {
    try {
      hilog.info(DOMAIN_NUMBER, TAG, '正在检查通知权限...');

      // 获取通知权限状态
      const isNotificationEnabled = await notificationManager.isNotificationEnabled();
      hilog.info(DOMAIN_NUMBER, TAG, `通知权限状态: ${isNotificationEnabled}`);

      if (!isNotificationEnabled) {
        // 通知权限未开启，提示用户
        hilog.warn(DOMAIN_NUMBER, TAG, '通知权限未启用，请确保在设置中启用通知权限');
        // 提示用户去设置页面开启权限
        promptAction.showToast({
          message: '请在设置中开启通知权限以接收健康提醒'
        });
      } else {
        // 通知权限已开启，记录日志
        hilog.info(DOMAIN_NUMBER, TAG, '通知权限已启用');
        // 发送测试通知验证功能
        this.sendTestNotification();
      }
    } catch (error) {
      // 捕获权限检查可能出现的错误并记录日志
      const errMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN_NUMBER, TAG, `权限检查失败: ${errMsg}`);
    }
  }

  /**
   * 发送测试通知方法
   * 用于验证通知功能是否正常工作
   */
  private sendTestNotification(): void {
    try {
      // 创建通知内容
      let notificationRequest: notificationManager.NotificationRequest = {
        id: 0, // 通知ID
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 基本文本通知类型
          normal: {
            title: '健康管理系统', // 通知标题
            text: '通知功能已启用', // 通知内容
            additionalText: '您将收到健康相关提醒' // 通知附加内容
          }
        }
      };

      // 发布通知并处理回调
      notificationManager.publish(notificationRequest, (err: BusinessError) => {
        if (err) {
          // 发送失败，记录错误日志
          hilog.error(DOMAIN_NUMBER, TAG, `测试通知发送失败. 错误码: ${err.code}, 错误信息: ${err.message}`);
          return;
        }
        // 发送成功，记录日志
        hilog.info(DOMAIN_NUMBER, TAG, '测试通知发送成功');
      });
    } catch (error) {
      // 捕获可能出现的异常并记录日志
      const errMsg = error instanceof Error ? error.message : String(error);
      hilog.error(DOMAIN_NUMBER, TAG, `发送测试通知失败: ${errMsg}`);
    }
  }

  /**
   * 检查饮水量并发送通知方法
   * 当饮水量达到目标时触发通知
   * @param waterAmount 当前饮水量（毫升）
   */
  private checkWaterAndNotify(waterAmount:number) : void {
    // 记录当前饮水量检查信息
    hilog.info(DOMAIN_NUMBER, TAG, `检查饮水总量通知条件: 当前饮水量=${waterAmount}, 上次饮水量=${this.lastNotifyWater}`);

    // 饮水量达到2000ml且与上次通知的饮水量不同时发送通知
    if (waterAmount >= 2000 && waterAmount !== this.lastNotifyWater) {
      hilog.info(DOMAIN_NUMBER, TAG, `饮水量已达到通知条件: ${waterAmount}ml >= 2000ml`);

      try {
        // 创建饮水达标通知请求
        let notificationRequest: notificationManager.NotificationRequest = {
          id: 2, // 通知ID，与其他通知区分
          content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
              title: '健康饮水提醒', // 通知标题
              text: `恭喜! 您今日的饮水量为${waterAmount}ml，已超过2000ml目标！`, // 通知正文
              additionalText: '继续保持健康生活方式!' // 通知附加文本
            }
          },
          isOngoing: false // 非持续性通知
        };

        // 发送通知
        notificationManager.publish(notificationRequest, (err) => {
          if (err) {
            // 发送失败，记录错误信息
            hilog.error(DOMAIN_NUMBER, TAG, `发送步数通知失败. 错误码: ${err.code}, 错误信息: ${err.message}`);
            return;
          }
          // 发送成功，记录日志并更新最后通知的饮水量
          hilog.info(DOMAIN_NUMBER, TAG, `成功发送步数通知：当前步数 ${waterAmount}`);
          this.lastNotifyWater = waterAmount;

          // 提示用户查看通知
          promptAction.showToast({
            message: '已发送步数达标通知，请检查通知栏'
          });
        });

      } catch (error) {
        // 异常处理
        const errMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN_NUMBER, TAG, `步数通知处理异常: ${errMsg}`);
      }
    } else {
      // 记录未达到通知条件的原因
      if (waterAmount < 8000) {
        hilog.info(DOMAIN_NUMBER, TAG, `饮水量未达到通知条件: ${waterAmount}ml < 2000ml`);
      } else if (waterAmount === this.lastNotifyWater) {
        hilog.info(DOMAIN_NUMBER, TAG, `已经为当前饮水量(${waterAmount})发送过通知，不重复发送`);
      }
    }
  }

  /**
   * 检查睡眠时长并发送通知方法
   * 根据睡眠时长发送不同类型的通知：达标通知或不足警告
   * @param sleepHours 睡眠时长（小时）
   */
  private checkSleepAndNotify(sleepHours: number): void {
    // 记录当前睡眠时长检查信息
    hilog.info(DOMAIN_NUMBER, TAG, `检查睡眠时长通知条件: 当前睡眠时长=${sleepHours}, 上次睡眠时长=${this.lastNotifySleep}`);

    // 条件1：睡眠时长达标（≥8小时）且与上次通知的时长不同
    if (sleepHours >= 8.0 && sleepHours !== this.lastNotifySleep) {
      // 记录睡眠达标日志
      hilog.info(DOMAIN_NUMBER, TAG, `睡眠时长已达标: ${sleepHours}小时 >= 8小时`);

      try {
        // 创建睡眠达标通知
        let notificationRequest: notificationManager.NotificationRequest = {
          id: 3,  // 通知ID，与其他通知区分
          content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
              title: '健康睡眠提醒',  // 通知标题
              text: `恭喜! 您今日的总睡眠时长为${sleepHours}小时，已超过8小时目标！`,  // 通知内容
              additionalText: '继续保持健康生活方式!'  // 通知附加内容
            }
          },
          isOngoing: false  // 非持续性通知
        };

        // 发送通知
        notificationManager.publish(notificationRequest, (err) => {
          if (err) {
            // 发送失败，记录错误信息
            hilog.error(DOMAIN_NUMBER, TAG, `发送睡眠通知失败. 错误码: ${err.code}, 错误信息: ${err.message}`);
            return;
          }

          // 发送成功，记录日志并更新最后通知的睡眠时长
          hilog.info(DOMAIN_NUMBER, TAG, `成功发送睡眠通知：当前睡眠时长 ${sleepHours}`);
          this.lastNotifySleep = sleepHours;

          // 提示用户查看通知
          promptAction.showToast({
            message: '已发送睡眠达标通知，请检查通知栏'  // 注意：原代码显示"步数达标通知"，应改为"睡眠达标通知"
          });
        });

      } catch (error) {
        // 异常处理
        const errMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN_NUMBER, TAG, `通知处理异常: ${errMsg}`);
      }
    }
    // 条件2：睡眠时长不足（≤6小时）且与上次通知的时长不同
    else if (sleepHours <= 6.0 && sleepHours !== this.lastNotifySleep) {
      try {
        // 创建睡眠不足警告通知
        let notificationRequest1: notificationManager.NotificationRequest = {
          id: 4,  // 不同的ID以区分不同类型的通知
          content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
              title: '健康睡眠提醒',  // 通知标题
              text: `注意! 您今日的总睡眠时长为${sleepHours}小时，请注意休息时间！`,  // 警告内容
              additionalText: '请保持健康生活方式!'  // 建议内容
            }
          },
          isOngoing: false  // 非持续性通知
        };

        // 发送通知
        notificationManager.publish(notificationRequest1, (err) => {
          if (err) {
            // 发送失败，记录错误信息
            hilog.error(DOMAIN_NUMBER, TAG, `发送睡眠通知失败. 错误码: ${err.code}, 错误信息: ${err.message}`);
            return;
          }

          // 发送成功，记录日志并更新最后通知的睡眠时长
          hilog.info(DOMAIN_NUMBER, TAG, `成功发送通知：当前睡眠时长 ${sleepHours}`);
          this.lastNotifySleep = sleepHours;

          // 提示用户查看通知
          promptAction.showToast({
            message: '已发送步数达标通知，请检查通知栏'  // 注意：原代码显示"步数达标通知"，应改为"睡眠不足通知"
          });
        });

      } catch (error) {
        // 异常处理
        const errMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN_NUMBER, TAG, `通知处理异常: ${errMsg}`);
      }
    }
    // 条件3：不满足发送通知的条件
    else {
      // 睡眠时长在6-8小时之间，记录日志
      if (sleepHours > 6.0 && sleepHours < 8.0) {
        hilog.info(DOMAIN_NUMBER, TAG, `时长未达到通知条件: ${sleepHours}小时 < 8小时`);
      }
      // 当前睡眠时长与上次通知的时长相同，避免重复通知
      else if (sleepHours === this.lastNotifySleep) {
        hilog.info(DOMAIN_NUMBER, TAG, `已经为当前时长(${sleepHours})发送过通知，不重复发送`);
      }
    }
  }

  /**
   * 检查步数并发送通知方法
   * 当步数达到目标时触发通知
   * @param steps 当前步数
   */
  private checkStepsAndNotify(steps: number): void {
    // 记录当前步数检查信息
    hilog.info(DOMAIN_NUMBER, TAG, `检查步数通知条件: 当前步数=${steps}, 上次通知步数=${this.lastNotifiedSteps}`);

    // 步数达到8000且与上次通知的步数不同时发送通知
    if (steps >= 8000 && steps !== this.lastNotifiedSteps) {
      hilog.info(DOMAIN_NUMBER, TAG, `步数已达到通知条件: ${steps}步 >= 8000步`);

      try {
        // 创建步数达标通知请求
        let notificationRequest: notificationManager.NotificationRequest = {
          id: 1, // 通知ID
          content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
              title: '健康步数提醒', // 通知标题
              text: `恭喜! 您今日的步数为${steps}步，已超过8000步目标！`, // 通知内容
              additionalText: '继续保持健康生活方式!' // 通知附加内容
            }
          },
          isOngoing: false // 非持续性通知
        };

        // 发送通知
        notificationManager.publish(notificationRequest, (err) => {
          if (err) {
            // 发送失败，记录错误信息
            hilog.error(DOMAIN_NUMBER, TAG, `发送步数通知失败. 错误码: ${err.code}, 错误信息: ${err.message}`);
            return;
          }
          // 发送成功，记录日志并更新最后通知的步数
          hilog.info(DOMAIN_NUMBER, TAG, `成功发送步数通知：当前步数 ${steps}`);
          this.lastNotifiedSteps = steps;

          // 提示用户查看通知
          promptAction.showToast({
            message: '已发送步数达标通知，请检查通知栏'
          });
        });
      } catch (error) {
        // 异常处理
        const errMsg = error instanceof Error ? error.message : String(error);
        hilog.error(DOMAIN_NUMBER, TAG, `步数通知处理异常: ${errMsg}`);
      }
    } else {
      // 记录未达到通知条件的原因
      if (steps < 8000) {
        hilog.info(DOMAIN_NUMBER, TAG, `步数未达到通知条件: ${steps}步 < 8000步`);
      } else if (steps === this.lastNotifiedSteps) {
        hilog.info(DOMAIN_NUMBER, TAG, `已经为当前步数(${steps})发送过通知，不重复发送`);
      }
    }
  }

  /**
   * 组件将要出现时的生命周期钩子
   * 执行初始化操作和设置定时刷新
   */
  aboutToAppear() {
    // 获取路由参数，包含用户信息
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

    // 初始化数据并检查通知权限
    this.initData().then(() => {
      this.checkNotificationPermission();
    });

    // 设置定时刷新，每30秒刷新一次数据
    this.refreshInterval = setInterval(() => {
      this.refreshData();
    }, 30000); // 30秒
  }

  /**
   * 组件将要消失时的生命周期钩子
   * 执行清理操作，释放资源
   */
  aboutToDisappear() {
    // 清除定时器
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }

    // 关闭数据库连接
    this.dbHelper.closeDatabase();

    // 关闭各种对话框控制器
    this.heartRateDialogController.close();
    this.waterDialogController.close();
    this.stepDialogController.close();
  }

  /**
   * 初始化应用数据
   * 加载用户信息、健康数据和图表数据
   * @returns {Promise<void>} 无返回值的Promise
   */
  async initData() {
    try {
      // 初始化数据库
      await this.dbHelper.initDatabase();

      // 根据用户名查询用户ID（如果未设置）
      if (this.userId < 0 && this.username) {
        const users = await this.dbHelper.queryUserByUsername(this.username);
        if (users.length > 0) {
          this.userId = users[0].id || -1;
        }
      }

      // 用户ID有效时加载用户信息和健康数据
      if (this.userId > 0) {
        // 获取用户个人信息（身高、体重和头像）
        const userInfo = await this.dbHelper.getUserById(this.userId);
        if (userInfo) {
          this.myHeight = userInfo.height || 0;
          this.myWeight = userInfo.weight || 0;
          this.userAvatarPath = userInfo.avatarPath || '';

          // 计算BMI指数
          if (this.myHeight > 0 && this.myWeight > 0) {
            this.bmi = this.myWeight / Math.pow(this.myHeight / 100, 2);
          }
        }

        // 加载健康数据和步数图表数据
        await this.loadHealthData();
        await this.updateStepChartData();
      }

      // 获取当天的步数记录
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

      // 重置新登录标志
      this.isNewLogin = false;
    } catch (error) {
      // 处理初始化过程中的错误
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to initialize data: ${errorMessage}`);
    }
  }

  /**
   * 刷新应用数据
   * 更新用户信息和健康数据
   * @returns {Promise<void>} 无返回值的Promise
   */
  async refreshData() {
    try {
      hilog.info(0x0000, TAG, 'Checking for data updates');

      // 用户ID有效时刷新数据
      if (this.userId > 0) {
        // 获取最新的用户信息
        const userInfo = await this.dbHelper.getUserById(this.userId);
        if (userInfo) {
          this.myHeight = userInfo.height || 0;
          this.myWeight = userInfo.weight || 0;
          this.userAvatarPath = userInfo.avatarPath || '';

          // 重新计算BMI指数
          if (this.myHeight > 0 && this.myWeight > 0) {
            this.bmi = this.myWeight / Math.pow(this.myHeight / 100, 2);
          }
        }

        // 刷新健康数据和图表数据
        await this.loadHealthData();
        await this.updateStepChartData(true); // 强制刷新图表数据
      }
    } catch (error) {
      // 捕获并处理刷新过程中的错误
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to refresh data: ${errorMessage}`);
    }
  }

  /**
   * 加载健康数据方法
   * 从数据库获取最新的健康数据并更新界面
   * @returns {Promise<void>} 无返回值的Promise
   */
  async loadHealthData() {
    try {
      // 获取当日步数记录
      const stepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
      this.stepTimeRecords = stepRecords; // 直接使用stepRecords作为时间记录

      // 计算总步数（累加所有记录的步数）
      this.totalSteps = stepRecords.reduce((sum, record) => sum + record.steps, 0);

      if (stepRecords.length > 0) {
        // 使用最近一条记录的步数
        this.steps = stepRecords[stepRecords.length - 1].steps;
      } else {
        // 无记录时步数为0
        this.steps = 0;
        this.totalSteps = 0;
      }

      // 检查步数是否达到8000并发送通知
      this.checkStepsAndNotify(this.totalSteps);

      // 获取心率记录
      const heartRateRecords = await this.dbHelper.getHeartRateRecords(this.userId, this.currentDate);
      this.heartRateRecords = heartRateRecords;

      if (heartRateRecords.length > 0) {
        // 使用最近一条记录的心率
        this.heartRate = heartRateRecords[heartRateRecords.length - 1].rate;
      } else {
        this.heartRate = 0;
      }

      // 获取睡眠记录
      const sleepRecords = await this.dbHelper.getSleepRecords(this.userId, this.currentDate);
      if (sleepRecords.length > 0) {
        // 计算睡眠小时数（睡眠时长记录单位为分钟）
        this.sleepHours = sleepRecords[0].duration / 60;
      } else {
        this.sleepHours = 0;
      }

      // 检查睡眠时长是否达标并发送通知
      this.checkSleepAndNotify(this.sleepHours);

      // 获取饮水记录
      const waterRecords = await this.dbHelper.getWaterRecords(this.userId, this.currentDate);
      this.waterRecords = waterRecords;

      // 计算总饮水量（累加所有记录的饮水量）
      this.waterAmount = waterRecords.reduce((total, record) => total + record.amount, 0);

      // 更新最后数据刷新时间
      this.lastUpdateTime = Date.now();
      hilog.info(0x0000, TAG, 'Health data loaded successfully');
    } catch (error) {
      // 捕获并处理加载健康数据过程中的错误
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to load health data: ${errorMessage}`);
    }
  }
  /**
   * 异步方法：更新步数图表数据
   * 根据选择的图表模式（日/周/月）处理相应的步数数据
   * @param forceRefresh 是否强制刷新数据，默认为false
   */
  async updateStepChartData(forceRefresh: boolean = false) {
    try {
      let data: ChartDataItem[] = [];      // 初始化图表数据数组
      let total = 0;                       // 初始化总步数
      let dateDisplay = '';                // 初始化日期显示文本

      const currentDateObj = new Date(this.currentDate); // 创建当前日期对象

      // 根据不同的图表模式处理数据
      switch (this.chartMode) {
        case '日':
          // 日视图: 显示一天内不同时间段的步数分布

          total = this.totalSteps; // 使用已计算好的今日总步数

          // 定义一天中的6个时间段
          const timeSlots = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00'];

          if (this.stepTimeRecords.length > 0) {
            // 如果有详细的时间步数记录，按时间段汇总
            const slotData: number[] = new Array(timeSlots.length).fill(0); // 初始化每个时间段的步数为0

            // 遍历所有步数记录，将其归类到对应的时间段
            for (const record of this.stepTimeRecords) {
              const recordHour = parseInt(record.time.split(':')[0]); // 获取记录的小时
              let slotIndex = 0; // 初始化时间段索引

              // 确定记录属于哪个时间段
              for (let i = 1; i < timeSlots.length; i++) {
                const slotHour = parseInt(timeSlots[i].split(':')[0]); // 获取时间段的小时
                if (recordHour < slotHour) {
                  // 找到第一个大于记录小时的时间段，则记录属于前一个时间段
                  break;
                }
                slotIndex = i; // 更新时间段索引
              }

              slotData[slotIndex] += record.steps; // 累加该时间段的步数
            }

            // 创建图表数据项
            for (let i = 0; i < timeSlots.length; i++) {
              data.push({
                label: timeSlots[i],    // 时间段标签
                value: slotData[i]      // 该时间段的步数
              });
            }
          } else {
            // 如果没有详细时间记录，使用默认的时间分布比例
            // 定义各时间段占总步数的百分比
            const hourlyDistribution = [0.05, 0.05, 0.15, 0.30, 0.35, 0.10];

            // 根据分布比例计算每个时间段的步数
            for (let i = 0; i < timeSlots.length; i++) {
              const slotSteps = Math.round(total * hourlyDistribution[i]); // 根据分布比例计算步数
              data.push({
                label: timeSlots[i],
                value: slotSteps
              });
            }
          }

          // 设置Y轴最大显示值，取15000和总步数40%中的较大值
          this.maxDisplayValue = Math.max(15000, total * 0.4);
          dateDisplay = this.currentDate; // 设置日期显示文本为当前日期
          this.avgDailySteps = total;    // 日视图的平均步数即为总步数
          break;

        case '周':
          // 周视图: 显示一周内每天的步数

          const today = new Date(this.currentDate); // 获取当前日期
          const currentDayOfWeek = today.getDay() || 7; // 获取星期几(0-6)，将周日的0转换为7
          const mondayOfWeek = new Date(today); // 创建本周一的日期
          mondayOfWeek.setDate(today.getDate() - currentDayOfWeek + 1); // 设置为本周的周一

          let weekTotal = 0; // 初始化周总步数
          let dayCount = 0;  // 初始化有步数记录的天数

          // 记录日志，表示正在更新周数据
          hilog.info(DOMAIN_NUMBER, TAG, `更新周视图数据, 强制刷新: ${forceRefresh}`);

          // 清空数据数组，确保完全刷新
          data = [];

          // 遍历周一到周日的7天
          for (let i = 0; i < 7; i++) {
            // 创建当天的日期对象
            const date = new Date(mondayOfWeek);
            date.setDate(mondayOfWeek.getDate() + i);
            // 格式化日期为YYYY-MM-DD格式
            const dateStr = date.toISOString().split('T')[0];

            // 记录日志，表示正在获取特定日期的步数数据
            hilog.info(DOMAIN_NUMBER, TAG, `获取日期 ${dateStr} 的步数数据`);
            // 从数据库获取该日期的步数记录，确保获取最新数据
            const stepRecords = await this.dbHelper.getStepRecords(this.userId, dateStr);

            // 计算该日的总步数（累加所有记录的步数）
            const daySteps = stepRecords.reduce((sum, record) => sum + record.steps, 0);
            // 记录日志，显示计算出的总步数
            hilog.info(DOMAIN_NUMBER, TAG, `${dateStr} 的总步数: ${daySteps}`);

            // 添加图表数据项，标签为"月/日"格式
            data.push({
              label: `${date.getMonth() + 1}/${date.getDate()}`, // 月/日格式的标签
              value: daySteps                                    // 该日的总步数
            });

            weekTotal += daySteps; // 累加到周总步数
            if (daySteps > 0) {
              dayCount++;          // 如果当天有步数，有效天数+1
            }
          }

          total = weekTotal; // 设置总步数为周总步数
          // 设置Y轴最大显示值，取15000和(周平均步数*1.5)中的较大值
          this.maxDisplayValue = Math.max(15000, Math.ceil(weekTotal / 7) * 1.5);

          // 计算本周结束日期（周日）
          const endOfWeek = new Date(mondayOfWeek);
          endOfWeek.setDate(mondayOfWeek.getDate() + 6);

          // 设置日期范围显示文本，格式为"YYYY年MM月DD日至DD日"
          dateDisplay = `${mondayOfWeek.getFullYear()}年${mondayOfWeek.getMonth() +
            1}月${mondayOfWeek.getDate()}日至${endOfWeek.getDate()}日`;

          // 计算平均每日步数（只计算有步数记录的天数）
          this.avgDailySteps = dayCount > 0 ? Math.round(weekTotal / dayCount) : 0;

          // 记录日志，表示周数据更新完成
          hilog.info(DOMAIN_NUMBER, TAG, `周视图数据更新完成: 总步数=${total}, 平均步数=${this.avgDailySteps}`);
          break;

        case '月':
          // 月视图: 显示一个月内每天的步数

          const year = currentDateObj.getFullYear();  // 获取年份
          const month = currentDateObj.getMonth();    // 获取月份（0-11）
          // 计算当月的天数（创建下月第0天，即当月最后一天）
          const daysInMonth = new Date(year, month + 1, 0).getDate();

          let monthTotal = 0; // 初始化月总步数
          let activeDays = 0; // 初始化有步数记录的天数

          // 记录日志，表示正在更新月数据
          hilog.info(DOMAIN_NUMBER, TAG, `更新月视图数据, 强制刷新: ${forceRefresh}`);

          // 清空数据数组，确保完全刷新
          data = [];

          // 遍历当月的每一天
          for (let i = 1; i <= daysInMonth; i++) {
            // 格式化月份和日期，确保两位数（如01,02...）
            const monthStr = (month + 1).toString().padStart(2, '0');
            const dayStr = i.toString().padStart(2, '0');
            // 组合成YYYY-MM-DD格式的日期字符串
            const dateStr = `${year}-${monthStr}-${dayStr}`;

            // 记录日志，表示正在获取特定日期的步数数据
            hilog.info(DOMAIN_NUMBER, TAG, `获取日期 ${dateStr} 的步数数据`);
            // 从数据库获取该日期的步数记录
            const stepRecords = await this.dbHelper.getStepRecords(this.userId, dateStr);

            // 计算该日的总步数（累加所有记录的步数）
            const daySteps = stepRecords.reduce((sum, record) => sum + record.steps, 0);
            // 记录日志，显示计算出的总步数
            hilog.info(DOMAIN_NUMBER, TAG, `${dateStr} 的总步数: ${daySteps}`);

            // 添加图表数据项，标签为日期数字
            data.push({
              label: `${i}`,   // 日期数字作为标签
              value: daySteps  // 该日的总步数
            });

            monthTotal += daySteps; // 累加到月总步数
            if (daySteps > 0) {
              activeDays++;        // 如果当天有步数，有效天数+1
            }
          }

          total = monthTotal; // 设置总步数为月总步数
          // 设置Y轴最大显示值，取15000和(月平均步数*1.5)中的较大值
          this.maxDisplayValue = Math.max(15000, Math.ceil(monthTotal / daysInMonth) * 1.5);
          // 设置日期显示文本，格式为"YYYY年MM月"
          dateDisplay = `${year}年${month + 1}月`;
          // 计算平均每日步数（只计算有步数记录的天数）
          this.avgDailySteps = activeDays > 0 ? Math.round(monthTotal / activeDays) : 0;

          // 记录日志，表示月数据更新完成
          hilog.info(DOMAIN_NUMBER, TAG, `月视图数据更新完成: 总步数=${total}, 平均步数=${this.avgDailySteps}`);
          break;
      }

      // 更新图表数据、总步数和日期范围文本
      this.stepChartData = data;
      this.totalSteps = total;
      this.dateRangeText = dateDisplay;

    } catch (error) {
      // 捕获并处理任何可能发生的错误
      // 提取错误信息，针对Error对象和其他类型错误做不同处理
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      // 记录错误日志
      hilog.error(0x0000, TAG, `Failed to update step chart data: ${errorMessage}`);
    }
  }
  /**
   * 打开系统日历应用
   * 通过Want机制启动华为设备上的系统日历应用
   *
   * Want机制是鸿蒙OS中用于应用间通信和启动组件的标准方式，
   * 类似于Android中的Intent系统。
   *
   * @returns {Promise<void>} 返回一个Promise，表示异步操作完成
   */
  async openCalendar() {
    try {
      // 创建Want对象，指定目标应用信息
      const want: Want = {
        deviceId: "",  // 空字符串表示操作在本地设备上执行
        bundleName: "com.huawei.calendar",  // 华为日历应用的包名
        abilityName: "com.huawei.calendar.LauncherAbility"  // 日历应用的入口Ability
      };

      // 获取当前UI上下文并转换为UIAbilityContext类型
      // 这是鸿蒙OS应用的上下文对象，包含了应用运行环境的信息
      let context = getContext(this) as common.UIAbilityContext;

      // 通过上下文对象启动指定的应用
      // 使用await关键字等待操作完成
      await context.startAbility(want);

      // 操作成功时打印日志信息
      // grf_前缀可能是开发者的日志标识
      console.info("grf_成功打开系统日历");
    } catch (error) {
      // 捕获并处理启动过程中可能出现的异常
      // 例如：目标应用不存在、权限不足等
      console.info(`grf_打开系统日历失败：${error}`);
    }
  }

  /**
   * 选择日期方法
   *
   * 这是一个框架方法，目前只有基本的错误处理结构，
   * 具体功能尚未实现，可能是计划中的功能或待开发项。
   * 预期用途是让用户选择一个日期，可能用于查看特定日期的健康数据。
   *
   * @returns {Promise<void>} 返回一个Promise，表示异步操作完成
   */
  async selectDate() {
    try {
      // 待实现的功能逻辑
      // 这里可能会添加日期选择器的显示和处理逻辑
    } catch (err) {
      // 记录日期选择过程中的错误
      console.error(`Select date failed with error: ${err}`);
    }
  }

  /**
   * 计算柱状图条形高度
   *
   * 根据数值与最大显示值的比例计算柱状图中条形的可视高度。
   * 该方法确保即使是很小的非零值也有最小可见高度，
   * 提高图表的可读性。
   *
   * @param value 需要显示的数值（如步数、饮水量等）
   * @returns {number} 计算后的条形高度（像素值）
   */
  calculateBarHeight(value: number): number {
    const maxHeight = 120;  // 定义条形的最大高度为120像素

    // 按比例计算高度：(数值/最大显示值) * 最大高度
    // this.maxDisplayValue可能是动态计算的图表Y轴最大值
    const calculatedHeight = (value / this.maxDisplayValue) * maxHeight;

    // 返回计算高度和最小高度中的较大值
    // 如果value大于0但计算高度小于5，则使用5像素作为最小可见高度
    // 如果value为0，则高度为0（不显示）
    return Math.max(calculatedHeight, value > 0 ? 5 : 0);
  }

  /**
   * 分享健康数据方法
   * 该方法将用户健康数据打包并发送到目标应用程序
   * @returns {Promise<void>} 返回一个Promise，表示异步操作
   */
  async shareHealthData() {
    try {
      // 首先刷新数据，确保分享的是最新数据
      await this.refreshData();

      // 创建健康数据对象，包含用户所有相关健康信息
      const healthData: HealthData = {
        userId: this.userId,          // 用户ID
        username: this.username,      // 用户名
        date: this.currentDate,       // 当前日期
        steps: this.steps,            // 步数
        heartRate: this.heartRate,    // 心率
        sleepHours: this.sleepHours,  // 睡眠时长
        waterAmount: this.waterAmount // 饮水量
      };

      // 将健康数据对象转换为JSON字符串，便于传输
      const dataString = JSON.stringify(healthData);

      // 创建Want对象，用于启动目标应用
      // Want是鸿蒙OS中用于描述应用组件启动意图的对象
      const want: Want = {
        bundleName: 'com.example.target',  // 目标应用的包名
        abilityName: 'EntryAbility',       // 目标应用的Ability名称
        moduleName: 'entry',               // 目标应用的模块名称
        parameters: {
          healthData: dataString           // 将健康数据作为参数传递
        }
      };

      // 调用context的startAbility方法启动目标应用
      this.context.startAbility(want)
        .then(() => {
          // 启动成功，记录成功日志
          hilog.info(0x0000, TAG, 'Health data shared successfully');
        })
        .catch((err: Error) => {
          // 启动失败，记录错误日志
          hilog.error(0x0000, TAG, `Failed to start ability: ${err.message}`);
        });
    } catch (error) {
      // 捕获并处理整个分享过程中可能发生的任何错误
      // 将错误对象转换为字符串消息
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      // 记录错误日志
      hilog.error(0x0000, TAG, `Failed to share health data: ${errorMessage}`);
    }
  }

  /*
  通过路由Router进行页面的跳转，并且转递对应的参数
 */
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
  /*
   刷新数据
   */
  manualRefresh() {
    hilog.info(0x0000, TAG, 'Manual refresh triggered');
    this.refreshData();
  }
  /*
    添加要输入的心率数据行，默认为空
   */
  addHeartRateInputRow() {
    this.heartRateInputTimes.push('');
    this.heartRateInputValues.push('');
  }
  /*
    去除输入的心率行数据
   */
  removeHeartRateInputRow(index: number) {
    if (this.heartRateInputTimes.length > 1) {
      this.heartRateInputTimes.splice(index, 1);
      this.heartRateInputValues.splice(index, 1);
    }
  }
  /*
    添加要输入的饮水量数据行，默认为空
   */
  addWaterInputRow() {
    this.waterInputTimes.push('');
    this.waterInputValues.push('');
  }
  /*
    去除输入的饮水量数据行
   */
  removeWaterInputRow(index: number) {
    if (this.waterInputTimes.length > 1) {
      this.waterInputTimes.splice(index, 1);
      this.waterInputValues.splice(index, 1);
    }
  }
  /*
    添加输入的步数行，默认为8点，0步
   */
  addStepInputRow() {
    this.stepInputTimes.push('08:00');
    this.stepInputValues.push('0');
  }
/*
  去除输入的步数行
 */
  removeStepInputRow(index: number) {
    if (this.stepInputTimes.length > 1) {
      this.stepInputTimes.splice(index, 1);
      this.stepInputValues.splice(index, 1);
    }
  }

  /**
   * 保存多条心率记录
   * 该函数处理批量保存用户的心率记录到数据库
   *
   * @returns {Promise<void>} - 异步函数，无返回值
   */
  async saveMultiHeartRates() {
    // 验证用户ID是否有效
    if (this.userId <= 0) {
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }

    try {
      let successCount = 0;  // 记录成功保存的条目数

      // 遍历所有输入行，处理每组时间和心率值
      for (let i = 0; i < this.heartRateInputTimes.length; i++) {
        const time = this.heartRateInputTimes[i].trim();  // 去除时间字符串前后的空格
        const rate = parseInt(this.heartRateInputValues[i]) || 0;  // 将心率转换为整数，如果转换失败则为0

        // 跳过无效的记录（空时间、无效时间格式或心率小于等于0）
        if (!time || !this.isValidTimeFormat(time) || rate <= 0) {
          continue;
        }

        // 创建心率记录对象
        const record = new HeartRateRecord(this.userId, this.currentDate, time, rate);

        // 尝试将记录插入数据库，如果成功则递增计数器
        if (await this.dbHelper.insertHeartRateRecord(record)) {
          successCount++;
        }
      }

      // 根据保存结果提供反馈
      if (successCount > 0) {
        promptAction.showToast({ message: `成功保存 ${successCount} 条心率记录` });
        this.refreshData();  // 刷新界面数据
      } else {
        promptAction.showToast({ message: '没有有效的心率记录被保存' });
      }
    } catch (error) {
      // 错误处理：提取错误信息并记录日志
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to save heart rate records: ${errorMessage}`);
      promptAction.showToast({ message: '保存心率记录失败' });
    }
  }

  /**
   * 保存多条饮水记录
   * 该函数处理批量保存用户的饮水记录到数据库
   *
   * @returns {Promise<void>} - 异步函数，无返回值
   */
  async saveMultiWaterRecords() {
    // 验证用户ID是否有效
    if (this.userId <= 0) {
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }

    try {
      let successCount = 0;  // 记录成功保存的条目数

      // 遍历所有输入行，处理每组时间和饮水量
      for (let i = 0; i < this.waterInputTimes.length; i++) {
        const time = this.waterInputTimes[i].trim();  // 去除时间字符串前后的空格
        const amount = parseInt(this.waterInputValues[i]) || 0;  // 将饮水量转换为整数，如果转换失败则为0

        // 跳过无效的记录（空时间、无效时间格式或饮水量小于等于0）
        if (!time || !this.isValidTimeFormat(time) || amount <= 0) {
          continue;
        }

        // 创建饮水记录对象
        const record = new WaterRecord(this.userId, this.currentDate, time, amount);

        // 尝试将记录插入数据库，如果成功则递增计数器
        if (await this.dbHelper.insertWaterRecord(record)) {
          successCount++;
        }
      }

      // 根据保存结果提供反馈
      if (successCount > 0) {
        promptAction.showToast({ message: `成功保存 ${successCount} 条饮水记录` });
        this.checkWaterAndNotify(this.waterAmount);  // 检查饮水量并可能发送通知
        this.refreshData();  // 刷新界面数据
      } else {
        promptAction.showToast({ message: '没有有效的饮水记录被保存' });
      }
    } catch (error) {
      // 错误处理：提取错误信息并记录日志
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to save water records: ${errorMessage}`);
      promptAction.showToast({ message: '保存饮水记录失败' });
    }
  }

  /**
   * 保存多条步数记录
   * 该函数处理批量保存用户的步数记录到数据库，并包含详细的日志记录
   *
   * @returns {Promise<void>} - 异步函数，无返回值
   */
  async saveMultiStepRecords(): Promise<void> {
    // 验证用户ID是否有效
    if (this.userId <= 0) {
      hilog.error(0x0000, TAG, `Invalid userId: ${this.userId}`);
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }

    try {
      hilog.info(0x0000, TAG, `Starting to save multi step records for user ${this.userId}`);
      let successCount = 0;  // 记录成功验证的条目数

      // 收集有效的时间步数记录
      const validRecords: StepTimeInput[] = [];

      // 记录数据验证过程
      hilog.info(0x0000, TAG, `Total input rows: ${this.stepInputTimes.length}`);

      // 遍历所有输入行，处理每组时间和步数
      for (let i = 0; i < this.stepInputTimes.length; i++) {
        const time = this.stepInputTimes[i].trim();  // 去除时间字符串前后的空格
        const stepsStr = this.stepInputValues[i];
        const steps = parseInt(stepsStr) || 0;  // 将步数转换为整数，如果转换失败则为0

        hilog.info(0x0000, TAG, `Validating row ${i}: time=${time}, steps=${steps}`);

        // 验证时间是否为空
        if (!time) {
          hilog.warn(0x0000, TAG, `Row ${i}: Empty time`);
          continue;
        }

        // 验证时间格式
        if (!this.isValidTimeFormat(time)) {
          hilog.warn(0x0000, TAG, `Row ${i}: Invalid time format: ${time}`);
          continue;
        }

        // 验证步数是否有效
        if (steps <= 0) {
          hilog.warn(0x0000, TAG, `Row ${i}: Invalid steps value: ${steps}`);
          continue;
        }

        // 创建记录对象并添加到验证通过的记录数组
        const record: StepTimeInput = {
          time: time,
          steps: steps
        };

        validRecords.push(record);
        successCount++;
        hilog.info(0x0000, TAG, `Row ${i}: Valid record added: time=${time}, steps=${steps}`);
      }

      hilog.info(0x0000, TAG, `Collected ${successCount} valid records out of ${this.stepInputTimes.length} inputs`);

      // 处理验证结果
      if (successCount > 0) {
        // 使用批量保存方法将所有有效记录一次性保存到数据库
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

          // 向用户显示保存成功的消息
          promptAction.showToast({
            message: `成功保存 ${successCount} 条步数记录，总步数: ${totalSteps}`
          });

          // 检查步数达成情况并可能发送通知，然后刷新界面数据
          hilog.info(0x0000, TAG, 'Refreshing data after saving');
          this.checkStepsAndNotify(totalSteps);
          await this.refreshData();
        } else {
          // 数据库操作失败
          hilog.error(0x0000, TAG, 'batchSaveStepRecords returned false');
          promptAction.showToast({ message: '保存步数记录失败' });
        }
      } else {
        // 没有有效的记录
        hilog.warn(0x0000, TAG, 'No valid records to save');
        promptAction.showToast({ message: '没有有效的步数记录被保存' });
      }
    } catch (error) {
      // 详细的错误处理：提取错误信息和堆栈跟踪并记录日志
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Exception in saveMultiStepRecords: ${errorMessage}`);
      hilog.error(0x0000, TAG, `Stack trace: ${error instanceof Error ? error.stack : 'No stack trace'}`);
      promptAction.showToast({ message: '保存步数记录失败: ' + errorMessage });
    }
  }


  /*
    检查时间是否合法
   */
  isValidTimeFormat(time: string): boolean {
    const regex = /^([01]?[0-9]|2[0-3]):([0-5][0-9])$/;
    return regex.test(time);
  }

  build() {
    Column() {
      Row() {
        Text("个人健康管理系统")
          .titleTextStyle()
        Blank()
        if (this.username) {
          Text(`欢迎，${this.username}`)
            .regularTextStyle()
        }
      }
      .headerRowStyle()

      Divider()
        .standardDividerStyle()

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
            checkSleepAndNotify: this.checkSleepAndNotify.bind(this),
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
      .mainTabsStyle()
      .onChange((index: number) => {
        this.currentIndex = index;
        this.refreshData();
      })
    }
    .mainContainerStyle()
  }
}