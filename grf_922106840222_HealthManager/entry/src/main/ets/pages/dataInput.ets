import { hilog } from '@kit.PerformanceAnalysisKit';
import common from '@ohos.app.ability.common';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from '../common/HealthDataModel';
import promptAction from '@ohos.promptAction';

const TAG: string = 'dataInput';
@Entry
@Component
struct dataInput{
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

  async refreshData() {
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
  build() {

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
  }
}

export { dataInput };
