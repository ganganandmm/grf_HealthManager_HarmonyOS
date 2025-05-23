import { HeartRateRecord, StepRecord, WaterRecord } from "../common/HealthDataModel";
@Extend(Text) function labelText() {
  .fontSize(16)
  .fontColor('#666')
}

@Extend(Text) function valueText() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
}
/**
 * HealthDataCard组件
 * 用于展示单个健康数据指标的卡片组件
 * 包含标题和数值，可自定义颜色和单位
 */
@Component
export struct HealthDataCard {
  @Prop title: string;       // 卡片标题，如"步数"、"心率"等
  @Prop value: string;       // 数值，如"8000"、"75"等
  @Prop unit: string = '';   // 单位，如"bpm"、"ml"等，默认为空
  @Prop color: string = '#1698CE'; // 数值文本颜色，默认为蓝色

  build() {
    Column() {
      // 显示卡片标题
      Text(this.title)
        .labelText()  // 使用自定义的labelText样式

      // 显示数值和单位（如果有单位则添加空格和单位）
      Text(this.value + (this.unit ? ' ' + this.unit : ''))
        .valueText()  // 使用自定义的valueText样式
        .fontColor(this.color)  // 应用传入的颜色
    }
    .width('45%')
    .padding(10)
    .borderRadius(8)  // 圆角8像素
    .backgroundColor('#f7f7f7')  // 背景色浅灰
  }
}

/**
 * HeartRateRecordItem组件
 * 用于在列表中展示单条心率记录的组件
 * 显示记录时间和心率值
 */
@Component
export struct HeartRateRecordItem {
  @Prop record!: HeartRateRecord;  // 心率记录数据，使用!表示非空断言

  build() {
    Row() {
      // 显示记录时间
      Text(this.record.time)
        .fontSize(16)
        .width('40%')  // 时间占40%宽度

      // 显示心率值和单位
      Text(`${this.record.rate} 次/分`)
        .fontSize(16)
        .fontColor('#3498DB')  // 蓝色文本
        .width('60%')  // 数值占60%宽度
    }
    .width('100%')
    .padding(10)
    .justifyContent(FlexAlign.SpaceBetween)  // 两端对齐
  }
}

/**
 * WaterRecordItem组件
 * 用于在列表中展示单条饮水记录的组件
 * 显示记录时间和饮水量
 */
@Component
export struct WaterRecordItem {
  @Prop record!: WaterRecord;  // 饮水记录数据，使用!表示非空断言

  build() {
    Row() {
      // 显示记录时间
      Text(this.record.time)
        .fontSize(16)
        .width('40%')  // 时间占40%宽度

      // 显示饮水量和单位
      Text(`${this.record.amount} ml`)
        .fontSize(16)
        .fontColor('#3498DB')  // 蓝色文本
        .width('60%')  // 数值占60%宽度
    }
    .width('100%')  // 行宽度占满父容器
    .padding(10)    // 内边距10像素
    .justifyContent(FlexAlign.SpaceBetween)  // 两端对齐布局
  }
}
@Component
export struct DataInputRow {
  @Prop title: string = '';
  @Prop placeholder: string = '';
  @Prop unit: string = '';
  @Prop buttonText: string = '';
  @Prop buttonColor: string = '#3498DB';
  @State inputValue: string = '';
  inputType: InputType = InputType.NUMBER_DECIMAL;
  onInputChange: (value: string) => void = () => {};  // 提供默认空函数
  onButtonClick: () => void = () => {};  // 提供默认空函数

  build() {
    Row() {
      TextInput({ text: this.inputValue, placeholder: this.placeholder })
        .type(InputType.NUMBER_DECIMAL)
        .width('45%')
        .height(50)
        .onChange((value: string) => {
          this.inputValue = value;
          this.onInputChange(value);
        })

      Text(this.unit)
        .fontSize(16)
        .fontColor('#666')
        .width('15%')
        .margin({ left: 10, right: 10 })

      Button(this.buttonText)
        .width('40%')
        .height(50)
        .backgroundColor(this.buttonColor)
        .margin({ bottom: 10 })
        .onClick(() => {
          this.onButtonClick();
        })
    }
    .width('100%')
    .margin({ bottom: 10 })
  }
}

@Component
export struct StepRecordItem {
  @Prop record: StepRecord;

  build() {
    Row() {
      Text(this.record.time)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('30%')

      Text(`${this.record.steps} 步`)
        .fontSize(16)
        .fontColor('#1698CE')
        .width('40%')

      Text(`约 ${(this.record.steps / 3 / 1000).toFixed(2)} 公里`)
        .fontSize(14)
        .fontColor('#666')
        .width('30%')
    }
    .width('100%')
    .padding(10)
    .borderRadius(8)
    .backgroundColor('#f7f7f7')
    .margin({ bottom: 8 })
  }
}