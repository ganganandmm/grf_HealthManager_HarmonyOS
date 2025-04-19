import router from '@ohos.router';
import { AddFormMenuItem } from '@kit.ArkUI';
import { formBindingData, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';

const tag = 'AddFormMenuItem';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';

  onJumpClick() {
    router.pushUrl({
      url: 'pages/mainHome' // 替换为你的目标页面路径
    }, router.RouterMode.Standard, (err) => {
      if (err) {
        console.error(`grf_error_jump_failed code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info('Invoke success');
    });
  }

  onJumptoRegister() {//跳转到登陆页面
    router.pushUrl({
      url: 'pages/register'
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
      Text("个人健康管理系统").fontSize(36).fontColor('#1698CE').margin({top:'20%'})
      // 添加头像
      Image($r('app.media.image_1'))
        .width(100)
        .height(100)
        .borderRadius(50)
        .margin({ top: '10%' })

      Text('登录')
        .fontSize(30)
        .fontWeight('bold')
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)
      // 用户名
      TextInput({ placeholder: '请输入用户名' })
        .type(InputType.Normal)
        .width('80%')
        .height(50)
        .margin({ top: '10%' })
        .onChange((value: string) => {
          this.username = value;
        });
      // 密码
      TextInput({ placeholder: '请输入密码' })
        .type(InputType.Password)
        .width('80%')
        .height(50)
        .margin({ top: '5%' })
        .onChange((value: string) => {
          this.password = value;
        });
      // 登录
      Button('登录')
        .width('80%')
        .height(50)
        .margin({ top: '10%' })
        .backgroundColor('#1698CE')
        .onClick(() => {
          this.onJumpClick(); // 调用跳转函数
        });
      Text('没有账号？点击注册')
        .margin({ top: '5%' })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onJumptoRegister();
        });


    }
    .backgroundColor('#f5f5f5')
    .width('100%')
    .height('100%')
    .padding({ bottom: 20 })
  }
}