import promptAction from '@ohos.promptAction';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from '../common/HealthDataModel';
import { DataInputRow } from './myComponents';
import { DatabaseHelper } from '../common/DatabaseHelper';
import {HeartRateInputDialog, StepInputDialog, WaterInputDialog} from './Dialog'
const TAG: string = 'DataInputTabComponent';
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

@Component
export struct DataInputTabComponent {
  @Link username: string;
  @Link userId: number;
  @Link steps: number;
  @Link heartRate: number;
  @Link sleepHours: number;
  @Link waterAmount: number;
  @Link tempWaterAmount: number;
  @Link heartRateInputTimes: string[];
  @Link heartRateInputValues: string[];
  @Link waterInputTimes: string[];
  @Link waterInputValues: string[];
  @Link stepInputTimes: string[];
  @Link stepInputValues: string[];
  @Link currentDate: string;

  @Prop refreshData: () => Promise<void>;

  // @Prop heartRateDialogController: CustomDialogController;
  // @Prop waterDialogController: CustomDialogController;
  // @Prop stepDialogController: CustomDialogController;

  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));

  build() {
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
              .secondaryButton('#1698CE')
              .opacity(0.8)
              .onClick(() => {
                this.stepInputTimes = ['08:00'];
                this.stepInputValues = ['0'];
               // this.stepDialogController.open();
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
                //this.heartRateDialogController.open();
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
                //this.waterDialogController.open();
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
}