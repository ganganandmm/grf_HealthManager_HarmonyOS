// InputTabComponent.ets
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from '../common/HealthDataModel';
import { DatabaseHelper } from '../common/DatabaseHelper';
import promptAction from '@ohos.promptAction';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RefreshDataFunc } from './FunctionInterfaces';

const TAG: string = 'InputTab';

@CustomDialog
struct HeartRateInputDialog {
  @State heartRateInputTimes: string[] = [];
  @State heartRateInputValues: string[] = [];
  private controller: CustomDialogController;
  private addHeartRateInputRow!: () => void;
  private removeHeartRateInputRow!: (index: number) => void;
  private saveMultiHeartRates!: () => Promise<void>;

  aboutToAppear() {
    // 确保至少有一行输入
    if (this.heartRateInputTimes.length === 0) {
      this.heartRateInputTimes = ['08:00'];
      this.heartRateInputValues = ['0'];
    }
  }

  build() {
    Column() {
      Text('批量心率录入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 20 })

      // 心率输入行列表
      List() {
        ForEach(this.heartRateInputTimes, (time: string, index: number) => {
          ListItem() {
            Row() {
              // 时间输入
              TextInput({ text: time, placeholder: "时间 (HH:MM)" })
                .type(InputType.Normal)
                .width('40%')
                .height(50)
                .margin({ right: 10 })
                .onChange((value: string) => {
                  this.heartRateInputTimes[index] = value;
                })

              // 心率值输入
              TextInput({ text: this.heartRateInputValues[index], placeholder: "心率" })
                .type(InputType.Number)
                .width('30%')
                .height(50)
                .margin({ right: 10 })
                .onChange((value: string) => {
                  this.heartRateInputValues[index] = value;
                })

              // 删除按钮
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Image($r('app.media.delete') || $r('app.media.add'))
                  .width(24)
                  .height(24)
              }
              .width(40)
              .height(40)
              .backgroundColor('#f5f5f5')
              .onClick(() => {
                this.removeHeartRateInputRow(index);
              })
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      // 添加按钮
      Button('添加心率记录')
        .width('100%')
        .height(40)
        .margin({ top: 10, bottom: 10 })
        .backgroundColor('#27AE60')
        .onClick(() => {
          this.addHeartRateInputRow();
        })

      // 底部按钮
      Row() {
        Button('取消')
          .width('45%')
          .height(40)
          .backgroundColor('#95a5a6')
          .onClick(() => {
            this.controller.close();
          })

        Button('保存')
          .width('45%')
          .height(40)
          .backgroundColor('#E74C3C')
          .onClick(async () => {
            await this.saveMultiHeartRates();
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#f5f5f5')
  }
}

@CustomDialog
struct WaterInputDialog {
  @State waterInputTimes: string[] = [];
  @State waterInputValues: string[] = [];
  private controller: CustomDialogController;
  private addWaterInputRow!: () => void;
  private removeWaterInputRow!: (index: number) => void;
  private saveMultiWaterRecords!: () => Promise<void>;

  aboutToAppear() {
    // 确保至少有一行输入
    if (this.waterInputTimes.length === 0) {
      this.waterInputTimes = ['08:00'];
      this.waterInputValues = ['0'];
    }
  }

  build() {
    Column() {
      Text('批量饮水记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 20 })

      // 饮水量输入行列表
      List() {
        ForEach(this.waterInputTimes, (time: string, index: number) => {
          ListItem() {
            Row() {
              // 时间输入
              TextInput({ text: time, placeholder: "时间 (HH:MM)" })
                .type(InputType.Normal)
                .width('40%')
                .height(50)
                .margin({ right: 10 })
                .onChange((value: string) => {
                  this.waterInputTimes[index] = value;
                })

              // 饮水量输入
              TextInput({ text: this.waterInputValues[index], placeholder: "饮水量(ml)" })
                .type(InputType.Number)
                .width('30%')
                .height(50)
                .margin({ right: 10 })
                .onChange((value: string) => {
                  this.waterInputValues[index] = value;
                })

              // 删除按钮
              Button({ type: ButtonType.Circle, stateEffect: true }) {
                Image($r('app.media.delete') || $r('app.media.delete'))
                  .width(24)
                  .height(24)
              }
              .width(40)
              .height(40)
              .backgroundColor('#f5f5f5')
              .onClick(() => {
                this.removeWaterInputRow(index);
              })
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)

      // 添加按钮
      Button('添加饮水记录')
        .width('100%')
        .height(40)
        .margin({ top: 10, bottom: 10 })
        .backgroundColor('#27AE60')
        .onClick(() => {
          this.addWaterInputRow();
        })

      // 底部按钮
      Row() {
        Button('取消')
          .width('45%')
          .height(40)
          .backgroundColor('#95a5a6')
          .onClick(() => {
            this.controller.close();
          })

        Button('保存')
          .width('45%')
          .height(40)
          .backgroundColor('#3498DB')
          .onClick(async () => {
            await this.saveMultiWaterRecords();
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#f5f5f5')
  }
}

@Component
export struct InputTabComponent {
  @Link username: string;
  @Link userId: number;
  @Link steps: number;
  @Link heartRate: number;
  @Link sleepHours: number;
  @Link waterAmount: number;
  @Link currentDate: string;
  @Link tempWaterAmount: number;
  @Link heartRateInputTimes: string[];
  @Link heartRateInputValues: string[];
  @Link waterInputTimes: string[];
  @Link waterInputValues: string[];

  @Prop dbHelper: DatabaseHelper;
  @Prop refreshDataFunc: RefreshDataFunc;

  // 对话框控制器
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

  aboutToDisappear() {
    this.heartRateDialogController.close();
    this.waterDialogController.close();
  }

  // 添加心率输入行
  addHeartRateInputRow() {
    this.heartRateInputTimes.push('');
    this.heartRateInputValues.push('');
  }

  // 删除心率输入行
  removeHeartRateInputRow(index: number) {
    if (this.heartRateInputTimes.length > 1) {
      this.heartRateInputTimes.splice(index, 1);
      this.heartRateInputValues.splice(index, 1);
    }
  }

  // 添加饮水输入行
  addWaterInputRow() {
    this.waterInputTimes.push('');
    this.waterInputValues.push('');
  }

  // 删除饮水输入行
  removeWaterInputRow(index: number) {
    if (this.waterInputTimes.length > 1) {
      this.waterInputTimes.splice(index, 1);
      this.waterInputValues.splice(index, 1);
    }
  }

  // 批量保存心率数据
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

        // 验证时间格式和心率值
        if (!time || !this.isValidTimeFormat(time) || rate <= 0) {
          continue; // 跳过无效输入
        }

        // 创建并保存心率记录
        const record = new HeartRateRecord(this.userId, this.currentDate, time, rate);
        if (await this.dbHelper.insertHeartRateRecord(record)) {
          successCount++;
        }
      }

      // 显示结果消息
      if (successCount > 0) {
        promptAction.showToast({ message: `成功保存 ${successCount} 条心率记录` });
        this.refreshDataFunc.refreshData(); // 刷新数据
      } else {
        promptAction.showToast({ message: '没有有效的心率记录被保存' });
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to save heart rate records: ${errorMessage}`);
      promptAction.showToast({ message: '保存心率记录失败' });
    }
  }

  // 批量保存饮水数据
  async saveMultiWaterRecords() {
    if (this.userId <= 0) {
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }

    try {
      let successCount = 0;
      // 遍历所有输入行
      for (let i = 0; i < this.waterInputTimes.length; i++) {
        const time = this.waterInputTimes[i].trim();
        const amount = parseInt(this.waterInputValues[i]) || 0;

        // 验证时间格式和饮水量
        if (!time || !this.isValidTimeFormat(time) || amount <= 0) {
          continue; // 跳过无效输入
        }

        // 创建并保存饮水记录
        const record = new WaterRecord(this.userId, this.currentDate, time, amount);
        if (await this.dbHelper.insertWaterRecord(record)) {
          successCount++;
        }
      }

      // 显示结果消息
      if (successCount > 0) {
        promptAction.showToast({ message: `成功保存 ${successCount} 条饮水记录` });
        this.refreshDataFunc.refreshData(); // 刷新数据
      } else {
        promptAction.showToast({ message: '没有有效的饮水记录被保存' });
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to save water records: ${errorMessage}`);
      promptAction.showToast({ message: '保存饮水记录失败' });
    }
  }

  // 验证时间格式是否为 HH:MM
  isValidTimeFormat(time: string): boolean {
    const regex = /^([01]?[0-9]|2[0-3]):([0-5][0-9])$/;
    return regex.test(time);
  }

  build() {
    Column() {
      Text('健康数据录入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })
      Scroll() {
        Column() {
          // 步数输入
          Column() {
            Text('步数录入')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 })
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
                .margin({ bottom: 10 ,left:'5%'})
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
                      this.refreshDataFunc.refreshData();
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
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 10 })

          // 心率输入
          Column() {
            Text('心率录入')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 })

            Row() {
              TextInput({ text: this.heartRate.toString(), placeholder: "输入心率" })
                .type(InputType.Number)
                .width('45%')
                .height(50)
                .onChange((value: string) => {
                  this.heartRate = parseInt(value) || 0;
                })
              Text('bpm')
                .fontSize(16)
                .fontColor('#666')
                .width('15%')
                .margin({ left: 10, right: 10 })

              Button('保存心率')
                .width('40%')
                .height(50)
                .backgroundColor('#E74C3C')
                .margin({ bottom: 10 })
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
                      this.refreshDataFunc.refreshData();
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
            .width('100%')
            .margin({ bottom: 10 })

            // 添加批量输入心率按钮
            Button('批量输入心率')
              .width('100%')
              .height(40)
              .backgroundColor('#E74C3C')
              .opacity(0.8)
              .margin({ bottom: 10 })
              .onClick(() => {
                this.heartRateInputTimes = ['08:00'];
                this.heartRateInputValues = ['0'];
                this.heartRateDialogController.open();
              })
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 10 })

          // 睡眠时长输入
          Column() {
            Text('睡眠记录')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 })

            Row() {
              TextInput({ text: "", placeholder: "请输入睡眠时长"})
                .type(InputType.Number)
                .width('45%')
                .height(50)
                .onChange((value: string) => {
                  let sleepValue = parseFloat(value) || 0;
                  if (sleepValue < 0) sleepValue = 0;
                  if (sleepValue > 24) sleepValue = 24;
                  this.sleepHours = sleepValue;
                })
              Text('小时')
                .fontSize(16)
                .width('15%')
                .fontColor('#666')
                .margin({ left: 10, right:10})
              Button('保存时长')
                .width('40%')
                .height(50)
                .backgroundColor('#9B59B6')
                .margin({ bottom: 10 })
                .onClick(async () => {
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
                      this.refreshDataFunc.refreshData();
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
            .width('100%')
            .margin({ bottom: 10 })

            Text('睡眠时长范围: 0-24小时')
              .fontSize(14)
              .fontColor('#888')
              .margin({ bottom: 10 })
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 10 })

          // 饮水量输入
          Column() {
            Text('饮水记录')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 10 })

            Row() {
              TextInput({ text: '', placeholder: "请输入饮水量(ml)" })
                .type(InputType.Number)
                .width('45%')
                .height(50)
                .onChange((value: string) => {
                  this.tempWaterAmount = parseInt(value) || 0;
                })

              Text('ml')
                .fontSize(16)
                .fontColor('#666')
                .width('15%')
                .margin({ left: 10 })
              Button('添加记录')
                .width('40%')
                .height(50)
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
                      this.refreshDataFunc.refreshData();
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
            }
            .width('100%')
            .margin({ bottom: 10 })

            // 添加批量输入饮水量按钮
            Button('批量输入饮水量')
              .width('100%')
              .height(40)
              .backgroundColor('#3498DB')
              .opacity(0.8)
              .margin({ bottom: 10 })
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
                this.refreshDataFunc.refreshData();
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