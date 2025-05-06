import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import Want from '@ohos.app.ability.Want'
import { DatabaseHelper } from '../common/DatabaseHelper';
import { HeartRateRecord, WaterRecord } from '../common/HealthDataModel';

// 可复用样式定义
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

// 数据类型接口定义
interface AggregatedDataPoint {
  date: string;
  averageRate: number;
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

interface GeneratedTypeLiteralInterface_2 {
  dataPoints: AggregatedDataPoint[];
  labels: string[];
}

@Entry
@Component
struct DataShow {
  // 状态变量定义
  @State chartHeight: number=0;                        // 图表高度
  @State dateRangeText: string = '';                   // 日期范围文本
  @State username: string = '';                        // 用户名
  @State userId: string = '';                          // 用户ID
  @State heartRate: string = '0';                      // 当前心率
  @State waterAmount: string = '0';                    // 当前饮水量
  @State currentDate: string = new Date().toISOString().split('T')[0];  // 当前日期
  @State selectedTab: number = 0;                      // 选中的标签页 (0:日, 1:周, 2:月)
  @State displayMode: string = 'heartRate';            // 显示模式 ('heartRate':心率 或 'waterAmount':饮水量)
  @State heartRateRecords: HeartRateRecord[] = [];    // 心率记录数组
  @State waterRecords: WaterRecord[] = [];             // 饮水记录数组
  @State selectedDate: Date = new Date();              // 选中的日期
  @State formattedDate: string = '';                   // 格式化后的日期
  @State restingHeartRate: number = 0;                 // 静息心率
  @State highestHeartRate: number = 0;                 // 最高心率
  @State lowestHeartRate: number = 0;                  // 最低心率
  @State averageHeartRate: number = 0;                 // 平均心率
  @State lastHeartRateTime: string = '';               // 最近心率测量时间
  @State weekDates: string[] = [];                     // 本周日期数组
  @State monthDates: string[] = [];                    // 本月日期数组
  @State totalSteps: number = 0;                       // 总步数(周/月)
  @State averageSleepHours: number = 0;                // 平均睡眠时间(周/月)
  @State randomIndex : number = 0;                     // 随机索引(未使用)

  // 画布相关属性
  private canvasWidth: number = 0;                     // 画布宽度
  private canvasHeight: number = 0;                    // 画布高度
  private chartPadding: number = 10;                   // 图表内边距
  private yAxisWidth: number = 30;                     // Y轴宽度
  private xAxisHeight: number = 30;                    // X轴高度
  private settings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));

  // 组件即将出现时的生命周期回调
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

  // 组件即将销毁时的生命周期回调
  aboutToDisappear() {
    this.dbHelper.closeDatabase();
  }

  // 更新格式化日期并计算周/月日期
  updateFormattedDate() {
    const year = this.selectedDate.getFullYear();
    const month = String(this.selectedDate.getMonth() + 1).padStart(2, '0');
    const day = String(this.selectedDate.getDate()).padStart(2, '0');
    this.formattedDate = `${year}-${month}-${day}`;
    this.currentDate = this.formattedDate;

    this.calculateWeekDates();
    this.calculateMonthDates();
  }

  // 计算本周的所有日期
  calculateWeekDates() {
    const date = new Date(this.selectedDate);
    const day = date.getDay(); // 0-6，周日为0
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

    // 设置日期范围文本
    const weekStartText = `${weekStart.getMonth() + 1}月${weekStart.getDate()}日`;
    const weekEndDate = new Date(weekStart);
    weekEndDate.setDate(weekStart.getDate() + 6);
    const weekEndText = `${weekEndDate.getMonth() + 1}月${weekEndDate.getDate()}日`;
    this.dateRangeText = `${weekStartText} - ${weekEndText}`;
  }

  // 计算本月的所有日期
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

  // 加载特定日期的数据
  async loadDataForDate(date: string) {
    if (!this.userId) {
      return;
    }

    try {
      const userId = parseInt(this.userId);
      // 获取心率数据
      const heartRateRecords = await this.dbHelper.getHeartRateRecords(userId, date);
      this.heartRateRecords = heartRateRecords;

      if (heartRateRecords.length > 0) {
        // 获取最新心率记录
        const latestRecord = heartRateRecords[heartRateRecords.length - 1];
        this.heartRate = latestRecord.rate.toString();
        this.lastHeartRateTime = `${date} ${latestRecord.time}`;

        // 计算心率统计信息
        const rates = heartRateRecords.map(record => record.rate);
        this.highestHeartRate = Math.max(...rates);
        this.lowestHeartRate = Math.min(...rates);
        this.averageHeartRate = Math.round(rates.reduce((sum, rate) => sum + rate, 0) / rates.length);

        // 估算静息心率
        this.restingHeartRate = this.lowestHeartRate + 5;
        if (this.restingHeartRate > this.averageHeartRate) {
          this.restingHeartRate = this.lowestHeartRate;
        }
      } else {
        // 没有心率记录时重置所有数据
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

  // 加载周数据
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

      // 计算心率统计信息
      if (allHeartRates.length > 0) {
        this.highestHeartRate = Math.max(...allHeartRates);
        this.lowestHeartRate = Math.min(...allHeartRates);
        this.averageHeartRate = Math.round(totalHeartRate / totalHeartRateCount);
        this.restingHeartRate = this.lowestHeartRate + 5;
        if (this.restingHeartRate > this.averageHeartRate) {
          this.restingHeartRate = this.lowestHeartRate;
        }

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

      // 计算心率统计信息
      if (allHeartRates.length > 0) {
        this.highestHeartRate = Math.max(...allHeartRates);
        this.lowestHeartRate = Math.min(...allHeartRates);
        this.averageHeartRate = Math.round(totalHeartRate / totalHeartRateCount);
        this.restingHeartRate = this.lowestHeartRate + 5;
        if (this.restingHeartRate > this.averageHeartRate) {
          this.restingHeartRate = this.lowestHeartRate;
        }

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

      // 绘制月度心率图表
      this.drawHeartRateChart();
    } catch (error) {
      console.error(`加载月数据失败: ${error}`);
    }
  }

  // 打开系统日历应用
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

  // 处理聚合数据
  processAggregatedData(dates: string[]): GeneratedTypeLiteralInterface_2 {
    const dataPoints: AggregatedDataPoint[] = [];
    const labels: string[] = [];

    for (const date of dates) {
      // 获取特定日期的所有心率记录
      const dayRecords = this.heartRateRecords.filter(record => record.date === date);

      if (dayRecords.length > 0) {
        // 计算该日心率平均值
        const rates = dayRecords.map(record => record.rate);
        const avgRate = Math.round(rates.reduce((sum, rate) => sum + rate, 0) / rates.length);

        dataPoints.push({
          date: date,
          averageRate: avgRate
        });

        labels.push(date);
      } else {
        labels.push(date);
      }
    }

    return { dataPoints, labels };
  }

  /**
   * 绘制心率图表的方法
   * 根据不同时间段（日/周/月）的选择显示相应的心率数据图表
   */
  drawHeartRateChart() {
    // 清空整个画布，准备重新绘制
    this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 检查是否有心率数据，如果没有则显示提示信息
    if (this.heartRateRecords.length === 0) {
      this.context.fillStyle = '#888888';  // 设置文字颜色为灰色
      this.context.textAlign = 'center';   // 文字居中对齐
      this.context.font = '32px sans-serif'; // 设置字体大小和类型
      this.context.fillText('暂无心率数据', this.canvasWidth / 2, this.canvasHeight / 2); // 在画布中央显示提示文字
      return; // 没有数据则提前退出函数
    }

    // 对心率记录按时间排序，使用数组解构创建副本避免修改原数组
    const sortedRecords = [...this.heartRateRecords].sort((a, b) => {
      return a.time.localeCompare(b.time); // 使用字符串比较方法按时间升序排序
    });

    // 计算心率的范围，用于确定Y轴刻度
    const rates = sortedRecords.map(record => record.rate); // 提取所有心率值
    const minRate = Math.max(Math.min(...rates) - 10, 0);  // 最小心率值减10，但不小于0
    const maxRate = Math.max(...rates) + 10;               // 最大心率值加10，提供上下边距
    const rateRange = maxRate - minRate;                   // 计算心率范围区间大小

    // 定义图表的绘制区域，考虑了边距和轴的宽度
    const chartX = this.chartPadding + this.yAxisWidth;    // 图表左边界位置
    const chartY = this.chartPadding;                      // 图表上边界位置
    const chartWidth = this.canvasWidth - this.yAxisWidth - this.chartPadding * 2;  // 图表宽度
    const chartHeight = this.canvasHeight - this.xAxisHeight - this.chartPadding * 2; // 图表高度

    // 准备数据点和X轴标签的数组
    let dataPoints: HeartRateRecord[] | AggregatedDataPoint[] = [];
    let xLabels: string[] = [];

    // 根据选择的视图类型(日/周/月)准备相应的数据
    if (this.selectedTab === 0) {
      // 日视图：直接使用排序后的记录
      dataPoints = sortedRecords;
      xLabels = sortedRecords.map(record => record.time); // X轴标签为时间
    } else if (this.selectedTab === 1) {
      // 周视图：处理聚合的周数据
      const weekData = this.processAggregatedData(this.weekDates);
      dataPoints = weekData.dataPoints; // 获取处理后的数据点
      xLabels = weekData.labels;       // 获取处理后的标签
    } else {
      // 月视图：处理聚合的月数据
      const monthData = this.processAggregatedData(this.monthDates);
      dataPoints = monthData.dataPoints;
      xLabels = monthData.labels;
    }

    // 绘制Y轴主线
    this.context.strokeStyle = '#CCCCCC'; // 设置轴线颜色为浅灰色
    this.context.lineWidth = 1;          // 设置线宽为1像素
    this.context.beginPath();            // 开始一个新的路径
    this.context.moveTo(chartX, chartY); // 移动到Y轴起点
    this.context.lineTo(chartX, chartY + chartHeight); // 画线到Y轴终点
    this.context.stroke();               // 绘制路径

    // 绘制Y轴刻度标签和水平网格线
    this.context.fillStyle = '#666666';  // 设置标签文字颜色为深灰色
    this.context.textAlign = 'right';    // 文字右对齐
    this.context.font = '32px sans-serif'; // 设置字体

    const yLabelCount = 5;              // Y轴标签数量
    for (let i = 0; i <= yLabelCount; i++) {
      // 计算当前刻度对应的心率值
      const yValue = minRate + (rateRange * (yLabelCount - i) / yLabelCount);
      // 计算当前刻度在Y轴上的位置
      const yPos = chartY + (i * chartHeight / yLabelCount);

      // 绘制Y轴刻度文字标签
      this.context.fillText(Math.round(yValue).toString(), chartX - 5, yPos + 4);

      // 绘制对应的水平网格线
      this.context.strokeStyle = '#EEEEEE'; // 设置网格线颜色为浅灰色
      this.context.beginPath();
      this.context.moveTo(chartX, yPos);    // 从Y轴刻度位置开始
      this.context.lineTo(chartX + chartWidth, yPos); // 画到图表右边界
      this.context.stroke();
    }

    // 绘制X轴主线
    this.context.strokeStyle = '#CCCCCC';
    this.context.beginPath();
    this.context.moveTo(chartX, chartY + chartHeight); // 从X轴起点开始
    this.context.lineTo(chartX + chartWidth, chartY + chartHeight); // 画到X轴终点
    this.context.stroke();

    // 绘制X轴标签
    this.context.textAlign = 'center';   // 文字居中对齐

    // 限制X轴标签数量，避免标签过多导致拥挤
    const maxLabels = Math.min(6, xLabels.length); // 最多显示6个标签或所有标签数(如果少于6个)
    const labelStep = Math.ceil(xLabels.length / maxLabels); // 计算标签间隔步长

    // 遍历并绘制X轴标签和垂直网格线
    for (let i = 0; i < xLabels.length; i += labelStep) {
      if (i < xLabels.length) {
        const label = xLabels[i];
        // 根据视图类型调整标签显示内容
        const displayLabel = this.selectedTab === 0
          ? label.substring(0, 5)     // 日视图只显示前5个字符
          : label.substring(5);       // 周/月视图显示从第5个字符开始的内容

        // 计算标签在X轴上的位置
        const xPos = chartX + (i / (xLabels.length - 1)) * chartWidth;

        // 绘制X轴标签文字
        this.context.fillText(displayLabel, xPos, chartY + chartHeight + 20);

        // 绘制垂直网格线
        this.context.strokeStyle = '#EEEEEE';
        this.context.beginPath();
        this.context.moveTo(xPos, chartY);              // 从图表上边界开始
        this.context.lineTo(xPos, chartY + chartHeight); // 画到图表下边界
        this.context.stroke();
      }
    }

    // 绘制心率折线图，至少需要两个点才能绘制
    if (dataPoints.length > 1) {
      // 设置折线样式
      this.context.strokeStyle = '#E74C3C'; // 设置折线颜色为红色
      this.context.lineWidth = 2;          // 设置线宽为2像素
      this.context.beginPath();

      // 绘制连接所有数据点的折线
      for (let i = 0; i < dataPoints.length; i++) {
        const point = dataPoints[i];
        // 根据视图类型获取不同的心率值
        const rate = this.selectedTab === 0
          ? (point as HeartRateRecord).rate          // 日视图：直接使用记录的心率
          : (point as AggregatedDataPoint).averageRate; // 周/月视图：使用平均心率

        // 计算数据点在图表中的坐标
        const xPos = chartX + (i / (dataPoints.length - 1)) * chartWidth;
        // Y坐标计算：将心率值映射到图表高度范围内
        const yPos = chartY + chartHeight - ((rate - minRate) / rateRange) * chartHeight;

        if (i === 0) {
          this.context.moveTo(xPos, yPos); // 第一个点移动到位置
        } else {
          this.context.lineTo(xPos, yPos); // 后续点连线到位置
        }
      }

      this.context.stroke(); // 绘制整条折线

      // 绘制每个数据点的圆点和数值标签
      this.context.fillStyle = '#FFFFFF';   // 设置圆点填充颜色为白色
      this.context.strokeStyle = '#E74C3C'; // 设置圆点边框颜色为红色
      this.context.lineWidth = 2;          // 设置边框宽度
      this.context.textAlign = 'center';   // 文字居中对齐

      // 遍历所有数据点
      for (let i = 0; i < dataPoints.length; i++) {
        const point = dataPoints[i];
        // 根据视图类型获取心率值
        const rate = this.selectedTab === 0
          ? (point as HeartRateRecord).rate
          : (point as AggregatedDataPoint).averageRate;

        // 计算数据点在图表中的坐标
        const xPos = chartX + (i / (dataPoints.length - 1)) * chartWidth;
        const yPos = chartY + chartHeight - ((rate - minRate) / rateRange) * chartHeight;

        // 绘制数据点的圆圈
        this.context.beginPath();
        this.context.arc(xPos, yPos, 4, 0, Math.PI * 2); // 绘制半径为4的圆
        this.context.fill();   // 填充圆内部
        this.context.stroke(); // 绘制圆边框

        // 绘制心率数值标签
        this.context.fillStyle = '#E74C3C';          // 设置文字颜色为红色
        this.context.font = 'bold 32px sans-serif';  // 设置粗体字
        this.context.fillText(rate.toString(), xPos, yPos - 15); // 在数据点上方显示心率值

        this.context.fillStyle = '#FFFFFF'; // 恢复填充颜色为白色，为下一个点做准备
      }
    }
  }
  // 构建UI
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        // 返回按钮
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

        // 标题文本
        Text(this.displayMode === 'heartRate' ? "心率" : "饮水量")
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .justifyContent(FlexAlign.SpaceBetween)

      // 切换心率/饮水量按钮
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

      // 日期选择器
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

      // 日/周/月切换标签
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
              Text("最近心率").subtitleText()
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

            if (this.selectedTab === 0) {
              // 日视图显示心率趋势图
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
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
            } else {
              // 周/月视图显示心率数据统计
              Column() {
                Text(this.selectedTab === 1 ? "本周心率概览" : "本月心率概览")
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 15 })
                  .alignSelf(ItemAlign.Start)

                Grid() {
                  GridItem() {
                    Column() {
                      Text(this.restingHeartRate.toString())
                        .valueText()
                      Text("次/分")
                        .fontSize(16)
                        .fontColor('#666')
                      Text("静息心率")
                        .labelText()
                        .margin({ top: 5 })
                    }
                    .width('100%')
                    .height('100%')
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor('#f5f7fa')
                    .borderRadius(8)
                  }

                  GridItem() {
                    Column() {
                      Text(this.averageHeartRate.toString())
                        .valueText()
                      Text("次/分")
                        .fontSize(16)
                        .fontColor('#666')
                      Text("平均心率")
                        .labelText()
                        .margin({ top: 5 })
                    }
                    .width('100%')
                    .height('100%')
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor('#f5f7fa')
                    .borderRadius(8)
                  }

                  GridItem() {
                    Column() {
                      Text(this.lowestHeartRate.toString())
                        .valueText()
                      Text("次/分")
                        .fontSize(16)
                        .fontColor('#666')
                      Text("最低心率")
                        .labelText()
                        .margin({ top: 5 })
                    }
                    .width('100%')
                    .height('100%')
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor('#f5f7fa')
                    .borderRadius(8)
                  }

                  GridItem() {
                    Column() {
                      Text(this.highestHeartRate.toString())
                        .valueText()
                      Text("次/分")
                        .fontSize(16)
                        .fontColor('#666')
                      Text("最高心率")
                        .labelText()
                        .margin({ top: 5 })
                    }
                    .width('100%')
                    .height('100%')
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor('#f5f7fa')
                    .borderRadius(8)
                  }
                }
                .columnsTemplate('1fr 1fr')
                .rowsTemplate('1fr 1fr')
                .columnsGap(10)
                .rowsGap(10)
                .width('100%')
                .height(200)

                Text(this.selectedTab === 1 ? "本周期间" : "本月期间")
                  .fontSize(14)
                  .fontColor('#888888')
                  .margin({ top: 10 })
                  .alignSelf(ItemAlign.Center)
              }
              .width('90%')
              .padding(15)
              .margin({ top: 10, bottom: 20 })
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .shadow({ radius: 4, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
            }

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
                        // Modified part - showing date alongside time
                        Column() {
                          Text(item.date)
                            .fontSize(14)
                            .fontColor('#888888')
                          Text(item.time)
                            .fontSize(16)
                        }
                        .width('40%')
                        .alignItems(HorizontalAlign.Start)

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
              Stack() {
                // 根据当前选择的视图类型，设置不同的total值
                Progress({
                  value: Number(this.waterAmount),
                  total: this.selectedTab === 0 ? 2000 : (this.selectedTab === 1 ? 15000 : 60000),
                  type: ProgressType.Ring
                })
                  .width('80%')
                  .height(260)
                  .style({
                    strokeWidth: 20,
                    scaleCount: 15,
                    scaleWidth: 5
                  })
                  .color('#3498DB')
                  .backgroundColor('#EEEEEE')

                Column() {
                  if (this.selectedTab === 0) {
                    // 日视图
                    Text(`${this.waterAmount}`)
                      .fontSize(28)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333')

                    Text(`/ 2000ml`)
                      .fontSize(16)
                      .fontColor('#666')
                      .margin({ top: 5 })
                  } else if (this.selectedTab === 1) {
                    // 周视图
                    Text(`${this.waterAmount}`)
                      .fontSize(28)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333')

                    Text(`/ 15000ml`)
                      .fontSize(16)
                      .fontColor('#666')
                      .margin({ top: 5 })

                    Text("本周饮水")
                      .fontSize(14)
                      .fontColor('#888')
                      .margin({ top: 8 })
                  } else {
                    // 月视图
                    Text(`${this.waterAmount}`)
                      .fontSize(28)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#333')

                    Text(`/ 60000ml`)
                      .fontSize(16)
                      .fontColor('#666')
                      .margin({ top: 5 })

                    Text("本月饮水")
                      .fontSize(14)
                      .fontColor('#888')
                      .margin({ top: 8 })
                  }

                  Row() {
                    // 显示完成比例，限制最大为100%
                    Text(`${Math.min(Math.round(Number(this.waterAmount) / (this.selectedTab === 0 ? 2000 : (this.selectedTab === 1 ? 15000 : 60000)) * 100), 100)}%`)
                      .fontSize(18)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#2ECC71')
                  }
                  .margin({ top: 10 })
                }
                .alignItems(HorizontalAlign.Center)
              }
              .width('100%')
              .height(260)
              .alignContent(Alignment.Center)

              // 饮水量建议文本
              Text(this.selectedTab === 0 ? "建议每日饮水量: 2000ml" :
                (this.selectedTab === 1 ? "建议每周饮水量: 15000ml" : "建议每月饮水量: 60000ml"))
                .fontSize(14)
                .fontColor('#888888')
                .margin({ top: 20 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
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
                        // Modified part - showing date alongside time
                        Column() {
                          Text(item.date)
                            .fontSize(14)
                            .fontColor('#888888')
                          Text(item.time)
                            .fontSize(16)
                        }
                        .width('40%')
                        .alignItems(HorizontalAlign.Start)

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