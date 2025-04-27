// SportsTabComponent.ets
import { hilog } from '@kit.PerformanceAnalysisKit';
import { RefreshDataFunc, UpdateStepChartFunc } from './FunctionInterfaces';

const TAG: string = 'SportsTab';

// 定义柱状图数据结构
interface ChartDataItem {
  label: string;
  value: number;
}

@Component
export struct SportsTabComponent {
  @Link username: string;
  @Link userId: number;
  @Link currentDate: string;
  @Link stepChartData: ChartDataItem[];
  @Link chartMode: string;
  @Link dateRangeText: string;
  @Link totalSteps: number;
  @Link avgDailySteps: number;
  @Link maxDisplayValue: number;

  @Prop refreshDataFunc: RefreshDataFunc;
  @Prop updateStepChartFunc: UpdateStepChartFunc;

  // 计算柱状图高度
  calculateBarHeight(value: number): number {
    const maxHeight = 150; // 柱状图区域最大高度
    return (value / this.maxDisplayValue) * maxHeight;
  }

  async selectDate() {
    try {
      // 这里可以实现日期选择功能
    } catch (err) {
      console.error(`Select date failed with error: ${err}`);
    }
  }

  build() {
    Scroll() {
      Column() {
        Column() {
          Row() {
            Image($r('app.media.date'))
              .width(24)
              .height(24)
              .onClick(() => {
                this.selectDate();
              })
            Text('步数')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
            Text(this.dateRangeText)
              .fontSize(16)
              .fontColor('#666')
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })

          // 图表模式切换
          Row() {
            ForEach(['日', '周', '月'], (mode: string) => {
              Text(mode)
                .fontSize(16)
                .fontWeight(this.chartMode === mode ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.chartMode === mode ? '#000' : '#666')
                .backgroundColor(this.chartMode === mode ? '#fff' : '#f5f5f5')
                .padding({ left: 20, right: 20, top: 8, bottom: 8 })
                .borderRadius(20)
                .onClick(() => {
                  this.chartMode = mode;
                  this.updateStepChartFunc.updateStepChartData();
                })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
          .margin({ bottom: 20 })

          // 步数显示
          Column() {
            Row() {
              Text(this.totalSteps.toString())
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
              Text('步')
                .fontSize(20)
                .margin({ left: 5 })
            }

            Text(this.dateRangeText)
              .fontSize(14)
              .fontColor('#666')
              .margin({ top: 5 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 20 })

          // 柱状图
          Column() {
            Stack() {
              // Y轴刻度 - 动态调整以适应数据
              Column() {
                ForEach([1, 0.8, 0.6, 0.4, 0.2, 0], (ratio: number) => {
                  Row() {
                    Text(Math.round(this.maxDisplayValue * ratio).toString())
                      .fontSize(12)
                      .fontColor('#999')
                      .width(50)
                      .textAlign(TextAlign.End)
                      .margin({ right: 10 })

                    // 网格线
                    Divider()
                      .width('100%')
                      .color('#eee')
                  }
                  .width('100%')
                  .height(25)
                })
              }
              .height(150)
              .width('100%')
              .alignItems(HorizontalAlign.Start)

              // 柱状图
              Row() {
                ForEach(this.stepChartData, (item: ChartDataItem) => {
                  Column() {
                    if (item.value > 0) {
                      Column()
                        .width(this.chartMode === '月' ? 6 : 15)
                        .height(this.calculateBarHeight(item.value))
                        .backgroundColor('#FFD700')
                        .borderRadius(this.chartMode === '月' ? 3 : 5)
                    }
                  }
                  .layoutWeight(1)
                  .height(150)
                  .justifyContent(FlexAlign.End)
                })
              }
              .width('100%')
              .height(150)
              .margin({ left: 60 })
            }

            // X轴标签
            Row() {
              ForEach(this.stepChartData, (item: ChartDataItem) => {
                Text(item.label)
                  .fontSize(this.chartMode === '月' ? 10 : 12)
                  .fontColor('#666')
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
              })
            }
            .width('100%')
            .margin({ left: 60, top: 5 })
          }
          .width('100%')
          .margin({ bottom: 20 })

          // 概览部分
          Row() {
            Image($r('app.media.target'))
              .width(24)
              .height(24)
              .margin({ right: 10 })

            Text('本周概览')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .margin({ bottom: 10 })

          // 统计数据 - 使用正确的换算公式: 三步=一米
          Row() {
            Column() {
              Text(this.totalSteps.toString())
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('总步数')
                .fontSize(14)
                .fontColor('#666')
                .margin({ top: 5 })
            }
            .layoutWeight(1)

            Column() {
              // 使用正确的换算: 三步=一米，再转换为公里
              Text((this.totalSteps / 3 / 1000).toFixed(2))
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('总距离(公里)')
                .fontSize(14)
                .fontColor('#666')
                .margin({ top: 5 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 20 })

          Row() {
            Column() {
              Text(this.avgDailySteps.toString())
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('日均步数')
                .fontSize(14)
                .fontColor('#666')
                .margin({ top: 5 })
            }
            .layoutWeight(1)

            Column() {
              // 使用正确的换算: 三步=一米，再转换为公里
              Text((this.avgDailySteps / 3 / 1000).toFixed(2))
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
              Text('日均距离(公里)')
                .fontSize(14)
                .fontColor('#666')
                .margin({ top: 5 })
            }
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(15)
        .borderRadius(8)
        .backgroundColor('#fff')
        .margin({ top: 20, bottom: 20 })

        Divider() //分割线
          .width('90%')
          .height(1)
          .backgroundColor('#ddd')
          .margin({ top: 10, bottom: 10 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .scrollBar(BarState.Auto)
    .onScrollFrameBegin((offset: number) => {
      if (offset <= -100) {
        this.refreshDataFunc.refreshData();
        return { offsetRemain: 0 };
      }
      return { offsetRemain: offset };
    })
  }
}