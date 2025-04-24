import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'DataShow';

interface RouterParams {
  username: string;
  userId: string;
  steps: string;
  heartRate: string;
  sleepHours: string;
  waterAmount: string;
}

@Entry
@Component
struct DataShow {
  @State username: string = '';
  @State userId: string = '';
  @State heartRate: string = '0';
  @State waterAmount: string = '0';
  @State currentDate: string = new Date().toISOString().split('T')[0];
  @State selectedTab: number = 0; // 0 for day, 1 for week, 2 for month
  @State displayMode: string = 'heartRate'; // 'heartRate' or 'waterAmount'

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouterParams;
    if (params) {
      this.username = params.username || '';
      this.userId = params.userId || '';
      this.heartRate = params.heartRate || '0';
      this.waterAmount = params.waterAmount || '0';
    }
  }

  build() {
    Column() {
      // Header with back button and title
      Row() {
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Image($r('app.media.image_2'))
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

        Button({ type: ButtonType.Normal }) {
          Image($r('app.media.image_2'))
            .width(24)
            .height(24)
        }
        .width(36)
        .height(36)
        .backgroundColor('transparent')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .justifyContent(FlexAlign.SpaceBetween)

      // Toggle between heart rate and water amount views
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

      // Date selector
      Row() {
        Text(`2025年4月24日`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)

        Image($r('app.media.image_2'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 10, bottom: 20 })

      // Tab selector (Day, Week, Month)
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
        .onClick(() => { this.selectedTab = 0 })

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
        .onClick(() => { this.selectedTab = 1 })

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
        .onClick(() => { this.selectedTab = 2 })
      }
      .width('90%')
      .height(50)
      .backgroundColor('#F5F5F5')
      .borderRadius(25)
      .padding(5)

      // Conditional display based on displayMode
      if (this.displayMode === 'heartRate') {
        // Heart Rate Display
        Column() {
          // Current heart rate with big display
          Column() {
            Row() {
              Text("80")
                .fontSize(70)
                .fontWeight(FontWeight.Bold)

              Text("次/分")
                .fontSize(20)
                .fontColor('#666666')
                .margin({ left: 8, bottom: 15 })
                .alignSelf(ItemAlign.End)
            }

            Text("4月24日 16:59")
              .fontSize(16)
              .fontColor('#888888')
          }
          .width('100%')
          .margin({ top: 20, bottom: 10 })
          .alignItems(HorizontalAlign.Center)

          // Heart rate chart (simplified representation)
          Column() {
            // This would be a chart component in a real implementation
            // Simplified representation for now
            Stack() {
              // Y-axis labels
              Column() {
                Text("140").fontSize(12).fontColor('#888888')
                Text("112").fontSize(12).fontColor('#888888')
                Text("84").fontSize(12).fontColor('#888888')
                Text("56").fontSize(12).fontColor('#888888')
                Text("28").fontSize(12).fontColor('#888888')
                Text("0").fontSize(12).fontColor('#888888')
              }
              .width('10%')
              .height('100%')
              .alignItems(HorizontalAlign.Start)
              .justifyContent(FlexAlign.SpaceBetween)
              .position({ x: 0, y: 0 })

              // X-axis labels
              Row() {
                Text("00:00").fontSize(12).fontColor('#888888')
                Text("06:00").fontSize(12).fontColor('#888888')
                Text("12:00").fontSize(12).fontColor('#888888')
                Text("18:00").fontSize(12).fontColor('#888888')
                Text("00:00").fontSize(12).fontColor('#888888')
              }
              .width('90%')
              .height('10%')
              .position({ x: '10%', y: '90%' })
              .justifyContent(FlexAlign.SpaceBetween)

              // Chart container (this would be a real chart component)
              Column() {
                // Placeholder for chart
                Text("Heart Rate Chart")
                  .fontSize(0)
                  .width(0)
                  .height(0)
              }
              .width('90%')
              .height('90%')
              .position({ x: '10%', y: 0 })
              .backgroundColor('#FFFFFF10')
            }
            .width('100%')
            .height('100%')
          }
          .width('90%')
          .height(250)
          .padding(10)
          .margin({ top: 10, bottom: 20 })
          .backgroundColor('#F5F5F5')
          .borderRadius(8)

          // Today's overview section
          Row() {
            Image($r('app.media.image_2'))
              .width(36)
              .height(36)

            Text("今日概览")
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 10 })
          }
          .width('90%')
          .padding({ top: 15, bottom: 15 })
          .alignItems(VerticalAlign.Center)

          // Heart rate statistics in grid layout
          Grid() {
            // Resting heart rate
            GridItem() {
              Column() {
                Text("62")
                  .fontSize(30)
                  .fontWeight(FontWeight.Bold)

                Text("次/分")
                  .fontSize(14)
                  .fontColor('#888888')

                Text("静息心率")
                  .fontSize(14)
                  .fontColor('#888888')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Start)
            }
            .columnStart(0)
            .columnEnd(1)

            // Highest heart rate
            GridItem() {
              Column() {
                Text("132")
                  .fontSize(30)
                  .fontWeight(FontWeight.Bold)

                Text("次/分")
                  .fontSize(14)
                  .fontColor('#888888')

                Text("最高心率")
                  .fontSize(14)
                  .fontColor('#888888')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Start)
            }
            .columnStart(1)
            .columnEnd(2)

            // Lowest heart rate
            GridItem() {
              Column() {
                Text("55")
                  .fontSize(30)
                  .fontWeight(FontWeight.Bold)

                Text("次/分")
                  .fontSize(14)
                  .fontColor('#888888')

                Text("最低心率")
                  .fontSize(14)
                  .fontColor('#888888')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Start)
            }
            .columnStart(0)
            .columnEnd(1)
            .rowStart(1)
            .rowEnd(2)

            // Average heart rate
            GridItem() {
              Column() {
                Text("73")
                  .fontSize(30)
                  .fontWeight(FontWeight.Bold)

                Text("次/分")
                  .fontSize(14)
                  .fontColor('#888888')

                Text("平均心率")
                  .fontSize(14)
                  .fontColor('#888888')
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Start)
            }
            .columnStart(1)
            .columnEnd(2)
            .rowStart(1)
            .rowEnd(2)
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .width('90%')
          .height(200)
          .margin({ top: 10 })
        }
        .width('100%')
      } else {
        // Water Amount Display
        Column() {
          // Current water amount with big display
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

            Text(`${this.currentDate.replace(/-/g, '/')}`)
              .fontSize(16)
              .fontColor('#888888')
          }
          .width('100%')
          .margin({ top: 20, bottom: 10 })
          .alignItems(HorizontalAlign.Center)

          // Water consumption progress
          Column() {
            Text("今日饮水进度")
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 20 })

            Stack() {
              Progress({ value: parseInt(this.waterAmount), total: 2000 })
                .width('100%')
                .height(30)
                .color('#3498DB')

              Text(`${this.waterAmount}/2000ml`)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .position({ x: '40%', y: 5 })
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

          // Water intake records
          Column() {
            Text("今日饮水记录")
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 15 })

            Column() {
              // This would normally be populated from actual data
              Row() {
                Text("08:30")
                  .fontSize(16)
                  .width('30%')
                Text("250ml")
                  .fontSize(16)
                  .fontColor('#3498DB')
                  .width('70%')
              }
              .width('100%')
              .padding(10)

              Divider().color('#EEEEEE').height(1)

              Row() {
                Text("10:15")
                  .fontSize(16)
                  .width('30%')
                Text("300ml")
                  .fontSize(16)
                  .fontColor('#3498DB')
                  .width('70%')
              }
              .width('100%')
              .padding(10)

              Divider().color('#EEEEEE').height(1)

              Row() {
                Text("12:40")
                  .fontSize(16)
                  .width('30%')
                Text("200ml")
                  .fontSize(16)
                  .fontColor('#3498DB')
                  .width('70%')
              }
              .width('100%')
              .padding(10)

              Divider().color('#EEEEEE').height(1)

              Row() {
                Text("15:20")
                  .fontSize(16)
                  .width('30%')
                Text("250ml")
                  .fontSize(16)
                  .fontColor('#3498DB')
                  .width('70%')
              }
              .width('100%')
              .padding(10)
            }
            .width('90%')
            .padding(15)
            .borderRadius(8)
            .backgroundColor('#F5F5F5')

            // Water recommendation tips
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
            .margin({ top: 20 })
          }
          .width('100%')
        }
      }

      // Date selector (placed here so it applies to both displays)
      Row() {
        Text(`2025年4月24日`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)

        Image($r('app.media.image_2'))
          .width(24)
          .height(24)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 10, bottom: 20 })

      // Tab selector (Day, Week, Month)
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
        .onClick(() => { this.selectedTab = 0 })

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
        .onClick(() => { this.selectedTab = 1 })

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
        .onClick(() => { this.selectedTab = 2 })
      }
      .width('90%')
      .height(50)
      .backgroundColor('#F5F5F5')
      .borderRadius(25)
      .padding(5)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
}