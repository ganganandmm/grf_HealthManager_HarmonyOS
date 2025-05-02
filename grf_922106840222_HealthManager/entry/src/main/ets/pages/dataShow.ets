import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import Want from '@ohos.app.ability.Want'
import { DatabaseHelper } from '../common/DatabaseHelper';
import { HeartRateRecord, WaterRecord } from '../common/HealthDataModel';
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
@Extend(Text) function subtitleText() {
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .margin({ bottom: 10 })
}
interface RouterParams {
  username: string;
  userId: string;
  steps: string;
  heartRate: string;
  sleepHours: string;
  waterAmount: string;
  date: string
}
interface CalendarWant {
  deviceId: string;
  bundleName: string;
  abilityName: string;
}

const want: CalendarWant = {
  deviceId: "",
  bundleName: "com.huawei.calendar",
  abilityName: "com.huawei.calendar.LauncherAbility"
};
@Entry
@Component
struct DataShow {
  @State chartHeight: number=0;
  @State dateRangeText: string = '';
  @State username: string = '';
  @State userId: string = '';
  @State heartRate: string = '0';
  @State waterAmount: string = '0';
  @State currentDate: string = new Date().toISOString().split('T')[0];
  @State selectedTab: number = 0; // 0 for day, 1 for week, 2 for month
  @State displayMode: string = 'heartRate'; // 'heartRate' or 'waterAmount'
  @State heartRateRecords: HeartRateRecord[] = [];
  @State waterRecords: WaterRecord[] = [];
  @State selectedDate: Date = new Date();
  @State formattedDate: string = '';
  @State restingHeartRate: number = 0;
  @State highestHeartRate: number = 0;
  @State lowestHeartRate: number = 0;
  @State averageHeartRate: number = 0;
  @State lastHeartRateTime: string = '';
  @State weekDates: string[] = []; // 存储本周的日期
  @State monthDates: string[] = []; // 存储本月的日期
  @State totalSteps: number = 0; // 周/月总步数
  @State averageSleepHours: number = 0; // 周/月平均睡眠时间
  @State randomIndex : number = 0;

  // 画布相关
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;
  private chartPadding: number = 10;
  private yAxisWidth: number = 30;
  private xAxisHeight: number = 30;
  private settings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));

  aboutToAppear() {
    this.dbHelper.initDatabase().then(() => {
      const params = router.getParams() as RouterParams;
      if (params) {
        this.username = params.username || '';
        this.userId = params.userId || '';
        this.heartRate = params.heartRate || '0';
        this.waterAmount = params.waterAmount || '0';
        if (params.date) {
          this.currentDate = params.date;
          this.selectedDate = new Date(params.date);
        }
        this.updateFormattedDate();
        this.loadDataForDate(this.currentDate).then(() => {
        });
      }
    });
  }
  aboutToDisappear() {
    this.dbHelper.closeDatabase();
  }
  updateFormattedDate() {
    const year = this.selectedDate.getFullYear();
    const month = String(this.selectedDate.getMonth() + 1).padStart(2, '0');
    const day = String(this.selectedDate.getDate()).padStart(2, '0');
    this.formattedDate = `${year}-${month}-${day}`;
    this.currentDate = this.formattedDate;

    this.calculateWeekDates();

    this.calculateMonthDates();
  }
  calculateWeekDates() {
    const date = new Date(this.selectedDate);
    const day = date.getDay(); // 0
    const diff = date.getDate() - day + (day === 0 ? -6 : 1);

    const weekStart = new Date(date);
    weekStart.setDate(diff);

    this.weekDates = [];
    for (let i = 0; i < 7; i++) {
      const currentDate = new Date(weekStart);
      currentDate.setDate(weekStart.getDate() + i);

      const year = currentDate.getFullYear();
      const month = String(currentDate.getMonth() + 1).padStart(2, '0');
      const day = String(currentDate.getDate()).padStart(2, '0');
      this.weekDates.push(`${year}-${month}-${day}`);
    }
    const weekStartText = `${weekStart.getMonth() + 1}月${weekStart.getDate()}日`;
    const weekEndDate = new Date(weekStart);
    weekEndDate.setDate(weekStart.getDate() + 6);
    const weekEndText = `${weekEndDate.getMonth() + 1}月${weekEndDate.getDate()}日`;
    this.dateRangeText = `${weekStartText} - ${weekEndText}`;
  }
  calculateMonthDates() {
    const year = this.selectedDate.getFullYear();
    const month = this.selectedDate.getMonth();
    const firstDay = new Date(year, month, 1);
    const nextMonth = new Date(year, month + 1, 1);
    const lastDay = new Date(nextMonth);
    lastDay.setDate(lastDay.getDate() - 1);

    const daysInMonth = lastDay.getDate();
    this.monthDates = [];

    for (let i = 1; i <= daysInMonth; i++) {
      const currentDate = new Date(year, month, i);
      const yearStr = currentDate.getFullYear();
      const monthStr = String(currentDate.getMonth() + 1).padStart(2, '0');
      const dayStr = String(currentDate.getDate()).padStart(2, '0');
      this.monthDates.push(`${yearStr}-${monthStr}-${dayStr}`);
    }
    this.dateRangeText = `${year}年${month + 1}月`;
  }

  async loadDataForDate(date: string) {
    if (!this.userId) {
      return;
    }

    try {
      const userId = parseInt(this.userId);
      const heartRateRecords = await this.dbHelper.getHeartRateRecords(userId, date);
      this.heartRateRecords = heartRateRecords;
      if (heartRateRecords.length > 0) {

        const latestRecord = heartRateRecords[heartRateRecords.length - 1];
        this.heartRate = latestRecord.rate.toString();
        this.lastHeartRateTime = `${date} ${latestRecord.time}`;

        const rates = heartRateRecords.map(record => record.rate);
        this.highestHeartRate = Math.max(...rates);
        this.lowestHeartRate = Math.min(...rates);
        this.averageHeartRate = Math.round(rates.reduce((sum, rate) => sum + rate, 0) / rates.length);

        this.restingHeartRate = this.lowestHeartRate + 5;
        if (this.restingHeartRate > this.averageHeartRate) {
          this.restingHeartRate = this.lowestHeartRate;
        }
      } else {
        // 如果没有心率记录，重置所有数据
        this.heartRate = '0';
        this.restingHeartRate = 0;
        this.highestHeartRate = 0;
        this.lowestHeartRate = 0;
        this.averageHeartRate = 0;
        this.lastHeartRateTime = '';
      }

      // 加载饮水数据
      const waterRecords = await this.dbHelper.getWaterRecords(userId, date);
      this.waterRecords = waterRecords;

      // 计算总饮水量
      if (waterRecords.length > 0) {
        const totalWater = waterRecords.reduce((sum, record) => sum + record.amount, 0);
        this.waterAmount = totalWater.toString();
      } else {
        this.waterAmount = '0';
      }
      this.drawHeartRateChart();
    } catch (error) {
      console.error(`加载健康数据失败: ${error}`);
    }
  }
  async loadWeekData() {
    if (!this.userId) {
      return;
    }
    try {
      const userId = parseInt(this.userId);
      this.heartRateRecords = [];
      this.waterRecords = [];

      let totalHeartRate = 0;
      let totalHeartRateCount = 0;
      let allHeartRates: number[] = [];
      let totalWaterAmount = 0;
      this.totalSteps = 0;
      let totalSleepMinutes = 0;
      let sleepDaysCount = 0;

      // 遍历本周每一天加载数据
      for (const date of this.weekDates) {
        // 加载心率数据
        const heartRateRecords = await this.dbHelper.getHeartRateRecords(userId, date);
        this.heartRateRecords = [...this.heartRateRecords, ...heartRateRecords];

        if (heartRateRecords.length > 0) {
          const rates = heartRateRecords.map(record => record.rate);
          totalHeartRate += rates.reduce((sum, rate) => sum + rate, 0);
          totalHeartRateCount += rates.length;
          allHeartRates = [...allHeartRates, ...rates];
        }

        // 加载饮水数据
        const waterRecords = await this.dbHelper.getWaterRecords(userId, date);
        this.waterRecords = [...this.waterRecords, ...waterRecords];

        if (waterRecords.length > 0) {
          const dayWaterAmount = waterRecords.reduce((sum, record) => sum + record.amount, 0);
          totalWaterAmount += dayWaterAmount;
        }

        // 加载步数数据
        const stepRecords = await this.dbHelper.getStepRecords(userId, date);
        if (stepRecords.length > 0) {
          this.totalSteps += stepRecords[0].steps;
        }

        // 加载睡眠数据
        const sleepRecords = await this.dbHelper.getSleepRecords(userId, date);
        if (sleepRecords.length > 0) {
          totalSleepMinutes += sleepRecords[0].duration;
          sleepDaysCount++;
        }
      }

      // 计算统计数据
      if (allHeartRates.length > 0) {
        this.highestHeartRate = Math.max(...allHeartRates);
        this.lowestHeartRate = Math.min(...allHeartRates);
        this.averageHeartRate = Math.round(totalHeartRate / totalHeartRateCount);
        this.restingHeartRate = this.lowestHeartRate + 5;
        if (this.restingHeartRate > this.averageHeartRate) {
          this.restingHeartRate = this.lowestHeartRate;
        }

        // 使用本周最新的心率值
        const latestRecord = this.heartRateRecords[this.heartRateRecords.length - 1];
        this.heartRate = latestRecord.rate.toString();
        this.lastHeartRateTime = `${latestRecord.date} ${latestRecord.time}`;
      } else {
        this.heartRate = '0';
        this.restingHeartRate = 0;
        this.highestHeartRate = 0;
        this.lowestHeartRate = 0;
        this.averageHeartRate = 0;
        this.lastHeartRateTime = '';
      }

      // 设置总饮水量
      this.waterAmount = totalWaterAmount.toString();

      // 计算平均睡眠时间（小时）
      this.averageSleepHours = sleepDaysCount > 0 ? (totalSleepMinutes / sleepDaysCount) / 60 : 0;

    } catch (error) {
      console.error(`加载周数据失败: ${error}`);
    }
  }

  // 加载一个月数据
  async loadMonthData() {
    if (!this.userId) {
      return;
    }
    try {
      const userId = parseInt(this.userId);
      this.heartRateRecords = [];
      this.waterRecords = [];

      let totalHeartRate = 0;
      let totalHeartRateCount = 0;
      let allHeartRates: number[] = [];
      let totalWaterAmount = 0;
      this.totalSteps = 0;
      let totalSleepMinutes = 0;
      let sleepDaysCount = 0;

      // 遍历本月每一天加载数据
      for (const date of this.monthDates) {
        // 加载心率数据
        const heartRateRecords = await this.dbHelper.getHeartRateRecords(userId, date);
        this.heartRateRecords = [...this.heartRateRecords, ...heartRateRecords];

        if (heartRateRecords.length > 0) {
          const rates = heartRateRecords.map(record => record.rate);
          totalHeartRate += rates.reduce((sum, rate) => sum + rate, 0);
          totalHeartRateCount += rates.length;
          allHeartRates = [...allHeartRates, ...rates];
        }

        // 加载饮水数据
        const waterRecords = await this.dbHelper.getWaterRecords(userId, date);
        this.waterRecords = [...this.waterRecords, ...waterRecords];

        if (waterRecords.length > 0) {
          const dayWaterAmount = waterRecords.reduce((sum, record) => sum + record.amount, 0);
          totalWaterAmount += dayWaterAmount;
        }

        // 加载步数数据
        const stepRecords = await this.dbHelper.getStepRecords(userId, date);
        if (stepRecords.length > 0) {
          this.totalSteps += stepRecords[0].steps;
        }

        // 加载睡眠数据
        const sleepRecords = await this.dbHelper.getSleepRecords(userId, date);
        if (sleepRecords.length > 0) {
          totalSleepMinutes += sleepRecords[0].duration;
          sleepDaysCount++;
        }
      }

      // 计算统计数据
      if (allHeartRates.length > 0) {
        this.highestHeartRate = Math.max(...allHeartRates);
        this.lowestHeartRate = Math.min(...allHeartRates);
        this.averageHeartRate = Math.round(totalHeartRate / totalHeartRateCount);
        this.restingHeartRate = this.lowestHeartRate + 5;
        if (this.restingHeartRate > this.averageHeartRate) {
          this.restingHeartRate = this.lowestHeartRate;
        }

        // 使用本月最新的心率值
        const latestRecord = this.heartRateRecords[this.heartRateRecords.length - 1];
        this.heartRate = latestRecord.rate.toString();
        this.lastHeartRateTime = `${latestRecord.date} ${latestRecord.time}`;
      } else {
        this.heartRate = '0';
        this.restingHeartRate = 0;
        this.highestHeartRate = 0;
        this.lowestHeartRate = 0;
        this.averageHeartRate = 0;
        this.lastHeartRateTime = '';
      }

      // 设置总饮水量
      this.waterAmount = totalWaterAmount.toString();

      // 计算平均睡眠时间（小时）
      this.averageSleepHours = sleepDaysCount > 0 ? (totalSleepMinutes / sleepDaysCount) / 60 : 0;

    } catch (error) {
      console.error(`加载月数据失败: ${error}`);
    }
  }
  // 打开系统日历
  async openCalendar() {
    try {
      const want: Want = {
        deviceId: "",
        bundleName: "com.huawei.calendar",
        abilityName: "com.huawei.calendar.LauncherAbility"
      };

      let context = getContext(this) as common.UIAbilityContext;
      await context.startAbility(want);
      console.info("grf_成功打开系统日历");
    } catch (error) {
      console.info(`grf_打开系统日历失败：${error}`);
    }
  }


  drawHeartRateChart() {

  }

  build() {
    Column() {
      Row() {
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.backup'))
            .width(24)
            .height(24)
        }
        .width(36)
        .height(36)
        .backgroundColor('transparent')
        .onClick(() => {
          router.back();
        })

        Text(this.displayMode === 'heartRate' ? "心率" : "饮水量")
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .justifyContent(FlexAlign.SpaceBetween)

      Row() {
        Button('心率')
          .width('45%')
          .height(40)
          .backgroundColor(this.displayMode === 'heartRate' ? '#1698CE' : '#E0E0E0')
          .fontColor(this.displayMode === 'heartRate' ? '#FFFFFF' : '#666666')
          .onClick(() => {
            this.displayMode = 'heartRate';
          })

        Button('饮水量')
          .width('45%')
          .height(40)
          .backgroundColor(this.displayMode === 'waterAmount' ? '#1698CE' : '#E0E0E0')
          .fontColor(this.displayMode === 'waterAmount' ? '#FFFFFF' : '#666666')
          .onClick(() => {
            this.displayMode = 'waterAmount';
          })
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 10, bottom: 10 })

      Row() {
        Text(this.formattedDate)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            console.info("CalendarDialog.show")
            CalendarPickerDialog.show({
              selected: this.selectedDate,
              onAccept: (value) => {
                this.selectedDate = value;
                this.updateFormattedDate();
                this.loadDataForDate(this.currentDate);
                console.info("calendar onAccept:" + this.currentDate)
              },
              onCancel: () => {
                console.info("calendar onCancel")
              },
              onChange: (value) => {
                console.info("calendar onChange:" + JSON.stringify(value))
              }
            })
          })

        Image($r('app.media.date'))
          .width(24)
          .height(24)
          .margin({left : 10})
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 10, bottom: 20 })

      Row() {
        Column() {
          Text("日")
            .fontSize(16)
            .fontColor(this.selectedTab === 0 ? '#000000' : '#888888')
            .fontWeight(this.selectedTab === 0 ? FontWeight.Bold : FontWeight.Normal)
        }
        .width('33%')
        .height(40)
        .backgroundColor(this.selectedTab === 0 ? '#FFFFFF' : 'transparent')
        .borderRadius(20)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.selectedTab = 0;
          // 当切换到日视图时，重新加载当前选择日期的数据
          this.loadDataForDate(this.currentDate);
        })
        Column() {
          Text("周")
            .fontSize(16)
            .fontColor(this.selectedTab === 1 ? '#000000' : '#888888')
            .fontWeight(this.selectedTab === 1 ? FontWeight.Bold : FontWeight.Normal)
        }
        .width('33%')
        .height(40)
        .backgroundColor(this.selectedTab === 1 ? '#FFFFFF' : 'transparent')
        .borderRadius(20)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.selectedTab = 1;
          this.loadWeekData();
        })

        Column() {
          Text("月")
            .fontSize(16)
            .fontColor(this.selectedTab === 2 ? '#000000' : '#888888')
            .fontWeight(this.selectedTab === 2 ? FontWeight.Bold : FontWeight.Normal)
        }
        .width('33%')
        .height(40)
        .backgroundColor(this.selectedTab === 2 ? '#FFFFFF' : 'transparent')
        .borderRadius(20)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.selectedTab = 2;
          this.loadMonthData()
        })
      }
      .width('90%')
      .height(50)
      .backgroundColor('#F5F5F5')
      .borderRadius(25)
      .padding(5)

      Scroll(){
        if (this.displayMode === 'heartRate') {
          Column() {
            Column() {
              Row() {
                Text(this.heartRate)
                  .fontSize(70)
                  .fontWeight(FontWeight.Bold)

                Text("次/分")
                  .fontSize(20)
                  .fontColor('#666666')
                  .margin({ left: 8, bottom: 15 })
                  .alignSelf(ItemAlign.End)
              }

              Text(this.lastHeartRateTime ? this.lastHeartRateTime : "暂无数据")
                .fontSize(16)
                .fontColor('#888888')
            }
            .width('100%')
            .margin({ top: 20, bottom: 10 })
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text("心率趋势")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })
                .alignSelf(ItemAlign.Start)

              Canvas(this.context)
                .width('100%')
                .height('100%')
                .onReady(() => {
                  // Get Canvas actual dimensions
                  this.canvasWidth = this.context.width;
                  this.canvasHeight = this.context.height;

                  // Draw the heart rate chart
                  this.drawHeartRateChart();
                })
            }
            .width('90%')
            .height(250)
            .padding(10)
            .margin({ top: 10, bottom: 20 })
            .backgroundColor('#FFFFFF')  // Change from Color.Yellow to white
            .borderRadius(8)
            .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })

            // 概览部分--------------------------------------------------------------
            Row() {
              Image($r('app.media.target'))
                .width(24)
                .height(24)
                .margin({ right: 10 })

              Text(this.formattedDate + " 概览")
                .subtitleText()
            }
            .width('90%')
            .padding({ top: 15, bottom: 15 })
            .alignItems(VerticalAlign.Center)

            Row() {
              Column() {
                Text(this.restingHeartRate.toString())
                  .valueText()
                Text("次/分").valueText()
                Text("静息心率")
                  .labelText()
                  .margin({ top: 5 })
              }
              .layoutWeight(1)

              Column() {
                Text(this.highestHeartRate.toString())
                  .valueText()
                Text("次/分").valueText()

                Text("最高心率")
                  .labelText()
                  .margin({ top: 5 })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 20 })


            Row() {
              Column() {
                Text(this.lowestHeartRate.toString())
                  .valueText()
                Text("次/分").valueText()
                Text("最低心率")
                  .labelText()
                  .margin({ top: 5 })
              }
              .layoutWeight(1)

              Column() {
                Text(this.averageHeartRate.toString())
                  .valueText()
                Text("次/分").valueText()

                Text("平均心率")
                  .labelText()
                  .margin({ top: 5 })
              }
              .layoutWeight(1)
            }
            .width('100%')
            .margin({ bottom: 20 })
            //------------------------------------------------------------------------
            // 心率记录列表
            if (this.heartRateRecords.length > 0) {
              Column() {
                Text("心率记录")
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .alignSelf(ItemAlign.Start)
                  .margin({ bottom: 10 })
                List() {
                  ForEach(this.heartRateRecords, (item: HeartRateRecord) => {
                    ListItem() {
                      Row() {
                        Text(item.time)
                          .fontSize(16)
                          .width('40%')
                        Text(`${item.rate} 次/分`)
                          .fontSize(16)
                          .fontColor('#E74C3C')
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
                .margin({bottom : '100%'})
                Text("").fontSize(50)
              }
              .width('90%')
              .padding(15)
              .borderRadius(8)
              .backgroundColor('#F5F5F5')
              .margin({ top: 20, bottom: 20 })
            } else {
              Text("该日期暂无心率记录")
                .fontSize(16)
                .fontColor('#888888')
                .margin({ top: 20, bottom: 20 })
            }
          }
          .width('100%')
        } else {
          Column() {
            Column() {
              Row() {
                Text(this.waterAmount)
                  .fontSize(70)
                  .fontWeight(FontWeight.Bold)

                Text("ml")
                  .fontSize(20)
                  .fontColor('#666666')
                  .margin({ left: 8, bottom: 15 })
                  .alignSelf(ItemAlign.End)
              }

              Text(this.formattedDate) // 饮水量下方显示的时间
                .fontSize(16)
                .fontColor('#888888')
            }
            .width('100%')
            .margin({ top: 20, bottom: 10 })
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text("饮水进度")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 20 })
              Stack() {
                Progress({ value: Number(this.waterAmount), total: 2000 })
                  .width('100%')
                  .height(30)
                  .color('#3498DB')

                Text(`${this.waterAmount}/2000ml`)
                  .fontSize(14)
                  .fontColor('#3498DB')
                  .padding({bottom : 40})
              }
              .width('90%')

              Text("建议每日饮水量: 2000ml")
                .fontSize(14)
                .fontColor('#888888')
                .margin({ top: 10 })
            }
            .width('90%')
            .padding(20)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .margin({ top: 20, bottom: 20 })
            // 饮水记录部分
            Column() {
              Text("饮水记录")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 15 })

              if (this.waterRecords.length > 0) {
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

              } else {
                Text("该日期暂无饮水记录")
                  .fontSize(16)
                  .fontColor('#888888')
                  .margin({ top: 10, bottom: 10 })
              }

            }
            .width('90%')
            .padding(15)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .margin({ top: 10, bottom: 20 })

            Row(){
              Column() {
                Text("饮水建议")
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .alignSelf(ItemAlign.Start)
                  .margin({ bottom: 10 })

                Text("• 早晨起床后喝一杯水，有助于唤醒身体")
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 5 })

                Text("• 每次饮水量控制在200-300ml之间")
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 5 })

                Text("• 避免一次性大量饮水")
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ bottom: 5 })

                Text("• 睡前1小时避免大量饮水")
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .width('90%')
              .padding(15)
              .borderRadius(8)
              .backgroundColor('#F5F5F5')
              .margin({ top: 10, bottom: 50 })
            }
            .margin({bottom: '50%'})
          }
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}