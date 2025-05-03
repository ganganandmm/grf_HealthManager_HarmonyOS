import { HeartRateRecord, StepTimeRecord, WaterRecord } from "../common/HealthDataModel";
@Extend(Text) function labelText() {
  .fontSize(16)
  .fontColor('#666')
}

@Extend(Text) function valueText() {
  .fontSize(24)
  .fontWeight(FontWeight.Bold)
}
@Component
export struct HealthDataCard {
  @Prop title: string;
  @Prop value: string;
  @Prop unit: string = '';
  @Prop color: string = '#1698CE';

  build() {
    Column() {
      Text(this.title)
        .labelText()
      Text(this.value + (this.unit ? ' ' + this.unit : ''))
        .valueText()
        .fontColor(this.color)
    }
    .width('45%')
    .padding(10)
    .borderRadius(8)
    .backgroundColor('#f7f7f7')
  }
}

// 心率记录项组件
@Component
export struct HeartRateRecordItem {
  @Prop record!: HeartRateRecord;

  build() {
    Row() {
      Text(this.record.time)
        .fontSize(16)
        .width('40%')
      Text(`${this.record.rate} 次/分`)
        .fontSize(16)
        .fontColor('#3498DB')
        .width('60%')
    }
    .width('100%')
    .padding(10)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}
@Component
export struct WaterRecordItem {
  @Prop record!: WaterRecord;

  build() {
    Row() {
      Text(this.record.time)
        .fontSize(16)
        .width('40%')
      Text(`${this.record.amount} ml`)
        .fontSize(16)
        .fontColor('#3498DB')
        .width('60%')
    }
    .width('100%')
    .padding(10)
    .justifyContent(FlexAlign.SpaceBetween)
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
  onInputChange: (value: string) => void = () => {};  // 提供默认空函数
  onButtonClick: () => void = () => {};  // 提供默认空函数

  build() {
    Row() {
      TextInput({ text: this.inputValue, placeholder: this.placeholder })
        .type(InputType.Number)
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
export struct StepTimeRecordItem {
  @Prop record: StepTimeRecord;

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