import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import promptAction from '@ohos.promptAction';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { PreferencesHelper } from '../common/PreferencesHelper';

const TAG: string = 'LoginPage';

@Entry
@Component
struct LoginPage {   // 登录页面组件
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false; //判断是否登录中
  @State rememberMe: boolean = false;  //是否记住密码
  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));
  private preferencesHelper: PreferencesHelper = new PreferencesHelper(getContext(this));

  aboutToAppear() {
    this.initializeDatabase(); //初始化数据库
    this.loadSavedUserInfo(); // 加载已保存的用户信息
  }

  async loadSavedUserInfo() { // 加载已保存的用户信息
    try {
      const userInfo = await this.preferencesHelper.getUserInfo(); //从preferences中返回用户信息，以此达到已登录用户不用多次输入密码登录
      if (userInfo.rememberMe) {
        this.username = userInfo.username;
        this.password = userInfo.password;
        this.rememberMe = userInfo.rememberMe;
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to load saved user info: ${error}`);
    }
  }

  async initializeDatabase() { // 初始化数据库
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

  async login() {  // 登录逻辑实现
    if (!this.username || !this.password) {
      promptAction.showToast({
        message: '用户名和密码不能为空',
        duration: 2000
      });
      return;
    }

    this.isLoading = true;

    try {
      // 延迟1秒钟模拟后台认证过程
      await new Promise<void>(resolve => setTimeout(resolve, 2000));

      const isValid = await this.dbHelper.validateUser(this.username, this.password); //检查用户信息是否正确

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

  onJumpClick() { // 登录之后进行跳转到主页面
    router.pushUrl({
      url: 'pages/mainHome',
      params: {
        username: this.username,
        newLogin: true  // 添加新登录标记，用来区分是否是新用户
      }
    }, router.RouterMode.Standard, (err) => {
      if (err) {
        console.error(`grf_error_jump_failed code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info('Invoke success');
    });
  }

  onJumptoRegister() { //跳转到注册页面
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

  @Builder
  HeaderSection() {
    Column() {
      Text("个人健康管理系统").fontSize(36).fontColor('#1698CE').margin({top:'20%'})
      Image($r('app.media.avater_1'))
        .width(100)
        .height(100)
        .borderRadius(50)
        .margin({ top: '10%' })

      Text('登录')
        .fontSize(30)
        .fontWeight('bold')
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)
    }
  }

  @Builder
  InputFields() {
    Column() {
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
    }
  }

  @Builder
  LoginButton() {
    Button() {
      Row() {
        if (this.isLoading) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color(Color.White)
            .margin({ right: 8 })
          Text('登录中...')
            .fontColor(Color.White)
        } else {
          Text('登录')
            .fontColor(Color.White)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('80%')
    .height(50)
    .margin({ top: '10%' })
    .backgroundColor('#1698CE')
    .enabled(!this.isLoading)
    .onClick(() => {
      this.login();
    })
  }

  @Builder
  RegisterLink() {
    Text('没有账号？点击注册')
      .margin({ top: '5%' })
      .textAlign(TextAlign.Center)
      .onClick(() => {
        this.onJumptoRegister();
      })
  }

  build() {
    Column() {
      this.HeaderSection()
      this.InputFields()
      this.LoginButton()
      this.RegisterLink()
    }
    .backgroundColor('#f5f5f5')
    .width('100%')
    .height('100%')
    .padding({ bottom: 20 })
  }
}