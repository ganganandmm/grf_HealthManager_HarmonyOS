import router from '@ohos.router';
@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State email: string = '';
  @State phoneNumber: string = '';

  // 返回登录页面
  onBackClick() {
    router.back();
  }

  // 注册功能
  onRegisterClick() {
    // 验证表单数据
    if (this.username.length < 3) {
      AlertDialog.show({
        title: '提示',
        message: '用户名长度不能少于3个字符',
        confirm: {
          value: '确定',
          action: () => {
            console.info('用户名长度不足');
          }
        }
      });
      return;
    }

    if (this.password.length < 6) {
      AlertDialog.show({
        title: '提示',
        message: '密码长度不能少于6个字符',
        confirm: {
          value: '确定',
          action: () => {
            console.info('密码长度不足');
          }
        }
      });
      return;
    }

    if (this.password !== this.confirmPassword) {
      AlertDialog.show({
        title: '提示',
        message: '两次输入的密码不一致',
        confirm: {
          value: '确定',
          action: () => {
            console.info('密码不一致');
          }
        }
      });
      return;
    }

    // TODO: 处理注册逻辑
    console.info('注册信息:', this.username, this.email, this.phoneNumber);

    // 注册成功后返回登录页面
    AlertDialog.show({
      title: '注册成功',
      message: '账号注册成功，请返回登录',
      confirm: {
        value: '确定',
        action: () => {
          this.onBackClick();
        }
      }
    });
  }

  build() {
    Column() {
      // 头像上传区域
      Column() {
        Image($r('app.media.image_1'))
          .width(100)
          .height(100)
          .borderRadius(50)
      }
      .margin({ top: 24, bottom: 24 })
      .onClick(() => {
        console.info('上传头像');

      })

      // 表单区域
      Column() {
        // 用户名
        TextInput({ placeholder: '请输入用户名（至少3个字符）' })
          .type(InputType.Normal)
          .width('90%')
          .height(50)
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.username = value;
          })

        // 手机号
        TextInput({ placeholder: '请输入手机号' })
          .type(InputType.PhoneNumber)
          .width('90%')
          .height(50)
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.phoneNumber = value;
          })



        // 密码
        TextInput({ placeholder: '请输入密码（至少6个字符）' })
          .type(InputType.Password)
          .width('90%')
          .height(50)
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.password = value;
          })

        // 确认密码
        TextInput({ placeholder: '请确认密码' })
          .type(InputType.Password)
          .width('90%')
          .height(50)
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.confirmPassword = value;
          })



        // 注册按钮
        Button('注册')
          .width('90%')
          .height(50)
          .margin({ top: 24 })
          .backgroundColor('#1698CE')
          .onClick(() => {
            this.onRegisterClick();
          })

        // 返回登录
        Text('已有账号？返回登录')
          .margin({ top: 16 })
          .fontColor('#1698CE')
          .onClick(() => {
            this.onBackClick();
          })
      }
      .width('100%')
    }
    .backgroundColor('#f5f5f5')
    .width('100%')
    .height('100%')
  }
}