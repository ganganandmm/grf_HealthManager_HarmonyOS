import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { hilog } from '@kit.PerformanceAnalysisKit';

export const TAG: string = 'ProfileTab';
const DOMAIN_NUMBER: number = 0xFF00;

@Extend(Text)
function titleText() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .margin({ top: 10, bottom: 20 })
}

@Extend(Column)
function cardContainer() {
  .width('90%')
  .padding(15)
  .borderRadius(8)
  .backgroundColor('#f7f7f7')
  .margin({ bottom: 10 })
}

@Extend(Button)
function primaryButton() {
  .width('100%')
  .height(40)
  .backgroundColor('#27AE60')
  .margin({ bottom: 10 })
}

@Extend(Row)
function menuItem() {
  .width('100%')
  .padding(15)
  .backgroundColor('#ffffff')
  .borderRadius(8)
  .margin({ bottom: 10 })
}

@Component
export struct ProfileTab {
  @Link username: string;
  @Link userId: number;
  @Link userAvatarPath: string;

  private ClickJumpToShowData: () => void = () => {};

  @Builder
  UserAvatar() {
    Column() {
      // 用户头像
      if (this.userAvatarPath) {
        // 如果有自定义头像，显示自定义头像
        Image(this.userAvatarPath)
          .width(80)
          .height(80)
          .borderRadius(40)
      } else {
        // 否则显示默认头像
        Image($r('app.media.avater_1'))
          .width(80)
          .height(80)
          .borderRadius(40)
      }
    }
    .margin({ right: 20 })
  }

  @Builder
  UserInfo() {
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

  @Builder
  ProfileCard() {
    Column() {
      Row() {
        this.UserAvatar()
        this.UserInfo()
      }
      .width('100%')
      .padding(10)

      Button('编辑个人资料')
        .primaryButton()
        .onClick(() => {
          hilog.info(DOMAIN_NUMBER, TAG,
            `Navigating to myInfo with username: ${this.username}, userId: ${this.userId}`);
          router.pushUrl({
            url: 'pages/changeMyInfo',
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
  }

  @Builder
  MenuItem(icon: Resource, title: string, onClick: () => void) {
    Row() {
      Image(icon)
        .width(30)
        .height(30)
        .margin({ right: 10 })
      Text(title)
        .fontSize(16)
        .layoutWeight(1)
      Image(icon)
        .width(20)
        .height(20)
    }
    .menuItem()
    .onClick(onClick)
  }

  @Builder
  MenuSection() {
    Column() {
      // 健康数据分析菜单项
      this.MenuItem($r('app.media.data'), '健康数据分析', () => {
        this.ClickJumpToShowData();
      })

      // 健康目标设置菜单项
      this.MenuItem($r('app.media.target'), '健康目标设置', () => {
        promptAction.showToast({
          message: '健康目标设置功能即将上线',
          duration: 2000
        });
      })

      // 健康提醒菜单项
      this.MenuItem($r('app.media.remind'), '健康提醒', () => {
        promptAction.showToast({
          message: '健康提醒功能即将上线',
          duration: 2000
        });
      })

      // 设置菜单项
      this.MenuItem($r('app.media.settings'), '设置', () => {
        promptAction.showToast({
          message: '设置功能即将上线',
          duration: 2000
        });
      })

      // 退出登录菜单项
      this.MenuItem($r('app.media.logout'), '退出登录', () => {
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

  build() {
    Column() {
      Text('个人中心')
        .titleText()

      this.ProfileCard()
      this.MenuSection()
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#f5f5f5')
  }
}