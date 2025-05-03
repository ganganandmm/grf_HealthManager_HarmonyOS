import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'ExerciseTabComponent';

interface ChartDataItem {
  label: string;
  value: number;
}
@Extend(Text) function titleText() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .margin({ top: 10, bottom: 20 })
}

@Extend(Text) function subtitleText() {
  .fontSize(18)
  .fontWeight(FontWeight.Bold)
  .margin({ bottom: 10 })
}

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

@Extend(Button) function primaryButton() {
  .width('100%')
  .height(40)
  .backgroundColor('#27AE60')
  .margin({ bottom: 10 })
}

@Extend(Button) function secondaryButton(bgColor: string = '#3498DB') {
  .width('100%')
  .height(40)
  .backgroundColor(bgColor)
  .margin({ bottom: 10 })
}

@Extend(Row) function menuItem() {
  .width('100%')
  .padding(15)
  .backgroundColor('#ffffff')
  .borderRadius(8)
  .margin({ bottom: 10 })
}

@Component
export struct ExerciseTabComponent {
  @Link username: string;
  @Link userId: number;
  @Link steps: number;
  @Link myWeight: number;
  @Link myHeight: number;
  @Link bmi: number;
  @Link currentDate: string;
  @Link stepChartData: ChartDataItem[];
  @Link chartMode: string;
  @Link dateRangeText: string;
  @Link totalSteps: number;
  @Link avgDailySteps: number;
  @Link maxDisplayValue: number;
  @Link canvasContext: CanvasRenderingContext2D | null;
  @Link selectedDate: Date;
  @Link isCalendarVisible: boolean;

  @Prop refreshData: () => Promise<void>;
  @Prop updateStepChartData: () => Promise<void>;

  // 计算柱状图高度
  calculateBarHeight(value: number): number {
    const maxHeight = 120; // 减小最大高度，确保不会超出容器
    const calculatedHeight = (value / this.maxDisplayValue) * maxHeight;
    return Math.max(calculatedHeight, value > 0 ? 5 : 0); // 确保即使数值很小，柱子也至少有5px高度
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
              .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .borderRadius(20)
              .onClick(() => {
                this.chartMode = mode;
                this.updateStepChartData();
              })
          })
        }
        .width('100%')
        .margin({top : '10%'})
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

        // 柱状图组件 - 修复柱状图覆盖日期的问题
        Column() {
          // Y轴标签和网格线
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

            Column() {
              List({ space: 0 }) {
                ForEach(this.stepChartData, (item: ChartDataItem) => {
                  ListItem() {
                    Column() {
                      // 柱子部分 - 确保柱子位于上方，不会延伸到下方标签区域
                      Column() {
                        if (item.value > 0) {
                          Column()
                            .width(this.chartMode === '月' ? 20 : 40)
                            .height(this.calculateBarHeight(item.value))
                            .backgroundColor('#FFD700')
                            .borderRadius(this.chartMode === '月' ? 3 : 5)
                        }
                      }
                      .height(130)
                      .width('100%')
                      .justifyContent(FlexAlign.End)
                    }
                    .alignItems(HorizontalAlign.Center)
                  }
                  .width(this.chartMode === '月' ? 40 : 60)
                })
              }
              .listDirection(Axis.Horizontal) // 水平列表
              .scrollBar(BarState.Auto) // 显示滚动条
              .scrollBarColor(Color.Gray)
              .scrollBarWidth(2)
              .edgeEffect(EdgeEffect.Spring) // 滚动到边缘时的弹性效果
              .width('100%')
              .height(130) // 减小高度，与柱子容器一致
            }
            .width('100%')
            .height(150)
            .margin({ left: 60 })
          }

          // 将日期标签单独放在下方，确保不被柱状图覆盖
          List() {
            ForEach(this.stepChartData, (item: ChartDataItem) => {
              ListItem() {
                Text(item.label)
                  .fontSize(14)
                  .fontColor('#333')
                  .textAlign(TextAlign.Center)
                  .width('100%')
                  .padding({ top: 5, bottom: 5 })
              }
              .width(this.chartMode === '月' ? 40 : 60)
            })
          }
          .listDirection(Axis.Horizontal)
          .scrollBar(BarState.Off) // 隐藏日期部分的滚动条
          .width('100%')
          .height(30)
          .margin({ left: 60 }) // 与上方柱状图对齐

          // 分隔线，明确分隔图表和日期区域
          Divider()
            .width('90%')
            .strokeWidth(1)
            .color('#ddd')
            .margin({ top: 5 })

          // 图表说明
          Text('← 左右滑动查看更多数据 →')
            .fontSize(12)
            .fontColor('#666')
            .textAlign(TextAlign.Center)
            .width('100%')
            .margin({ top: 5 })
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

        // 分割线
        Divider()
          .width('90%')
          .height(1)
          .backgroundColor('#ddd')
          .margin({ top: 10, bottom: 10 })

        // 身体成分分析部分
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
          Column(){
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
          Column(){
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