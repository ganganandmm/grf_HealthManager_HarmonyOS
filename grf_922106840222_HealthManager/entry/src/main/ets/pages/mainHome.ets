import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';
import common from '@ohos.app.ability.common';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from '../common/HealthDataModel';
import Want from '@ohos.app.ability.Want'
import promptAction from '@ohos.promptAction';
const TAG: string = 'MainHome';


interface RouteParams {
  username?: string;
  userId?: number;
  newLogin?: boolean; // Add explicit type for newLogin flag
}

// Define interface for health data
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
  // Add other specific parameters as needed
}

// Define explicit type for ability parameters
interface AbilityStartParams {
  bundleName: string;
  abilityName: string;
  moduleName?: string;
  parameters?: WantParams;
}

// Define router parameters type
interface RouterParams {
  username: string;
  userId: string;
  steps: string;
  heartRate: string;
  sleepHours: string;
  waterAmount: string;
}

// Define metadata params type
interface MetadataParams {
  healthData?: string;
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

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    if (params) {
      if (params.username) {
        this.username = params.username;
      }
      if (params.userId) {
        this.userId = params.userId;
      }
      // Check if this is a new login
      if (params.newLogin) {
        this.isNewLogin = true;
        hilog.info(0x0000, TAG, 'New login detected, refreshing data');
      }
    }

    // 初始化数据库和加载数据
    this.initData();

    // 检查是否有通过Want接收到的数据
    this.checkReceivedData();

    // Set up periodic refresh for data (every 30 seconds)
    this.refreshInterval = setInterval(() => {
      this.refreshData();
    }, 30000); // 30 seconds
  }

  aboutToDisappear() {
    // Clear the interval when component is about to disappear
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }
    // Close database connection
    this.dbHelper.closeDatabase();
  }

  async initData() {
    try {
      await this.dbHelper.initDatabase();

      // 如果没有提供userId，则尝试从用户名获取
      if (this.userId < 0 && this.username) {
        const users = await this.dbHelper.queryUserByUsername(this.username);
        if (users.length > 0) {
          this.userId = users[0].id || -1;
        }
      }

      // 只有在有效userId的情况下才加载健康数据
      if (this.userId > 0) {
        await this.loadHealthData();
      }

      // Reset new login flag after initial data load
      this.isNewLogin = false;
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to initialize data: ${errorMessage}`);
    }
  }

  async refreshData() {
    // Check if there's a need to refresh (if db was updated)
    try {
      hilog.info(0x0000, TAG, 'Checking for data updates');
      if (this.userId > 0) {
        await this.loadHealthData();
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to refresh data: ${errorMessage}`);
    }
  }

  async loadHealthData() {
    try {
      // 加载步数数据
      const stepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
      if (stepRecords.length > 0) {
        this.steps = stepRecords[0].steps;
      } else {
        this.steps = 0; // Reset if no records
      }

      // 加载心率数据
      const heartRateRecords = await this.dbHelper.getHeartRateRecords(this.userId, this.currentDate);
      if (heartRateRecords.length > 0) {
        // 取最近的一次心率记录
        this.heartRate = heartRateRecords[heartRateRecords.length - 1].rate;
      } else {
        this.heartRate = 0; // Reset if no records
      }

      // 加载睡眠数据
      const sleepRecords = await this.dbHelper.getSleepRecords(this.userId, this.currentDate);
      if (sleepRecords.length > 0) {
        this.sleepHours = sleepRecords[0].duration / 60; // 转换为小时
      } else {
        this.sleepHours = 0; // Reset if no records
      }

      // 加载饮水数据
      const waterRecords = await this.dbHelper.getWaterRecords(this.userId, this.currentDate);
      this.waterRecords = waterRecords;
      // 计算总饮水量
      this.waterAmount = waterRecords.reduce((total, record) => total + record.amount, 0);

      // Update last update time
      this.lastUpdateTime = Date.now();

      hilog.info(0x0000, TAG, 'Health data loaded successfully');
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to load health data: ${errorMessage}`);
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

  ClickJumpToShowData() {
    // Before navigating, refresh data
    this.refreshData().then(() => {
      // We only need to pass heart rate and water amount data
      const routerParams: RouterParams = {
        username: this.username,
        userId: this.userId.toString(),
        steps: this.steps.toString(),
        heartRate: this.heartRate.toString(),
        sleepHours: this.sleepHours.toString(),
        waterAmount: this.waterAmount.toString()
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

  // Add manual refresh method that can be triggered by a button
  manualRefresh() {
    hilog.info(0x0000, TAG, 'Manual refresh triggered');
    this.refreshData();
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

        // Add a refresh button
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          Image($r('app.media.startIcon'))
            .width(24)
            .height(24)
        }
        .width(36)
        .height(36)
        .backgroundColor('#1698CE')
        .margin({ left: 8 })
        .onClick(() => {
          this.manualRefresh();
        })
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
        // 首页 - 健康数据概览
        TabContent() {
          Scroll() {
            Column() {
              // Show last update time
              Text(`上次更新: ${new Date(this.lastUpdateTime).toLocaleTimeString()}`)
                .fontSize(14)
                .fontColor('#888')
                .alignSelf(ItemAlign.End)
                .margin({ top: 5, right: 10 })
                .visibility(this.lastUpdateTime > 0 ? Visibility.Visible : Visibility.None)

              Text('今日健康数据概览')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 10, bottom: 20 })

              // 数据卡片
              Row() {
                Column() {
                  Text('步数')
                    .fontSize(16)
                    .fontColor('#666')
                  Text(`${this.steps}`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1698CE')
                }
                .width('45%')
                .padding(10)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')

                Column() {
                  Text('平均心率')
                    .fontSize(16)
                    .fontColor('#666')
                  Text(`${this.heartRate} bpm`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#E74C3C')
                }
                .width('45%')
                .padding(10)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')
              }
              .width('90%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ top: 10, bottom: 20 })

              Row() {
                Column() {
                  Text('睡眠时长')
                    .fontSize(16)
                    .fontColor('#666')
                  Text(`${this.sleepHours.toFixed(1)} 小时`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#9B59B6')
                }
                .width('45%')
                .padding(10)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')

                Column() {
                  Text('饮水量')
                    .fontSize(16)
                    .fontColor('#666')
                  Text(`${this.waterAmount} ml`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#3498DB')
                }
                .width('45%')
                .padding(10)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')
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
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 10 })
                    .alignSelf(ItemAlign.Start)

                  Text(this.receivedHealthData)
                    .fontSize(14)
                    .fontColor('#666')
                    .width('100%')
                }
                .width('90%')
                .padding(15)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')
                .margin({ top: 10, bottom: 20 })
              }

              // 最近饮水记录
              Column() {
                Text('今日饮水记录')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 10 })
                  .alignSelf(ItemAlign.Start)

                List() {
                  ForEach(this.waterRecords, (item: WaterRecord) => {
                    ListItem() {
                      Row() {
                        Text(item.time)
                          .fontSize(16)
                          .width('40%')
                        Text(`${item.amount} ml`)
                          .fontSize(16)
                          .fontColor('#3498DB')
                          .width('60%')
                      }
                      .width('100%')
                      .padding(10)
                      .justifyContent(FlexAlign.SpaceBetween)
                    }
                  })
                }
                .width('100%')
                .height(150)
                .divider({ strokeWidth: 1, color: '#eeeeee' })
              }
              .width('90%')
              .padding(15)
              .borderRadius(8)
              .backgroundColor('#f7f7f7')
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
        .tabBar({ text: '首页' })

        // 数据输入页面
        TabContent() {
          Column() {
            Text('健康数据录入')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20, bottom: 20 })
            Scroll() {
              Column() {
                // 步数输入
                Column() {
                  Text('步数录入')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 10 })

                  TextInput({ text: this.steps.toString() })
                    .type(InputType.Number)
                    .width('100%')
                    .height(50)
                    .margin({ bottom: 10 })
                    .onChange((value: string) => {
                      this.steps = parseInt(value) || 0;
                    })
                  Button('保存步数')
                    .width('100%')
                    .height(40)
                    .backgroundColor('#1698CE')
                    .margin({ bottom: 20 })
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
                .width('90%')
                .padding(15)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')
                .margin({ bottom: 20 })

                // 心率输入
                Column() {
                  Text('心率录入')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 10 })

                  Row() {
                    TextInput({ text: this.heartRate.toString() })
                      .type(InputType.Number)
                      //.placeholderText('请输入心率')
                      .width('70%')
                      .height(50)
                      .onChange((value: string) => {
                        this.heartRate = parseInt(value) || 0;
                      })

                    Text('bpm')
                      .fontSize(16)
                      .fontColor('#666')
                      .margin({ left: 10 })
                  }
                  .width('100%')
                  .margin({ bottom: 10 })

                  Button('保存心率')
                    .width('100%')
                    .height(40)
                    .backgroundColor('#E74C3C')
                    .margin({ bottom: 20 })
                    .onClick(async () => {
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
                    })
                }
                .width('90%')
                .padding(15)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')
                .margin({ bottom: 20 })

                // 睡眠时长输入
                Column() {
                  Text('睡眠记录')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 10 })

                  Row() {
                    TextInput({ text: this.sleepHours.toFixed(1) })
                      .type(InputType.Number)
                      //.placeholderText('请输入睡眠时长(0-24小时)')
                      .width('70%')
                      .height(50)
                      .onChange((value: string) => {
                        let sleepValue = parseFloat(value) || 0;
                        // 限制睡眠时长在0-24小时之间
                        if (sleepValue < 0) sleepValue = 0;
                        if (sleepValue > 24) sleepValue = 24;
                        this.sleepHours = sleepValue;
                      })

                    Text('小时')
                      .fontSize(16)
                      .fontColor('#666')
                      .margin({ left: 10 })
                  }
                  .width('100%')
                  .margin({ bottom: 10 })

                  Text('睡眠时长范围: 0-24小时')
                    .fontSize(14)
                    .fontColor('#888')
                    .margin({ bottom: 10 })

                  Button('保存睡眠时长')
                    .width('100%')
                    .height(40)
                    .backgroundColor('#9B59B6')
                    .margin({ bottom: 20 })
                    .onClick(async () => {
                      if (this.userId > 0) {
                        // 确保睡眠时长在0-24小时范围内
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
                    })
                }
                .width('90%')
                .padding(15)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')
                .margin({ bottom: 20 })

                // 饮水量输入
                Column() {
                  Text('饮水记录')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .alignSelf(ItemAlign.Start)
                    .margin({ bottom: 10 })

                  Row() {
                    TextInput({ text: '' })
                      .type(InputType.Number)
                      //.placeholderText('请输入饮水量')
                      .width('70%')
                      .height(50)
                      .onChange((value: string) => {
                        this.tempWaterAmount = parseInt(value) || 0;
                      })

                    Text('ml')
                      .fontSize(16)
                      .fontColor('#666')
                      .margin({ left: 10 })
                  }
                  .width('100%')
                  .margin({ bottom: 10 })

                  Button('添加饮水记录')
                    .width('100%')
                    .height(40)
                    .backgroundColor('#3498DB')
                    .margin({ bottom: 20 })
                    .onClick(async () => {
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
                    })

                  // 显示今日总饮水量
                  Text(`今日总饮水量: ${this.waterAmount} ml`)
                    .fontSize(16)
                    .fontColor('#3498DB')
                    .margin({ top: 10 })
                }
                .width('90%')
                .padding(15)
                .borderRadius(8)
                .backgroundColor('#f7f7f7')
                .margin({ bottom: 20 })

                // 数据刷新按钮
                Column() {
                  Button('刷新所有数据')
                    .width('90%')
                    .height(40)
                    .backgroundColor('#2ECC71')
                    .margin({ bottom: 10 })
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

        // 我的运动页面
        TabContent() {
          Column() {
            Text('我的运动')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20, bottom: 20 })

            Text(`今日步数: ${this.steps}`)
              .fontSize(18)
              .margin({ top: 10, bottom: 10 })

            // 这里可以添加运动相关的功能
            Button('刷新运动数据')
              .width('80%')
              .height(40)
              .backgroundColor('#27AE60')
              .margin({ top: 20, bottom: 20 })
              .onClick(() => {
                this.refreshData();
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar({ text: '我的运动' })

        // 个人中心页面
        TabContent() {
          Column() {
            Text('个人中心')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 20, bottom: 20 })

            Column() {
              Row() {
                Text('用户名：')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .width('30%')
                Text(this.username)
                  .fontSize(16)
                  .width('70%')
              }
              .width('100%')
              .padding(10)

              Divider()
                .width('100%')
                .height(1)
                .backgroundColor('#eeeeee')

              Row() {
                Text('用户ID：')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .width('30%')
                Text(this.userId.toString())
                  .fontSize(16)
                  .width('70%')
              }
              .width('100%')
              .padding(10)
            }
            .width('90%')
            .padding(15)
            .borderRadius(8)
            .backgroundColor('#f7f7f7')
            .margin({ bottom: 20 })

            Button('退出登录')
              .width('80%')
              .height(50)
              .margin({ top: 30 })
              .backgroundColor('#E74C3C')
              .onClick(() => {
                router.clear();
                router.pushUrl({
                  url: 'pages/Login' // 修改为正确的登录页面路径
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
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .tabBar({ text: '个人中心' })
      }
      .width('100%')
      .layoutWeight(1)
      .barHeight(60)
      .onChange((index: number) => {
        this.currentIndex = index;
        // Refresh data when switching tabs
        this.refreshData();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}