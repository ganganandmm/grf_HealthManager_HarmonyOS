import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { User } from '../common/UserModel';

const TAG: string = 'RegisterPage';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isLoading: boolean = false;

  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));

  aboutToAppear() {
    // 初始化数据库
    this.initializeDatabase();
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

  async register() { //登录方法
    // 表单验证 ，确保所填字段非空
    if (!this.username || !this.password || !this.confirmPassword) {
      promptAction.showToast({
        message: '请填写所有字段',
        duration: 2000
      });
      return;
    }

    if (this.password !== this.confirmPassword) { //确保两次密码一致
      promptAction.showToast({
        message: '两次输入的密码不一致',
        duration: 2000
      });
      return;
    }

    this.isLoading = true;
    try {
      // 检查用户名是否已存在
      const existingUsers = await this.dbHelper.queryUserByUsername(this.username);
      if (existingUsers.length > 0) {
        promptAction.showToast({
          message: '用户名已存在',
          duration: 2000
        });
        this.isLoading = false;
        return;
      }

      // 创建新用户
      const newUser = new User(this.username, this.password);
      const success = await this.dbHelper.insertUser(newUser);

      if (success) {
        promptAction.showToast({ //弹出提醒
          message: '注册成功', // 提醒信息
          duration: 2000 // 持续时间
        });
        // 返回登录页面
        router.back();
      } else {
        promptAction.showToast({
          message: '注册失败',
          duration: 2000
        });
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Register error: ${error}`);
      promptAction.showToast({
        message: '注册过程出错',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Text("个人健康管理系统").fontSize(36).fontColor('#1698CE').margin({top:'10%'})
     //默认头像，可在用户信息修改页面进行换头像
      Image($r('app.media.avater_1'))
        .width(100)
        .height(100)
        .borderRadius(50)
        .margin({ top: '5%' })

      Text('注册')
        .fontSize(30)
        .fontWeight('bold')
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)

      // 用户名
      TextInput({ placeholder: '请输入用户名' })
        .type(InputType.Normal)
        .width('80%')
        .height(50)
        .margin({ top: '8%' })
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

      // 确认密码
      TextInput({ placeholder: '请确认密码' })
        .type(InputType.Password)
        .width('80%')
        .height(50)
        .margin({ top: '5%' })
        .onChange((value: string) => {
          this.confirmPassword = value;
        });

      // 注册按钮
      Button(this.isLoading ? '注册中...' : '注册')
        .width('80%')
        .height(50)
        .margin({ top: '8%' })
        .backgroundColor('#1698CE')
        .enabled(!this.isLoading)
        .onClick(() => {
          this.register();
        });

      // 返回登录
      Text('已有账号？返回登录')
        .margin({ top: '5%' })
        .textAlign(TextAlign.Center)
        .onClick(() => {
          router.back();
        });
    }
    .backgroundColor('#f5f5f5')
    .width('100%')
    .height('100%')
    .padding({ bottom: 20 })
  }
}