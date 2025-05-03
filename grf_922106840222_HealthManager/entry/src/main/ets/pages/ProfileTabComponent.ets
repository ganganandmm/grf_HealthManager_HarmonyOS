import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'ProfileTabComponent';
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
export struct ProfileTabComponent {
  @Link username: string;
  @Link userId: number;
  @Link myHeight: number;
  @Link myWeight: number;
  @Link bmi: number;

  build() {
    Column() {
      Text('个人中心')
        .titleText()
      Column() {
        Row() {
          Column() {
            // 用户头像
            Image($r('app.media.image_1'))
              .width(80)
              .height(80)
              .borderRadius(40)
          }
          .margin({ right: 20 })

          Column() {
            Row() {
              Text('用户名：')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .width('30%')
              Text(this.username)
                .fontSize(16)
                .width('70%')
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })

            Row() {
              Text('用户ID：')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .width('30%')
              Text(this.userId.toString())
                .fontSize(16)
                .width('70%')
            }
            .width('100%')
            .padding({ top: 5, bottom: 5 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(10)

        Button('编辑个人资料')
          .primaryButton()
          .onClick(() => {
            hilog.info(0x0000, TAG, `Navigating to myInfo with username: ${this.username}, userId: ${this.userId}`);
            router.pushUrl({
              url: 'pages/myInfo',
              params: {
                username: this.username,
                userId: this.userId,
                isEdit: true
              }
            }, router.RouterMode.Standard, (err) => {
              if (err) {
                console.error(`跳转到个人信息页面失败: ${err.code}, ${err.message}`);
                promptAction.showToast({ message: '跳转失败，请重试' });
                return;
              }
              console.info('跳转到个人信息页面成功');
            });
          })
      }
      .cardContainer()
      .margin({ bottom: 20 })


      Column() {
        // 健康数据分析菜单项
        Row() {
          Image($r('app.media.data'))
            .width(30)
            .height(30)
            .margin({ right: 10 })
          Text('健康数据分析')
            .fontSize(16)
            .layoutWeight(1)
          Image($r('app.media.data'))
            .width(20)
            .height(20)
        }
        .menuItem()
        .onClick(() => {
          this.ClickJumpToShowData();
        })

        // 健康目标设置菜单项
        Row() {
          Image($r('app.media.target'))
            .width(30)
            .height(30)
            .margin({ right: 10 })
          Text('健康目标设置')
            .fontSize(16)
            .layoutWeight(1)
          Image($r('app.media.target'))
            .width(20)
            .height(20)
        }
        .menuItem()
        .onClick(() => {
          promptAction.showToast({
            message: '健康目标设置功能即将上线',
            duration: 2000
          });
        })

        // 健康提醒菜单项
        Row() {
          Image($r('app.media.remind'))
            .width(30)
            .height(30)
            .margin({ right: 10 })
          Text('健康提醒')
            .fontSize(16)
            .layoutWeight(1)
          Image($r('app.media.remind'))
            .width(20)
            .height(20)
        }
        .menuItem()
        .onClick(() => {
          promptAction.showToast({
            message: '健康提醒功能即将上线',
            duration: 2000
          });
        })

        // 设置菜单项
        Row() {
          Image($r('app.media.settings'))
            .width(30)
            .height(30)
            .margin({ right: 10 })
          Text('设置')
            .fontSize(16)
            .layoutWeight(1)
          Image($r('app.media.settings'))
            .width(20)
            .height(20)
        }
        .menuItem()
        .onClick(() => {
          promptAction.showToast({
            message: '设置功能即将上线',
            duration: 2000
          });
        })

        // 退出登录菜单项
        Row() {
          Image($r('app.media.logout'))
            .width(30)
            .height(30)
            .margin({ right: 10 })
          Text('退出登录')
            .fontSize(16)
            .layoutWeight(1)
          Image($r('app.media.logout'))
            .width(20)
            .height(20)
        }
        .menuItem()
        .onClick(() => {
          router.clear();
          router.pushUrl({
            url: 'pages/Login'
          }, router.RouterMode.Standard, (err) => {
            if (err) {
              console.error(`退出登录失败 code: ${err.code}, message: ${err.message}`);
              promptAction.showToast({ message: '退出登录失败，请重试' });
              return;
            }
            console.info('退出登录成功');
          });
        })
      }
      .width('90%')
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#f5f5f5')
  }

  // 需要实现这个函数，但在原代码中没有见到ProfileTabComponent的实现，所以假设它从MainHome组件中继承
  private ClickJumpToShowData() {
    router.pushUrl({
      url: 'pages/dataShow',
      params: {
        username: this.username,
        userId: this.userId.toString(),
        steps: '0',  // 这些值在原组件中可能通过其他方式获取
        heartRate: '0',
        sleepHours: '0',
        waterAmount: '0',
        date: new Date().toISOString().split('T')[0]
      }
    }, router.RouterMode.Standard, (err) => {
      if (err) {
        console.error(`error_jump_failed code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info('Navigate to ShowData success');
    });
  }
}