import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'MainHome';

interface RouteParams {
  username?: string;
}

@Entry
@Component
struct MainHome {
  @State username: string = '';

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    if (params && params.username) {
      this.username = params.username;
    }
  }
  ClickJumpToShowData() {
    router.pushUrl({
      url: 'pages/ShowData', // 替换为你的目标页面路径
      params: {
        username: this.username // 可以传递用户名到主页面
      }
    }, router.RouterMode.Standard, (err) => {
      if (err) {
        console.error(`grf_error_jump_failed code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info('Invoke success');
    });
  }

  build() {
    Column() {
      // 标题和用户信息
      Row() {
        Text("个人健康管理系统")
          .fontSize(24)
          .fontColor('#1698CE')
          .fontWeight(FontWeight.Bold)

        Blank()

        // 显示当前登录用户名
        if (this.username) {
          Text(`欢迎，${this.username}`)
            .fontSize(18)
            .fontColor('#333')
        }
      }
      .width('90%')
      .padding({ top: 20, bottom: 20 })

      // 分割线
      Divider()
        .width('90%')
        .height(1)
        .backgroundColor('#ddd')

      // 主要内容区域
      Column() {
        Text('主页内容')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 20 })

        Grid() {
          // 健康数据模块
          GridItem() {
            Column() {
              Image($r('app.media.image_1'))
                .width(50)
                .height(50)
                .margin({ bottom: 10 })
                .onClick(()=>{
                  this.ClickJumpToShowData();
                })
              Text('数据显示')
                .fontSize(16)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#e6f7ff')
            .borderRadius(10)
            .justifyContent(FlexAlign.Center)
          }

          GridItem() {
            Column() {
              Image($r('app.media.image_1'))
                .width(50)
                .height(50)
                .margin({ bottom: 10 })
              Text('我的运动')
                .fontSize(16)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#f6ffed')
            .borderRadius(10)
            .justifyContent(FlexAlign.Center)
          }

          GridItem() {
            Column() {
              Image($r('app.media.image_1'))
                .width(50)
                .height(50)
                .margin({ bottom: 10 })
              Text('数据录入')
                .fontSize(16)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#fff7e6')
            .borderRadius(10)
            .justifyContent(FlexAlign.Center)
          }

          GridItem() {
            Column() {
              Image($r('app.media.image_1'))
                .width(50)
                .height(50)
                .margin({ bottom: 10 })
              Text('个人中心')
                .fontSize(16)
            }
            .width('100%')
            .height('100%')
            .backgroundColor('#fcf5ff')
            .borderRadius(10)
            .justifyContent(FlexAlign.Center)
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsTemplate('1fr 1fr')
        .columnsGap(20)
        .rowsGap(20)
        .width('90%')
        .height(300)
      }
      .width('100%')
      .padding(20)

      Button('退出登录')
        .width('80%')
        .height(50)
        .margin({ top: 30 })
        .backgroundColor('#1698CE')
        .onClick(() => {
          router.clear();
          router.pushUrl({
            url: 'pages/index', // 返回登录页面
          });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}