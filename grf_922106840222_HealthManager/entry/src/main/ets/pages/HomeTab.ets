import { HealthDataCard, HeartRateRecordItem, WaterRecordItem } from './myComponents';
import { HeartRateRecord, WaterRecord } from '../common/HealthDataModel';
export const TAG: string = 'HomeTab';
@Extend(Text)
function titleText() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .margin({ top: 10, bottom: 20 })
}

@Extend(Text)
function subtitleText() {
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .margin({ bottom: 10 })
}

@Extend(Text)
function labelText() {
  .fontSize(16)
  .fontColor('#666')
}

@Extend(Text)
function valueText() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
}

@Extend(Column)
function cardContainer() {
  .width('90%')
  .padding(15)
  .borderRadius(8)
  .backgroundColor('#f7f7f7')
  .margin({ bottom: 10 })
}

@Component
export struct HomeTab {
  @Link username: string;
  @Link userId: number;
  @Link totalSteps: number;
  @Link heartRate: number;
  @Link sleepHours: number;
  @Link waterAmount: number;
  @Link currentDate: string;
  @Link receivedHealthData: string;
  @Link heartRateRecords: HeartRateRecord[];
  @Link waterRecords: WaterRecord[];
  @Link steps: number;
  private refreshData: () => Promise<void> = async () => {};
  private shareHealthData: () => Promise<void> = async () => {};
  private ClickJumpToShowData: () => void = () => {};

  build() {
    Scroll() {
      Column() {
        Text('今日健康数据概览')
          .titleText()

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

        // Pull to refresh text
        Text('下拉刷新数据')
          .fontSize(14)
          .fontColor('#888')
          .margin({ top: 5, bottom: 15 })

        // 显示接收到的健康数据
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

        // 最近饮水记录
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

        //心率记录
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
      // Implement pull-to-refresh functionality
      if (offset <= -100) { // If pulled down more than 100px
        this.refreshData();
        return { offsetRemain: 0 };
      }
      return { offsetRemain: offset };
    })
  }
}