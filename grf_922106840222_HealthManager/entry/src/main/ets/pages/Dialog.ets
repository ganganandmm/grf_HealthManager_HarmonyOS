
@CustomDialog
@Component
export  struct HeartRateInputDialog {
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


@Component
@CustomDialog
export  struct WaterInputDialog {
  @State waterInputTimes: string[] = [];
  @State waterInputValues: string[] = [];
  private controller: CustomDialogController;
  private addWaterInputRow!: () => void; // Add the ! operator
  private removeWaterInputRow!: (index: number) => void; // Add the ! operator
  private saveMultiWaterRecords!: () => Promise<void>; // Add the ! operator

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
