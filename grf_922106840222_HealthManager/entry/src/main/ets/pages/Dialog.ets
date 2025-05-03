import { promptAction } from "@kit.ArkUI";
import { hilog } from "@kit.PerformanceAnalysisKit";

@CustomDialog
@Component
export struct HeartRateInputDialog {
  @State heartRateInputTimes: string[] = [];
  @State heartRateInputValues: string[] = [];
  @State index: number = 0;
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
      Scroll() {
        Column() {
          ForEach(this.heartRateInputTimes, (time: string, index: number) => {
            Row() {
              // 使用TimePicker替代TextInput
              TimePicker({
                selected: new Date(`2023-01-01T${this.heartRateInputTimes[index] || '08:00'}:00`)
              })
                .useMilitaryTime(true) // 使用24小时制
                .onChange((value: TimePickerResult) => {
                  const hours = String(value.hour).padStart(2, '0');
                  const minutes = String(value.minute).padStart(2, '0');
                  this.heartRateInputTimes[index] = `${hours}:${minutes}`;
                })
                .margin({ right: 10 })
                .width('40%')

              // 心率值输入
              TextInput({
                text: this.heartRateInputValues[index],
                placeholder: "心率"
              })
                .type(InputType.Number)
                .width('40%')
                .height(50)
                .onChange((value: string) => {
                  this.heartRateInputValues[index] = value;
                })

              // 删除按钮
              Button({
                type: ButtonType.Circle,
                stateEffect: true
              }) {
                Image($r('app.media.delete'))
                  .width(20)
                  .height(20)
              }
              .width(28)
              .height(28)
              .backgroundColor('#f5f5f5')
              .margin({ left: 10 })
              .onClick(() => {
                this.removeHeartRateInputRow(index);
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .padding(10)
            .margin({ bottom: 10 })
            .borderRadius(8)
            .backgroundColor('#f0f0f0')
          })
        }
        .width('100%')
      }
      .height('60%')
      .width('100%')

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
    .width('90%')
    .padding(20)
    .borderRadius(16)
    .backgroundColor(Color.White)
  }
}

@Component
@CustomDialog
export struct WaterInputDialog {
  @State waterInputTimes: string[] = [];
  @State waterInputValues: string[] = [];
  @State index: number = 0;
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
      Scroll() {
        Column() {
          ForEach(this.waterInputTimes, (time: string, index: number) => {
            Row() {
              // 使用TimePicker替代TextInput
              TimePicker({
                selected: new Date(`2023-01-01T${this.waterInputTimes[index] || '08:00'}:00`)
              })
                .useMilitaryTime(true) // 使用24小时制
                .onChange((value: TimePickerResult) => {
                  const hours = String(value.hour).padStart(2, '0');
                  const minutes = String(value.minute).padStart(2, '0');
                  this.waterInputTimes[index] = `${hours}:${minutes}`;
                })
                .margin({ right: 10 })
                .width('40%')

              // 饮水量输入
              TextInput({
                text: this.waterInputValues[index],
                placeholder: "饮水量(ml)"
              })
                .type(InputType.Number)
                .width('40%')
                .height(50)
                .onChange((value: string) => {
                  this.waterInputValues[index] = value;
                })

              // 删除按钮
              Button({
                type: ButtonType.Circle,
                stateEffect: true
              }) {
                Image($r('app.media.delete'))
                  .width(20)
                  .height(20)
              }
              .width(28)
              .height(28)
              .backgroundColor('#f5f5f5')
              .margin({ left: 10 })
              .onClick(() => {
                this.removeWaterInputRow(index);
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .padding(10)
            .margin({ bottom: 10 })
            .borderRadius(8)
            .backgroundColor('#f0f0f0')
          })
        }
        .width('100%')
      }
      .height('60%')
      .width('100%')

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
    .width('90%')
    .padding(20)
    .borderRadius(16)
    .backgroundColor(Color.White)
  }
}


@CustomDialog
export struct StepInputDialog {
  @State stepInputTimes: string[] = [];
  @State stepInputValues: string[] = [];
  @State index: number = 0;
  private controller: CustomDialogController;
  private addStepInputRow!: () => void;
  private removeStepInputRow!: (index: number) => void;
  private saveMultiStepRecords!: () => Promise<void>;

  aboutToAppear() {
    // 确保至少有一行输入
    if (this.stepInputTimes.length === 0) {
      this.stepInputTimes = ['08:00'];
      this.stepInputValues = ['0'];
    }
    hilog.info(0x0000, 'StepInputDialog', 'Dialog about to appear with initial data');
  }

  build() {
    Column() {
      Text('批量步数录入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 20 })

      Scroll() {
        Column() {
          ForEach(this.stepInputTimes, (time: string, index: number) => {
            Row() {
              // 使用TimePicker替代TextClock
              TimePicker({
                selected: new Date(`2023-01-01T${this.stepInputTimes[index] || '08:00'}:00`)
              })
                .useMilitaryTime(true) // 使用24小时制
                .onChange((value: TimePickerResult) => {
                  const hours = String(value.hour).padStart(2, '0');
                  const minutes = String(value.minute).padStart(2, '0');
                  this.stepInputTimes[index] = `${hours}:${minutes}`;
                  hilog.info(0x0000, 'StepInputDialog', `Time changed at index ${index}: ${this.stepInputTimes[index]}`);
                })
                .margin({ right: 10 })
                .width('40%')

              // Step count input
              TextInput({
                text: this.stepInputValues[index],
                placeholder: '步数'
              })
                .width('40%')
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.stepInputValues[index] = value;
                  hilog.info(0x0000, 'StepInputDialog', `Step value changed at index ${index}: ${this.stepInputValues[index]}`);
                })

              // Remove button
              Button({
                type: ButtonType.Circle,
                stateEffect: true
              }) {
                Image($r('app.media.delete'))
                  .width(20)
                  .height(20)
              }
              .width(28)
              .height(28)
              .backgroundColor('#f5f5f5')
              .margin({ left: 10 })
              .onClick(() => {
                hilog.info(0x0000, 'StepInputDialog', `Removing row at index ${index}`);
                this.removeStepInputRow(index);
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .padding(10)
            .margin({ bottom: 10 })
            .borderRadius(8)
            .backgroundColor('#f0f0f0')
          }, (item: string, index: number) => index.toString())
        }
        .width('100%')
      }
      .height('60%')
      .width('100%')

      // Add new row button
      Button('添加更多记录')
        .width('100%')
        .height(40)
        .margin({ top: 10, bottom: 20 })
        .backgroundColor('#27AE60')
        .onClick(() => {
          hilog.info(0x0000, 'StepInputDialog', 'Adding new row');
          this.addStepInputRow();
        })

      // Action buttons
      Row() {
        Button('取消')
          .width('45%')
          .height(40)
          .backgroundColor('#E0E0E0')
          .fontColor('#333')
          .onClick(() => {
            hilog.info(0x0000, 'StepInputDialog', 'Cancel button clicked');
            this.controller.close();
          })

        Button('保存')
          .width('45%')
          .height(40)
          .backgroundColor('#1698CE')
          .onClick(async () => {
            hilog.info(0x0000, 'StepInputDialog', 'Save button clicked, calling saveMultiStepRecords');
            try {
              await this.saveMultiStepRecords();
              hilog.info(0x0000, 'StepInputDialog', 'saveMultiStepRecords completed, closing dialog');
              this.controller.close();
            } catch (error) {
              hilog.error(0x0000, 'StepInputDialog', `Error in save: ${error}`);
              promptAction.showToast({ message: '保存失败，请重试' });
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('90%')
    .padding(20)
    .borderRadius(16)
    .backgroundColor(Color.White)
  }
}