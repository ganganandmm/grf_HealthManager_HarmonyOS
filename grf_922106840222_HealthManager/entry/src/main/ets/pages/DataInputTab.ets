/**
 * DataInputTab.ets
 * 健康数据录入界面组件
 * 负责用户健康数据(步数、心率、睡眠、饮水量)的录入和保存功能
 */
import { DataInputRow } from '../ComponentAndDialog/myComponents'; // 导入自定义的数据输入行组件
import { SleepRecord, WaterRecord, StepRecord, HeartRateRecord } from '../common/HealthDataModel'; // 导入健康数据模型
import promptAction from '@ohos.promptAction'; // 导入提示框组件
import { hilog } from '@kit.PerformanceAnalysisKit'; // 导入日志组件
import { DatabaseHelper } from '../common/DatabaseHelper'; // 导入数据库助手

// 定义日志标签和域号，用于标识日志来源
export const TAG: string = 'DataInputTab';
const DOMAIN_NUMBER: number = 0xFF00;

/**
 * 文本样式扩展 - 信息提示文本样式
 * 用于显示小号灰色提示文本
 */
@Extend(Text)
function infoText() {
  .fontSize(14)
  .fontColor('#888')
  .margin({ bottom: 10 })
}

/**
 * 文本样式扩展 - 饮水信息文本样式
 * 用于显示蓝色的饮水量信息
 */
@Extend(Text)
function waterInfoText() {
  .fontSize(16)
  .fontColor('#3498DB')
  .margin({ top: 10 })
}

/**
 * 文本样式扩展 - 标题文本样式
 * 用于页面主标题
 */
@Extend(Text)
function titleText() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .margin({ top: 10, bottom: 20 })
}

/**
 * 文本样式扩展 - 副标题文本样式
 * 用于各数据卡片的标题
 */
@Extend(Text)
function subtitleText() {
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .margin({ bottom: 10 })
}

/**
 * 布局扩展 - 卡片容器样式
 * 用于包装各类数据输入区块
 */
@Extend(Column)
function cardContainer() {
  .width('90%')
  .padding(15)
  .borderRadius(8)
  .backgroundColor('#f7f7f7')
  .margin({ bottom: 10 })
}

/**
 * 按钮样式扩展 - 主按钮样式
 * 用于页面主要操作按钮
 */
@Extend(Button)
function primaryButton() {
  .width('100%')
  .height(40)
  .backgroundColor('#27AE60')
  .margin({ bottom: 10 })
}

/**
 * 按钮样式扩展 - 次要按钮样式
 * 用于次要操作按钮，可传入自定义背景色
 * @param bgColor 背景颜色，默认为蓝色
 */
@Extend(Button)
function secondaryButton(bgColor: string = '#3498DB') {
  .width('100%')
  .height(40)
  .backgroundColor(bgColor)
  .margin({ bottom: 10 })
}

/**
 * DataInputTab组件 - 健康数据录入界面
 * 用于用户录入各项健康数据并保存到数据库
 */
@Component
export struct DataInputTab {
  // 通过@Link装饰器连接父组件中的数据，实现双向数据绑定
  @Link userId: number; // 用户ID
  @Link username: string; // 用户名
  @Link currentDate: string; // 当前日期
  @Link totalSteps: number; // 当日总步数
  @Link steps: number; // 当前输入的步数
  @Link heartRate: number; // 当前输入的心率
  @Link sleepHours: number; // 睡眠时长（小时）
  @Link waterAmount: number; // 当日总饮水量
  @Link tempWaterAmount: number; // 临时保存的饮水量输入值
  @Link lastNotifiedSteps: number; // 上次通知的步数值
  @Link lastNotifyWater: number; // 上次通知的饮水量
  @Link heartRateInputTimes: string[]; // 批量输入心率的时间数组
  @Link heartRateInputValues: string[]; // 批量输入心率的值数组
  @Link waterInputTimes: string[]; // 批量输入饮水量的时间数组
  @Link waterInputValues: string[]; // 批量输入饮水量的值数组
  @Link stepInputTimes: string[]; // 批量输入步数的时间数组
  @Link stepInputValues: string[]; // 批量输入步数的值数组

  dbHelper: DatabaseHelper | null = null; // 数据库助手实例
  refreshData: () => Promise<void> = async () => {}; // 刷新数据的回调函数
  checkStepsAndNotify: (steps: number) => void = () => {}; // 检查步数并通知的回调函数
  checkWaterAndNotify: (water: number) => void = () => {}; // 检查饮水量并通知的回调函数
  checkSleepAndNotify: (water: number) => void = () => {}; // 检查睡眠并通知的回调函数
  heartRateDialogController!: CustomDialogController; // 心率批量输入对话框控制器
  waterDialogController!: CustomDialogController; // 饮水量批量输入对话框控制器
  stepDialogController!: CustomDialogController; // 步数批量输入对话框控制器

  /**
   * 构建页面头部区域
   * 显示页面标题
   */
  @Builder
  HeaderSection() {
    Text('健康数据录入')
      .titleText()
  }

  /**
   * 构建步数输入区域
   * 包含步数输入框、保存按钮和批量输入按钮
   */
  @Builder
  StepInputSection() {
    Column() {
      Text('步数录入')
        .subtitleText()
        .alignSelf(ItemAlign.Start)

      Row() {
        // 步数输入框
        TextInput({ text: this.steps.toString() })
          .type(InputType.Number) // 数字输入类型
          .width('60%')
          .height(50)
          .margin({ bottom: 10 })
          .onChange((value: string) => {
            this.steps = parseInt(value) || 0; // 转换为整数，无效值设为0
          })

        // 保存步数按钮
        Button('保存步数')
          .width('40%')
          .height(50)
          .backgroundColor('#1698CE')
          .margin({ bottom: 10, left: '5%' })
          .onClick(async () => {
            if (this.userId > 0) {
              try {
                // 获取当前时间
                const now = new Date();
                const timeStr = now.toTimeString().split(' ')[0].substring(0, 5); // 格式化为 HH:MM

                // 创建新的步数记录
                const record = new StepRecord(this.userId, this.currentDate, timeStr, this.steps);

                // 输出详细日志
                hilog.info(DOMAIN_NUMBER, TAG, `保存步数记录: userId=${record.userId}, date=${record.date}, time=${record.time}, steps=${record.steps}`);

                // 保存记录到数据库
                if (this.dbHelper && await this.dbHelper.insertStepRecord(record)) {
                  promptAction.showToast({ message: '步数保存成功' }); // 成功提示
                } else {
                  promptAction.showToast({ message: '步数保存失败' }); // 失败提示
                }

                // 刷新界面数据
                this.refreshData();
              } catch (error) {
                // 错误处理和日志记录
                const errorMessage: string = error instanceof Error ? error.message : String(error);
                hilog.error(DOMAIN_NUMBER, TAG, `Failed to save step data: ${errorMessage}`);
                promptAction.showToast({ message: '操作失败' });
              }
            } else {
              promptAction.showToast({ message: '用户ID无效' });
            }
            // 检查步数并触发通知
            this.checkStepsAndNotify(this.totalSteps);
          })
      }

      // 批量输入步数按钮
      Button('批量输入步数')
        .width('90%')
        .height(40)
        .backgroundColor('#1698CE')
        .margin({ bottom: 10 })
        .onClick(() => {
          // 初始化输入数组并打开对话框
          this.stepInputTimes = ['08:00']; // 默认时间值
          this.stepInputValues = ['0']; // 默认步数值
          this.stepDialogController.open(); // 打开批量输入对话框
          this.checkStepsAndNotify(this.totalSteps) // 检查步数并通知
        })
    }
    .cardContainer() // 应用卡片容器样式
  }

  /**
   * 构建心率输入区域
   * 包含心率输入组件和批量输入按钮
   */
  @Builder
  HeartRateInputSection() {
    Column() {
      Text('心率录入')
        .subtitleText()
        .alignSelf(ItemAlign.Start)

      // 使用自定义的DataInputRow组件
      DataInputRow({
        title: '心率录入',
        placeholder: '输入心率',
        unit: 'bpm', // 心率单位
        buttonText: '保存心率',
        buttonColor: '#E74C3C', // 红色按钮
        onInputChange: (value: string) => {
          this.heartRate = parseInt(value) || 0; // 转换为整数，无效值设为0
        },
        onButtonClick: async () => {
          if (this.userId > 0) {
            try {
              // 获取当前时间
              const now = new Date();
              const timeStr = now.toTimeString().split(' ')[0].substring(0, 5); // 格式化为 HH:MM

              // 创建新的心率记录（心率可以有多条记录）
              const record = new HeartRateRecord(this.userId, this.currentDate, timeStr, this.heartRate);
              if (this.dbHelper && await this.dbHelper.insertHeartRateRecord(record)) {
                promptAction.showToast({ message: '心率保存成功' }); // 成功提示
              } else {
                promptAction.showToast({ message: '心率保存失败' }); // 失败提示
              }
              // 刷新界面数据
              this.refreshData();
            } catch (error) {
              // 错误处理和日志记录
              const errorMessage: string = error instanceof Error ? error.message : String(error);
              hilog.error(DOMAIN_NUMBER, TAG, `Failed to save heart rate data: ${errorMessage}`);
              promptAction.showToast({ message: '操作失败' });
            }
          } else {
            promptAction.showToast({ message: '用户ID无效' });
          }
        }
      })

      // 批量输入心率按钮
      Button('批量输入心率')
        .secondaryButton('#E74C3C') // 应用红色次要按钮样式
        .opacity(0.8)
        .onClick(() => {
          // 初始化输入数组并打开对话框
          this.heartRateInputTimes = ['08:00']; // 默认时间值
          this.heartRateInputValues = ['0']; // 默认心率值
          this.heartRateDialogController.open(); // 打开批量输入对话框
        })
    }
    .cardContainer() // 应用卡片容器样式
  }

  /**
   * 构建睡眠输入区域
   * 包含睡眠时长输入组件和提示信息
   */
  @Builder
  SleepInputSection() {
    Column() {
      Text('睡眠记录')
        .subtitleText()
        .alignSelf(ItemAlign.Start)

      // 使用自定义的DataInputRow组件
      DataInputRow({
        title: '睡眠记录',
        placeholder: '请输入睡眠时长 (可带小数点)',
        unit: '小时',
        buttonText: '保存时长',
        buttonColor: '#9B59B6', // 紫色按钮
        inputType: InputType.NUMBER_DECIMAL, // 数字和小数点键盘
        onInputChange: (value: string) => {
          // 明确使用parseFloat处理小数点情况
          let sleepValue = parseFloat(value) || 0;
          // 限制睡眠时间范围
          if (sleepValue < 0) {
            sleepValue = 0;
          }
          if (sleepValue > 24) {
            sleepValue = 24;
          }
          // 保留一位小数
          this.sleepHours = Math.round(sleepValue * 10) / 10;
          this.checkSleepAndNotify(this.sleepHours); // 检查睡眠并通知
        },
        onButtonClick: async () => {
          if (this.userId > 0) {
            // 验证睡眠时长是否在有效范围内
            if (this.sleepHours < 0 || this.sleepHours > 24) {
              promptAction.showToast({ message: '睡眠时长必须在0-24小时之间' });
              return;
            }

            try {
              // 查询是否已有当日记录
              if (!this.dbHelper) return;
              const sleepRecords = await this.dbHelper.getSleepRecords(this.userId, this.currentDate);

              // 保持小数点精度，转换为分钟时再取整
              const sleepMinutes = Math.round(this.sleepHours * 60);
              hilog.info(DOMAIN_NUMBER, TAG, `保存睡眠时长: ${this.sleepHours}小时 (${sleepMinutes}分钟)`);

              if (sleepRecords.length > 0) {
                // 如果已有记录则更新
                const record = sleepRecords[0];
                record.duration = sleepMinutes;
                if (this.dbHelper && await this.dbHelper.updateSleepRecord(record)) {
                  promptAction.showToast({ message: '睡眠时长更新成功' });
                } else {
                  promptAction.showToast({ message: '睡眠时长更新失败' });
                }
              } else {
                // 如果没有记录则创建新记录
                const record = new SleepRecord(this.userId, this.currentDate, sleepMinutes);
                if (this.dbHelper && await this.dbHelper.insertSleepRecord(record)) {
                  promptAction.showToast({ message: '睡眠时长保存成功' });
                } else {
                  promptAction.showToast({ message: '睡眠时长保存失败' });
                }
              }
              // 刷新界面数据
              this.refreshData();
            } catch (error) {
              // 错误处理和日志记录
              const errorMessage: string = error instanceof Error ? error.message : String(error);
              hilog.error(DOMAIN_NUMBER, TAG, `Failed to save sleep data: ${errorMessage}`);
              promptAction.showToast({ message: '操作失败' });
            }
          } else {
            promptAction.showToast({ message: '用户ID无效' });
          }
        }
      })
      // 睡眠时长范围提示
      Text('睡眠时长范围: 0-24小时')
        .infoText()
    }
    .cardContainer() // 应用卡片容器样式
  }

  /**
   * 构建饮水输入区域
   * 包含饮水量输入组件、批量输入按钮和总饮水量显示
   */
  @Builder
  WaterInputSection() {
    Column() {
      Text('饮水记录')
        .subtitleText()
        .alignSelf(ItemAlign.Start)

      // 使用自定义的DataInputRow组件
      DataInputRow({
        title: '饮水记录',
        placeholder: '请输入饮水量(ml)',
        unit: 'ml', // 饮水量单位
        buttonText: '添加记录',
        buttonColor: '#3498DB', // 蓝色按钮
        onInputChange: (value: string) => {
          this.tempWaterAmount = parseInt(value) || 0; // 转换为整数，无效值设为0
        },
        onButtonClick: async () => {
          if (this.userId > 0 && this.tempWaterAmount > 0) {
            try {
              // 获取当前时间
              const now = new Date();
              const timeStr = now.toTimeString().split(' ')[0].substring(0, 5); // 格式化为 HH:MM

              // 创建新的饮水记录
              const record = new WaterRecord(this.userId, this.currentDate, timeStr, this.tempWaterAmount);
              if (this.dbHelper && await this.dbHelper.insertWaterRecord(record)) {
                promptAction.showToast({ message: '饮水记录添加成功' });
                // 重置临时水量
                this.tempWaterAmount = 0;
              } else {
                promptAction.showToast({ message: '饮水记录添加失败' });
              }
              // 刷新界面数据
              this.refreshData();
              this.checkWaterAndNotify(this.waterAmount); // 检查饮水量并通知
            } catch (error) {
              // 错误处理和日志记录
              const errorMessage: string = error instanceof Error ? error.message : String(error);
              hilog.error(DOMAIN_NUMBER, TAG, `Failed to save water data: ${errorMessage}`);
              promptAction.showToast({ message: '操作失败' });
            }
          } else if (this.tempWaterAmount <= 0) {
            promptAction.showToast({ message: '请输入有效的饮水量' });
          } else {
            promptAction.showToast({ message: '用户ID无效' });
          }
        }
      })

      // 批量输入饮水量按钮
      Button('批量输入饮水量')
        .secondaryButton('#3498DB') // 应用蓝色次要按钮样式
        .opacity(0.8)
        .onClick(() => {
          // 初始化输入数组并打开对话框
          this.waterInputTimes = ['08:00']; // 默认时间值
          this.waterInputValues = ['0']; // 默认饮水量值
          this.waterDialogController.open(); // 打开批量输入对话框
          this.checkWaterAndNotify(this.waterAmount); // 检查饮水量并通知
        })

      // 显示今日总饮水量
      Text(`今日总饮水量: ${this.waterAmount} ml`)
        .waterInfoText() // 应用水量信息文本样式
    }
    .cardContainer() // 应用卡片容器样式
    .margin({ bottom: 20 })
  }

  /**
   * 构建刷新按钮区域
   * 用于刷新页面所有数据
   */
  @Builder
  RefreshButton() {
    Column() {
      Button('刷新所有数据')
        .primaryButton() // 应用主按钮样式
        .backgroundColor('#2ECC71') // 绿色按钮
        .onClick(() => {
          this.refreshData(); // 调用刷新数据函数
          promptAction.showToast({ message: '数据已刷新' });
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 20 })
  }

  /**
   * 构建整个组件的UI结构
   * 包含头部、滚动区域和所有数据输入区块
   */
  build() {
    Column() {
      this.HeaderSection() // 头部区域

      Scroll() { // 创建可滚动区域
        Column() {
          this.StepInputSection() // 步数输入区域
          this.HeartRateInputSection() // 心率输入区域
          this.SleepInputSection() // 睡眠输入区域
          this.WaterInputSection() // 饮水输入区域
          this.RefreshButton() // 刷新按钮区域
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .scrollBar(BarState.Auto) // 自动显示滚动条
      .width('100%')
      .layoutWeight(1) // 占用剩余空间
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}