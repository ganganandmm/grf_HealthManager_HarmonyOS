import router from '@ohos.router';
import { AddFormMenuItem } from '@kit.ArkUI';
import { formBindingData, formProvider } from '@kit.FormKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import promptAction from '@ohos.promptAction';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { PreferencesHelper } from '../common/PreferencesHelper';

const TAG: string = 'LoginPage';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State rememberMe: boolean = false;
  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));
  private preferencesHelper: PreferencesHelper = new PreferencesHelper(getContext(this));

  aboutToAppear() {
    this.initializeDatabase();
    this.loadSavedUserInfo();
  }

  async loadSavedUserInfo() {
    try {
      const userInfo = await this.preferencesHelper.getUserInfo();
      if (userInfo.rememberMe) {
        this.username = userInfo.username;
        this.password = userInfo.password;
        this.rememberMe = userInfo.rememberMe;
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to load saved user info: ${error}`);
    }
  }

  async initializeDatabase() {
    try {
      const success = await this.dbHelper.initDatabase();
      if (!success) {
        promptAction.showToast({
          message: '数据库初始化失败',
          duration: 2000
        });
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Database initialization error: ${error}`);
      promptAction.showToast({
        message: '数据库初始化出错',
        duration: 2000
      });
    }
  }

  async login() {
    if (!this.username || !this.password) {
      promptAction.showToast({
        message: '用户名和密码不能为空',
        duration: 2000
      });
      return;
    }

    this.isLoading = true;
    try {
      const isValid = await this.dbHelper.validateUser(this.username, this.password);

      if (isValid) {
        await this.preferencesHelper.saveUserInfo(this.username, this.password, this.rememberMe);
        
        promptAction.showToast({
          message: '登录成功',
          duration: 2000
        });
        this.onJumpClick();
      } else {
        promptAction.showToast({
          message: '用户名或密码错误',
          duration: 2000
        });
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Login error: ${error}`);
      promptAction.showToast({
        message: '登录过程出错',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  onJumpClick() {
    router.pushUrl({
      url: 'pages/mainHome',
      params: {
        username: this.username
      }
    }, router.RouterMode.Standard, (err) => {
      if (err) {
        console.error(`grf_error_jump_failed code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info('Invoke success');
    });
  }

  onJumptoRegister() {
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

      TextInput({ placeholder: '请输入用户名', text: this.username })
        .type(InputType.Normal)
        .width('80%')
        .height(50)
        .margin({ top: '10%' })
        .onChange((value: string) => {
          this.username = value;
        })

      TextInput({ placeholder: '请输入密码', text: this.password })
        .type(InputType.Password)
        .width('80%')
        .height(50)
        .margin({ top: '5%' })
        .onChange((value: string) => {
          this.password = value;
        })

      Row() {
        Checkbox()
          .select(this.rememberMe)
          .onChange((isSelected: boolean) => {
            this.rememberMe = isSelected;
          })
        Text('记住密码')
          .fontSize(14)
          .margin({ left: 8 })
      }
      .width('80%')
      .margin({ top: '5%' })
      .justifyContent(FlexAlign.Start)

      Button(this.isLoading ? '登录中...' : '登录')
        .width('80%')
        .height(50)
        .margin({ top: '10%' })
        .backgroundColor('#1698CE')
        .enabled(!this.isLoading)
        .onClick(() => {
          this.login();
        })

      Text('没有账号？点击注册')
        .margin({ top: '5%' })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onJumptoRegister();
        })
    }
    .backgroundColor('#f5f5f5')
    .width('100%')
    .height('100%')
    .padding({ bottom: 20 })
  }
}