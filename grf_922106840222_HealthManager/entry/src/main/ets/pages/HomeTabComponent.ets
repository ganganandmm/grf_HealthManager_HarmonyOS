// HomeTabComponent.ets
import { HeartRateRecord, WaterRecord } from '../common/HealthDataModel';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RefreshDataFunc, ShareHealthDataFunc } from './FunctionInterfaces';

const TAG: string = 'HomeTab';

interface GeneratedObjectLiteralInterface_1 {
  username: string;
  userId: string;
  steps: string;
  heartRate: string;
  sleepHours: string;
  waterAmount: string;
  date: string;
}

@Component
export struct HomeTabComponent {
  @Link username: string;
  @Link userId: number;
  @Link steps: number;
  @Link heartRate: number;
  @Link sleepHours: number;
  @Link waterAmount: number;
  @Link waterRecords: WaterRecord[];
  @Link currentDate: string;
  @Link receivedHealthData: string;
  @Link heartRateRecords: HeartRateRecord[];
  @Link lastUpdateTime: number;

  // 需要提供的方法
  @Prop refreshDataFunc: RefreshDataFunc;
  @Prop shareHealthDataFunc: ShareHealthDataFunc;

  ClickJumpToShowData() {
    this.refreshDataFunc.refreshData().then(() => {
      const routerParams: GeneratedObjectLiteralInterface_1 = {
        username: this.username,
        userId: this.userId.toString(),
        steps: this.steps.toString(),
        heartRate: this.heartRate.toString(),
        sleepHours: this.sleepHours.toString(),
        waterAmount: this.waterAmount.toString(),
        date: this.currentDate // 添加日期参数
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

  build() {
    Scroll() {
      Column() {
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
            Text('最近心率')
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
              this.shareHealthDataFunc.shareHealthData();
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

        Divider()
          .width('90%')
          .height(1)
          .backgroundColor('#ddd')

        //心率记录
        Column() {
          Text('今日心率记录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 10 })
            .alignSelf(ItemAlign.Start)

          List() {
            ForEach(this.heartRateRecords, (item: HeartRateRecord) => {
              ListItem() {
                Row() {
                  Text(item.time)
                    .fontSize(16)
                    .width('40%')
                  Text(`${item.rate} 次/分`)
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
        this.refreshDataFunc.refreshData();
        return { offsetRemain: 0 };
      }
      return { offsetRemain: offset };
    })
  }
}