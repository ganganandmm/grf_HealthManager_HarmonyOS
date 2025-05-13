import { StepRecordItem } from '../ComponentAndDialog/myComponents';
import { StepRecord } from '../common/HealthDataModel';
import { ChartDataItem } from '../Interface/mainhomeInterface';
export const TAG: string = 'MyMovementTab';
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

@Component
export struct MyMovementTab {
  @Link username: string;
  @Link userId: number;
  @Link stepChartData: ChartDataItem[];
  @Link chartMode: string;
  @Link dateRangeText: string;
  @Link totalSteps: number;
  @Link avgDailySteps: number;
  @Link maxDisplayValue: number;
  @Link stepTimeRecords: StepRecord[];
  @Link myWeight: number;
  @Link myHeight: number;
  @Link bmi: number;
  private refreshData: () => Promise<void> = async () => {};
  private updateStepChartData: (forceRefresh?: boolean) => Promise<void> = async () => {};

  calculateBarHeight(value: number): number {
    const maxHeight = 120;
    const calculatedHeight = (value / this.maxDisplayValue) * maxHeight;
    return Math.max(calculatedHeight, value > 0 ? 5 : 0);
  }

  formatStepValue(value: number): string {
    // 对于大于1000的值，以K为单位显示
    if (value >= 10000) {
      return `${(value / 1000).toFixed(0)}K`;
    }
    return value.toString();
  }
  build() {
    Scroll() {
      Column() {
        Row() {
          Text('步数')
            .titleText()
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }

        Row() {
          Text(this.dateRangeText)
            .labelText()
            .textAlign(TextAlign.Center)
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')

        Divider();

        // 图表模式切换
        Row() {
          ForEach(['日', '周', '月'], (mode: string) => {
            Text(mode)
              .fontSize(16)
              .fontWeight(this.chartMode === mode ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.chartMode === mode ? '#000' : '#666')
              .backgroundColor(this.chartMode === mode ? '#fff' : '#f5f5f5')
              .padding({
                left: 20,
                right: 20,
                top: 8,
                bottom: 8
              })
              .borderRadius(20)
              .onClick(() => {
                this.chartMode = mode;
                this.updateStepChartData(true);
              })
          })
        }
        .width('100%')
        .margin({ top: '10%' })
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ bottom: 20 })

        // 步数显示
        Column() {
          Row() {
            Text(this.totalSteps.toString())
              .valueText()
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

        // 修改后的柱状图部分 - 集成日期和柱状图，确保同步滚动
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
                .height(20) // 统一高度
              })
            }
            .height(120) // 统一Y轴高度
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // 集成的柱状图和日期部分 - 单一列表实现同步滚动
            Column() {
              // 创建一个单一列表，包含柱子和对应的日期
              List({ space: 0 }) {
                ForEach(this.stepChartData, (item: ChartDataItem) => {
                  ListItem() {
                    Column() {
                      // 上部分: 步数标注和柱子 - 在固定高度的容器中
                      Column() {
                        // 添加一个固定高度的栈容器，确保柱状图有固定的显示区域
                        Stack({ alignContent: Alignment.Bottom }) {
                          if (item.value > 0) {
                            Column() {
                              // 步数标注在柱子上方
                              Text(item.value.toString())
                                .fontSize(this.chartMode === '月' ? 10 : 12)
                                .fontColor('#333')
                                .fontWeight(FontWeight.Bold)
                                .margin({ bottom: 4 })
                                .textAlign(TextAlign.Center)
                                .width('100%')
                                .visibility(item.value > (this.maxDisplayValue * 0.05) ? Visibility.Visible : Visibility.Hidden)

                              // 柱子本身
                              Column()
                                .width(this.chartMode === '月' ? 20 : 40)
                                .height(this.calculateBarHeight(item.value))
                                .backgroundColor('#FFD700')
                                .borderRadius(this.chartMode === '月' ? 3 : 5)
                            }
                            .width('100%')
                            .alignItems(HorizontalAlign.Center)
                          }
                        }
                        .width('100%')
                        .height(100) // 固定高度的容器，确保不会溢出到日期区域
                      }
                      .height(100)
                      .width('100%')
                      .alignItems(HorizontalAlign.Center)

                      // 清晰的分隔区域 - 确保柱状图和日期之间有空间
                      Column()
                        .height(15)
                        .width('100%')

                      // 下部分: 日期标签区域 - 独立的区域
                      Column() {
                        Text(item.label)
                          .fontSize(14)
                          .fontColor('#333')
                          .textAlign(TextAlign.Center)
                          .width('100%')
                      }
                      .width('100%')
                      .height(25) // 固定高度的日期区域
                      .alignItems(HorizontalAlign.Center)
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Center)
                  }
                  .width(this.chartMode === '月' ? 40 : 60)
                })
              }
              .listDirection(Axis.Horizontal)
              .scrollBar(BarState.Auto)
              .scrollBarColor(Color.Gray)
              .scrollBarWidth(2)
              .edgeEffect(EdgeEffect.Spring)
              .width('100%')
              .height(160) // 增加高度以容纳柱子和日期
            }
            .width('100%')
            .height(160)
            .margin({ left: 60 })
          }
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 20 })

        // 分隔线
        Divider()
          .width('90%')
          .strokeWidth(1)
          .color('#ddd')
          .margin({ top: 15 }) // 增加顶部间距，确保与图表有明确分隔

        // 图表说明
        Text('← 左右滑动查看更多数据 →')
          .fontSize(12)
          .fontColor('#666')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ top: 5 })

        // 概览部分
        Row() {
          Image($r('app.media.target'))
            .width(24)
            .height(24)
            .margin({ right: 10 })

          Text('本周概览')
            .subtitleText()
        }
        .width('100%')
        .margin({ bottom: 10 })

        Row() {
          Column() {
            Text(this.totalSteps.toString())
              .valueText()
            Text('总步数')
              .labelText()
              .margin({ top: 5 })
          }
          .layoutWeight(1)

          Column() {
            Text((this.totalSteps / 3 / 1000).toFixed(2))
              .valueText()
            Text('总距离(公里)')
              .labelText()
              .margin({ top: 5 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 20 })

        Row() {
          Column() {
            Text(this.avgDailySteps.toString())
              .valueText()
            Text('日均步数')
              .labelText()
              .margin({ top: 5 })
          }
          .layoutWeight(1)

          Column() {
            // 使用正确的换算: 三步=一米，再转换为公里
            Text((this.avgDailySteps / 3 / 1000).toFixed(2))
              .valueText()
            Text('日均距离(公里)')
              .labelText()
              .margin({ top: 5 })
          }
          .layoutWeight(1)
        }
        .width('100%')

        Column() {
          Row() {
            Image($r('app.media.target'))
              .width(24)
              .height(24)
              .margin({ right: 10 })

            Text('今日步数详细记录')
              .subtitleText()
          }
          .width('100%')
          .margin({ bottom: 10 })

          // mainHome.ets 中的步数详细记录部分
          if (this.stepTimeRecords.length > 0) {
            List() {
              ForEach(this.stepTimeRecords, (item: StepRecord) => {
                ListItem() {
                  StepRecordItem({ record: item })
                }
              })
            }
            .width('100%')
            .height(this.stepTimeRecords.length > 3 ? 200 : undefined)
            .divider({ strokeWidth: 1, color: '#eeeeee' })
          } else {
            Text('暂无详细步数记录')
              .fontSize(14)
              .fontColor('#999')
              .padding(10)
          }
        }
        .width('100%')
        .padding(15)
        .borderRadius(8)
        .backgroundColor('#f5f5f5')
        .margin({ top: 10, bottom: 20 })

        // 分割线
        Divider()
          .width('90%')
          .height(1)
          .backgroundColor('#ddd')
          .margin({ top: 10, bottom: 10 })

        // 身体成分分析部分
        Column() {
          Row() {
            Image($r('app.media.bmi'))
              .width(24)
              .height(24)
              .margin({ right: 10 })

            Text('身体成分分析')
              .subtitleText()
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            Column() {
              Text(this.myWeight.toString())
                .valueText()
              Text('体重 (kg)')
                .labelText()
                .margin({ top: 5 })
            }
            .layoutWeight(1)

            Column() {
              Text(this.myHeight.toString())
                .valueText()
              Text('身高 (cm)')
                .labelText()
                .margin({ top: 5 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 10 })

          Row() {
            Column() {
              Text(this.bmi.toFixed(1))
                .valueText()
              Text('BMI')
                .labelText()
                .margin({ top: 5 })
            }
            .layoutWeight(1)

            Column() {
              Text('    ')
                .valueText()
            }
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 10 })
        }
        .width('100%')
        .padding(15)
        .borderRadius(8)
        .backgroundColor('#f5f5f5')
        .margin({ top: 10, bottom: 20 })
      }
      .width('100%')
      .padding(15)
      .borderRadius(8)
      .backgroundColor('#f5f5f5')
      .margin({ top: 10, bottom: 20 })
    }
    .scrollBar(BarState.Auto)
    .onScrollFrameBegin((offset: number) => {
      if (offset <= -100) {
        this.refreshData();
        return { offsetRemain: 0 };
      }
      return { offsetRemain: offset };
    })
  }
}