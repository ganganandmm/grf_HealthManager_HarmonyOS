import { promptAction } from "@kit.ArkUI";              // 导入提示操作功能，用于显示Toast等UI提示
import { hilog } from "@kit.PerformanceAnalysisKit";   // 导入日志功能，用于记录调试信息

/**
 * 心率输入对话框组件
 * 用于批量输入多条心率记录，包含时间和心率值
 */
@CustomDialog                                         // 自定义对话框装饰器
@Component                                            // 组件装饰器
export struct HeartRateInputDialog {
  @State heartRateInputTimes: string[] = [];          // 存储心率记录的时间数组
  @State heartRateInputValues: string[] = [];         // 存储心率值数组
  @State index: number = 0;                           // 当前索引值
  private controller: CustomDialogController;         // 对话框控制器，用于控制对话框的显示和隐藏
  private addHeartRateInputRow!: () => void;          // 添加心率记录行的回调函数，由父组件传入
  private removeHeartRateInputRow!: (index: number) => void;  // 删除心率记录行的回调函数
  private saveMultiHeartRates!: () => Promise<void>;  // 保存多条心率记录的回调函数

  /**
   * 组件即将出现时的生命周期函数
   * 确保至少有一行心率输入记录
   */
  aboutToAppear() {
    // 确保至少有一行输入
    if (this.heartRateInputTimes.length === 0) {
      this.heartRateInputTimes = ['08:00'];           // 默认时间设为08:00
      this.heartRateInputValues = ['0'];              // 默认心率值设为0
    }
  }

  build() {
    Column() {
      // 标题文本
      Text('批量心率录入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 20 })

      // 心率输入行列表，使用滚动视图包装
      Scroll() {
        Column() {
          // 遍历心率时间数组，为每条记录创建输入行
          ForEach(this.heartRateInputTimes, (time: string, index: number) => {
            Row() {
              // 时间选择器，用于选择心率记录的时间
              TimePicker({
                selected: new Date(`2023-01-01T${this.heartRateInputTimes[index] || '08:00'}:00`)
              })
                .useMilitaryTime(true)                // 使用24小时制
                .onChange((value: TimePickerResult) => {
                  // 格式化时间，确保两位数表示
                  const hours = String(value.hour).padStart(2, '0');
                  const minutes = String(value.minute).padStart(2, '0');
                  this.heartRateInputTimes[index] = `${hours}:${minutes}`;
                })
                .margin({ right: 10 })
                .width('40%')

              // 心率值输入框
              TextInput({
                text: this.heartRateInputValues[index],
                placeholder: "心率"
              })
                .type(InputType.Number)               // 设置输入类型为数字
                .width('40%')
                .height(50)
                .onChange((value: string) => {
                  this.heartRateInputValues[index] = value;
                })

              // 删除按钮，用于删除当前心率记录行
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
                this.removeHeartRateInputRow(index);  // 调用删除函数并传入索引
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)   // 水平方向均匀分布
            .alignItems(VerticalAlign.Center)         // 垂直方向居中对齐
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

      // 添加心率记录按钮
      Button('添加心率记录')
        .width('100%')
        .height(40)
        .margin({ top: 10, bottom: 10 })
        .backgroundColor('#27AE60')
        .onClick(() => {
          this.addHeartRateInputRow();                // 调用添加行函数
        })

      // 底部操作按钮行
      Row() {
        // 取消按钮
        Button('取消')
          .width('45%')
          .height(40)
          .backgroundColor('#95a5a6')
          .onClick(() => {
            this.controller.close();
          })

        // 保存按钮
        Button('保存')
          .width('45%')
          .height(40)
          .backgroundColor('#E74C3C')
          .onClick(async () => {
            await this.saveMultiHeartRates();         // 调用保存函数
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

/**
 * 饮水记录输入对话框组件
 * 用于批量输入多条饮水记录，包含时间和饮水量
 */
@Component
@CustomDialog
export struct WaterInputDialog {
  @State waterInputTimes: string[] = [];              // 存储饮水记录的时间数组
  @State waterInputValues: string[] = [];             // 存储饮水量数组
  @State index: number = 0;                           // 当前索引值
  private controller: CustomDialogController;         // 对话框控制器
  private addWaterInputRow!: () => void;              // 添加饮水记录行的回调函数
  private removeWaterInputRow!: (index: number) => void;  // 删除饮水记录行的回调函数
  private saveMultiWaterRecords!: () => Promise<void>;    // 保存多条饮水记录的回调函数

  /**
   * 组件即将出现时的生命周期函数
   * 确保至少有一行饮水记录输入
   */
  aboutToAppear() {
    // 确保至少有一行输入
    if (this.waterInputTimes.length === 0) {
      this.waterInputTimes = ['08:00'];               // 默认时间设为08:00
      this.waterInputValues = ['0'];                  // 默认饮水量设为0
    }
  }

  build() {
    Column() {
      // 标题文本
      Text('批量饮水记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 20 })

      // 饮水量输入行列表，使用滚动视图包装
      Scroll() {
        Column() {
          // 遍历饮水时间数组，为每条记录创建输入行
          ForEach(this.waterInputTimes, (time: string, index: number) => {
            Row() {
              // 时间选择器，用于选择饮水记录的时间
              TimePicker({
                selected: new Date(`2023-01-01T${this.waterInputTimes[index] || '08:00'}:00`)
              })
                .useMilitaryTime(true)                // 使用24小时制
                .onChange((value: TimePickerResult) => {
                  // 格式化时间，确保两位数表示
                  const hours = String(value.hour).padStart(2, '0');
                  const minutes = String(value.minute).padStart(2, '0');
                  this.waterInputTimes[index] = `${hours}:${minutes}`;
                })
                .margin({ right: 10 })
                .width('40%')

              // 饮水量输入框
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

              // 删除按钮，用于删除当前饮水记录行
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

      // 添加饮水记录按钮
      Button('添加饮水记录')
        .width('100%')
        .height(40)
        .margin({ top: 10, bottom: 10 })
        .backgroundColor('#27AE60')
        .onClick(() => {
          this.addWaterInputRow();
        })

      // 底部操作按钮行
      Row() {
        // 取消按钮
        Button('取消')
          .width('45%')
          .height(40)
          .backgroundColor('#95a5a6')
          .onClick(() => {
            this.controller.close();
          })

        // 保存按钮
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

/**
 * 步数记录输入对话框组件
 * 用于批量输入多条步数记录，包含时间和步数值
 */
@CustomDialog
export struct StepInputDialog {
  @State stepInputTimes: string[] = [];               // 存储步数记录的时间数组
  @State stepInputValues: string[] = [];              // 存储步数值数组
  @State index: number = 0;                           // 当前索引值
  private controller: CustomDialogController;         // 对话框控制器
  private addStepInputRow!: () => void;               // 添加步数记录行的回调函数
  private removeStepInputRow!: (index: number) => void;   // 删除步数记录行的回调函数
  private saveMultiStepRecords!: () => Promise<void>;     // 保存多条步数记录的回调函数

  /**
   * 组件即将出现时的生命周期函数
   * 确保至少有一行步数记录输入，并记录日志
   */
  aboutToAppear() {
    // 确保至少有一行输入
    if (this.stepInputTimes.length === 0) {
      this.stepInputTimes = ['08:00'];                // 默认时间设为08:00
      this.stepInputValues = ['0'];                   // 默认步数值设为0
    }
    // 记录日志，表明对话框即将出现，包含初始数据
    hilog.info(0x0000, 'StepInputDialog', 'Dialog about to appear with initial data');
  }

  build() {
    Column() {
      // 标题文本
      Text('批量步数录入')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 20 })

      // 步数输入行列表，使用滚动视图包装
      Scroll() {
        Column() {
          // 遍历步数时间数组，为每条记录创建输入行
          ForEach(this.stepInputTimes, (time: string, index: number) => {
            Row() {
              // 时间选择器，用于选择步数记录的时间
              TimePicker({
                selected: new Date(`2023-01-01T${this.stepInputTimes[index] || '08:00'}:00`)
              })
                .useMilitaryTime(true)                // 使用24小时制
                .onChange((value: TimePickerResult) => {
                  // 格式化时间，确保两位数表示
                  const hours = String(value.hour).padStart(2, '0');
                  const minutes = String(value.minute).padStart(2, '0');
                  this.stepInputTimes[index] = `${hours}:${minutes}`;
                  // 记录时间变更日志
                  hilog.info(0x0000, 'StepInputDialog', `Time changed at index ${index}: ${this.stepInputTimes[index]}`);
                })
                .margin({ right: 10 })
                .width('40%')

              // 步数输入框
              TextInput({
                text: this.stepInputValues[index],
                placeholder: '步数'
              })
                .width('40%')
                .type(InputType.Number)               // 设置输入类型为数字
                .onChange((value: string) => {
                  this.stepInputValues[index] = value;
                  // 记录步数值变更日志
                  hilog.info(0x0000, 'StepInputDialog', `Step value changed at index ${index}: ${this.stepInputValues[index]}`);
                })

              // 删除按钮，用于删除当前步数记录行
              Button({
                type: ButtonType.Circle,
                stateEffect: true
              }) {
                Image($r('app.media.delete'))         // 显示删除图标
                  .width(20)
                  .height(20)
              }
              .width(28)
              .height(28)
              .backgroundColor('#f5f5f5')
              .margin({ left: 10 })
              .onClick(() => {
                // 记录删除操作日志
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

      // 添加更多记录按钮
      Button('添加更多记录')
        .width('100%')
        .height(40)
        .margin({ top: 10, bottom: 20 })
        .backgroundColor('#27AE60')
        .onClick(() => {
          // 记录添加操作日志
          hilog.info(0x0000, 'StepInputDialog', 'Adding new row');
          this.addStepInputRow();                     // 调用添加行函数
        })

      // 底部操作按钮行
      Row() {
        // 取消按钮
        Button('取消')
          .width('45%')
          .height(40)
          .backgroundColor('#E0E0E0')
          .fontColor('#333')
          .onClick(() => {
            // 记录取消操作日志
            hilog.info(0x0000, 'StepInputDialog', 'Cancel button clicked');
            this.controller.close();                  // 关闭对话框
          })

        // 保存按钮
        Button('保存')
          .width('45%')
          .height(40)
          .backgroundColor('#1698CE')
          .onClick(async () => {
            // 记录保存操作日志
            hilog.info(0x0000, 'StepInputDialog', 'Save button clicked, calling saveMultiStepRecords');
            try {
              await this.saveMultiStepRecords();      // 调用保存函数
              // 记录保存成功日志
              hilog.info(0x0000, 'StepInputDialog', 'saveMultiStepRecords completed, closing dialog');
              this.controller.close();                // 保存完成后关闭对话框
            } catch (error) {
              // 记录保存失败错误日志
              hilog.error(0x0000, 'StepInputDialog', `Error in save: ${error}`);
              // 显示保存失败提示
              promptAction.showToast({ message: '保存失败，请重试' });
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)         // 按钮水平均匀分布
    }
    .width('90%')
    .padding(20)
    .borderRadius(16)
    .backgroundColor(Color.White)                     // 对话框背景色
  }
}