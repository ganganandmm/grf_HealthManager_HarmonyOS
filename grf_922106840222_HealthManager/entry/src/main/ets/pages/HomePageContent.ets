import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { JSON } from '@kit.ArkTS';
import common from '@ohos.app.ability.common';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from '../common/HealthDataModel';
import Want from '@ohos.app.ability.Want'
import {TAG} from './mainHome'
interface HealthData {
  userId: number;
  username: string;
  date: string;
  steps: number;
  heartRate: number;
  sleepHours: number;
  waterAmount: number;
}
interface RouterParams {
  username: string;
  userId: string;
  steps: string;
  heartRate: string;
  sleepHours: string;
  waterAmount: string;
  date: string;
}
@Component
struct HomePageContent {
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
  private refreshInterval: number = 0; // For periodic refresh
  @State heartRateRecords: HeartRateRecord[] = [];//心率记录
  async shareHealthData() {
    try {
      // Before sharing, refresh data to ensure it's up to date
      await this.refreshData();

      // 创建健康数据对象
      const healthData: HealthData = {
        userId: this.userId,
        username: this.username,
        date: this.currentDate,
        steps: this.steps,
        heartRate: this.heartRate,
        sleepHours: this.sleepHours,
        waterAmount: this.waterAmount
      };

      // 将数据转换为JSON字符串
      const dataString = JSON.stringify(healthData);
      const want: Want = {
        bundleName: 'com.example.target', // Replace with target app
        abilityName: 'EntryAbility',      // Replace with target ability
        moduleName: 'entry',              // Optional module name
        parameters: {                     // Use a plain object for parameters
          healthData: dataString
        }
      };
      this.context.startAbility(want)
        .then(() => {
          hilog.info(0x0000, TAG, 'Health data shared successfully');
        })
        .catch((err: Error) => {
          hilog.error(0x0000, TAG, `Failed to start ability: ${err.message}`);
        });
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to share health data: ${errorMessage}`);
    }
  }
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
      const stepRecords = await this.dbHelper.getStepRecords(this.userId, this.currentDate);
      if (stepRecords.length > 0) {
        this.steps = stepRecords[0].steps;
      } else {
        this.steps = 0;
      }

      const heartRateRecords = await this.dbHelper.getHeartRateRecords(this.userId, this.currentDate);
      this.heartRateRecords = heartRateRecords;

      if (heartRateRecords.length > 0) {
        this.heartRate = heartRateRecords[heartRateRecords.length - 1].rate;
      } else {
        this.heartRate = 0;
      }

      const sleepRecords = await this.dbHelper.getSleepRecords(this.userId, this.currentDate);
      if (sleepRecords.length > 0) {
        this.sleepHours = sleepRecords[0].duration / 60;
      } else {
        this.sleepHours = 0;
      }

      const waterRecords = await this.dbHelper.getWaterRecords(this.userId, this.currentDate);
      this.waterRecords = waterRecords;
      this.waterAmount = waterRecords.reduce((total, record) => total + record.amount, 0);

      this.lastUpdateTime = Date.now();
      hilog.info(0x0000, TAG, 'Health data loaded successfully');
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to load health data: ${errorMessage}`);
    }
  }
  ClickJumpToShowData() {
    this.refreshData().then(() => {
      const routerParams: RouterParams = {
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
        this.refreshData();
        return { offsetRemain: 0 };
      }
      return { offsetRemain: offset };
    })
  }
}

export { HomePageContent };
