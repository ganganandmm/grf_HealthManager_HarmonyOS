/**
 * HomeTab.ets - 健康应用首页标签页组件
 *
 * 导入相关组件和数据模型
 */
import { HealthDataCard, HeartRateRecordItem, WaterRecordItem } from '../ComponentAndDialog/myComponents';
import { HeartRateRecord, WaterRecord } from '../common/HealthDataModel';
export const TAG: string = 'HomeTab';

/**
 * 文本样式扩展，定义标题文本样式
 */
@Extend(Text)
function titleText() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .margin({ top: 10, bottom: 20 })
}

/**
 * 文本样式扩展，定义子标题文本样式
 */
@Extend(Text)
function subtitleText() {
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .margin({ bottom: 10 })
}

/**
 * 文本样式扩展，定义标签文本样式
 */
@Extend(Text)
function labelText() {
  .fontSize(16)
  .fontColor('#666')
}

/**
 * 文本样式扩展，定义数值文本样式
 */
@Extend(Text)
function valueText() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
}

/**
 * 容器样式扩展，定义卡片容器样式
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
 * HomeTab组件 - 应用首页主组件
 */
@Component
export struct HomeTab {
  // 数据绑定属性，使用@Link装饰器实现与父组件的双向数据绑定
  @Link username: string;          // 用户名
  @Link userId: number;            // 用户ID
  @Link totalSteps: number;        // 总步数
  @Link heartRate: number;         // 心率
  @Link sleepHours: number;        // 睡眠时长
  @Link waterAmount: number;       // 饮水量
  @Link currentDate: string;       // 当前日期
  @Link receivedHealthData: string; // 接收到的健康数据
  @Link heartRateRecords: HeartRateRecord[]; // 心率记录列表
  @Link waterRecords: WaterRecord[];         // 饮水记录列表
  @Link steps: number;             // 步数

  // 功能回调函数
  private refreshData: () => Promise<void> = async () => {};      // 刷新数据
  private shareHealthData: () => Promise<void> = async () => {};  // 分享健康数据
  private ClickJumpToShowData: () => void = () => {};            // 跳转查看详细数据

  /**
   * 构建UI界面
   */
  build() {
    Scroll() {
      Column() {
        // 页面标题
        Text('今日健康数据概览')
          .titleText()

        // 步数和心率数据卡片行
        Row() {
          HealthDataCard({
            title: '步数',
            value: this.totalSteps.toString(),
            color: '#1698CE'
          })

          HealthDataCard({
            title: '最近心率',
            value: this.heartRate.toString(),
            unit: 'bpm',
            color: '#E74C3C'
          })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 10, bottom: 20 })

        // 睡眠和饮水量数据卡片行
        Row() {
          HealthDataCard({
            title: '睡眠时长',
            value: this.sleepHours.toFixed(1),
            unit: '小时',
            color: '#9B59B6'
          })

          HealthDataCard({
            title: '饮水量',
            value: this.waterAmount.toString(),
            unit: 'ml',
            color: '#3498DB'
          })
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

        // 下拉刷新提示文本
        Text('下拉刷新数据')
          .fontSize(14)
          .fontColor('#888')
          .margin({ top: 5, bottom: 15 })

        // 条件渲染：显示接收到的健康数据（如果有）
        if (this.receivedHealthData) {
          Column() {
            Text('接收到的健康数据')
              .subtitleText()
              .alignSelf(ItemAlign.Start)

            Text(this.receivedHealthData)
              .fontSize(14)
              .fontColor('#666')
              .width('100%')
          }
          .cardContainer()
          .margin({ top: 10, bottom: 20 })
        }

        // 饮水记录列表
        Column() {
          Text('今日饮水记录')
            .subtitleText()
            .alignSelf(ItemAlign.Start)

          List() {
            ForEach(this.waterRecords, (item: WaterRecord) => {
              ListItem() {
                WaterRecordItem({ record: item })
              }
            })
          }
          .width('100%')
          .height(150)
          .divider({ strokeWidth: 1, color: '#eeeeee' })
        }
        .cardContainer()
        .margin({ top: 10, bottom: 20 })

        Divider()
          .width('90%')
          .height(1)
          .backgroundColor('#ddd')

        // 心率记录列表
        Column() {
          Text('今日心率记录')
            .subtitleText()
            .alignSelf(ItemAlign.Start)

          List() {
            ForEach(this.heartRateRecords, (item: HeartRateRecord) => {
              ListItem() {
                HeartRateRecordItem({ record: item })
              }
            })
          }
          .width('100%')
          .height(150)
          .divider({ strokeWidth: 1, color: '#eeeeee' })
        }
        .cardContainer()
        .margin({ top: 10, bottom: 20 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .scrollBar(BarState.Auto)
    .onScrollFrameBegin((offset: number) => {
      // 下拉刷新实现：当下拉距离超过100px时触发刷新
      if (offset <= -100) {
        this.refreshData();
        return { offsetRemain: 0 };
      }
      return { offsetRemain: offset };
    })
  }
}