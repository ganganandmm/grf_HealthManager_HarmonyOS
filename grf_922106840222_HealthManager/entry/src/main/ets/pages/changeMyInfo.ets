import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import promptAction from '@ohos.promptAction';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { User } from '../common/UserModel';
import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
const TAG: string = 'changeMyInfo';

interface RouteParams {
  username?: string;
  userId?: number;
  isEdit?: boolean;
}

@Entry
@Component
struct changeMyInfo {
  @State userId: number = -1;                // 用户ID，默认为-1表示无效ID
  @State username: string = '';              // 用户名
  @State age: string = '';                   // 年龄
  @State gender: string = '未设置';           // 性别，默认为"未设置"
  @State phone: string = '';                 // 电话号码
  @State email: string = '';                 // 电子邮箱
  @State myheight: string = '';              // 身高，使用myheight而不是height避免与系统属性冲突
  @State weight: string = '';                // 体重
  @State emergencyContact: string = '';      // 紧急联系人姓名
  @State emergencyPhone: string = '';        // 紧急联系人电话
  @State medicalHistory: string = '';        // 医疗病史
  @State isEdit: boolean = false;            // 是否处于编辑模式
  @State bmi: number = 0;                    // BMI指数，体重(kg)除以身高(m)的平方
  @State avatarPath: string = '';            // 头像文件路径
  @State defaultAvatar: Resource = $r('app.media.avater_1');  // 默认头像资源引用

  // 创建数据库帮助类实例
  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));
  // 获取应用上下文
  private context = getContext(this);

  // 组件显示前的生命周期钩子
  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    if (params) {
      // 如果有参数，则设置对应的状态变量
      if (params.username) {
        this.username = params.username;
      }
      if (params.userId) {
        this.userId = params.userId;
      }
      if (params.isEdit !== undefined) {
        this.isEdit = params.isEdit;
      }
    }

    // 初始化用户数据
    this.initData();
  }

  // 初始化用户数据的异步方法
  async initData() {
    try {
      // 初始化数据库
      await this.dbHelper.initDatabase();

      // 记录日志，表示正在为指定用户ID初始化数据
      hilog.info(0x0000, TAG, `Initializing data for userId: ${this.userId}`);

      // 如果userId有效，则查询用户信息
      if (this.userId > 0) {
        // 通过用户ID获取用户信息
        const userInfo = await this.dbHelper.getUserById(this.userId);
        // 记录日志，显示获取到的用户信息
        hilog.info(0x0000, TAG, `Retrieved user info: ${userInfo ? JSON.stringify(userInfo) : 'null'}`);

        // 如果获取到用户信息，则更新组件状态
        if (userInfo) {
          // 将获取到的用户信息赋值给组件状态变量，使用空值合并运算符处理可能为null的字段
          this.username = userInfo.username || this.username;
          this.age = userInfo.age?.toString() || '';
          this.gender = userInfo.gender || '未设置';
          this.phone = userInfo.phone || '';
          this.email = userInfo.email || '';
          this.myheight = userInfo.height?.toString() || '';
          this.weight = userInfo.weight?.toString() || '';
          this.avatarPath = userInfo.avatarPath || '';

          // 如果身高和体重都有值，则计算BMI
          if (userInfo.height && userInfo.weight) {
            // 将身高从厘米转换为米
            const heightInMeters = userInfo.height / 100;
            // 计算BMI = 体重(kg) / 身高(m)²
            this.bmi = userInfo.weight / (heightInMeters * heightInMeters);
          }

          // 记录日志，表示用户信息加载成功
          hilog.info(0x0000, TAG, 'User info loaded successfully');
        } else {
          // 如果未找到用户信息，则记录警告日志并显示提示
          hilog.warn(0x0000, TAG, `No user found with id: ${this.userId}`);
          promptAction.showToast({ message: '无法获取用户信息', duration: 2000 });
        }
      } else {
        // 如果userId无效，则记录错误日志并显示提示
        hilog.error(0x0000, TAG, 'Invalid userId');
        promptAction.showToast({ message: '用户ID无效', duration: 2000 });
      }
    } catch (error) {
      // 捕获并处理异常，记录错误日志并显示提示
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to initialize data: ${errorMessage}`);
      promptAction.showToast({ message: '加载用户信息失败', duration: 2000 });
    }
  }

  // 选择头像的异步方法
  async selectAvatar() {
    try {
      // 创建照片选择器实例
      const photoPicker = new picker.PhotoViewPicker();
      // 创建照片选择选项
      const photoSelectOptions = new picker.PhotoSelectOptions();
      // 设置MIME类型为图片
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      // 设置最大选择数量为1
      photoSelectOptions.maxSelectNumber = 1;

      // 调用选择方法，等待用户选择图片
      const photoSelectResult = await photoPicker.select(photoSelectOptions);
      // 如果有选择结果且选择了照片
      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        // 获取选择的照片URI
        const photoUri = photoSelectResult.photoUris[0];
        // 设置头像保存目录
        const appDir = this.context.filesDir + '/avatars/';
        try {
          // 尝试获取目录状态，检查目录是否存在
          const stat = await fs.stat(appDir);
        } catch (err) {
          // 如果目录不存在，则创建目录
          if (err.code === 'ENOENT') {
            await fs.mkdir(appDir);
          } else {
            // 如果是其他错误，则暂不处理
          }
        }
        // 生成头像文件名，使用用户ID和时间戳确保唯一性
        const avatarFileName = `avatar_${this.userId}_${Date.now()}.jpg`;
        // 组合完整的头像文件路径
        const avatarFilePath = appDir + avatarFileName;

        // 复制选择的照片到应用目录
        await fs.copyFile(photoUri, avatarFilePath);

        // 更新头像路径状态变量
        this.avatarPath = avatarFilePath;
        // 记录日志，表示头像选择成功
        hilog.info(0x0000, TAG, `Avatar selected and copied to: ${this.avatarPath}`);
      }
    } catch (error) {
      // 捕获并处理异常，记录错误日志并显示提示
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to select avatar: ${errorMessage}`);
      promptAction.showToast({ message: '选择头像失败', duration: 2000 });
    }
  }

  // 保存用户信息的异步方法
  async saveUserInfo() {
    // 检查userId是否有效
    if (this.userId < 0) {
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }

    try {
      // 获取当前用户信息，以保持原有的用户名和密码
      const currentUser = await this.dbHelper.getUserById(this.userId);
      // 如果无法获取当前用户信息，则显示提示并返回
      if (!currentUser) {
        promptAction.showToast({ message: '无法获取用户信息' });
        return;
      }

      // 验证年龄输入，必须是数字
      if (this.age.trim() && isNaN(parseInt(this.age))) {
        promptAction.showToast({ message: '年龄必须是数字' });
        return;
      }

      // 验证身高输入，必须是数字
      if (this.myheight.trim() && isNaN(parseFloat(this.myheight))) {
        promptAction.showToast({ message: '身高必须是数字' });
        return;
      }

      // 验证体重输入，必须是数字
      if (this.weight.trim() && isNaN(parseFloat(this.weight))) {
        promptAction.showToast({ message: '体重必须是数字' });
        return;
      }

      // 创建用户对象，用于更新用户信息
      const user = new User(
        currentUser.username,  // 保持原有用户名
        currentUser.password,  // 保持原有密码
        this.userId,           // 用户ID
        this.age.trim() ? parseInt(this.age) : undefined,  // 年龄，如果有值则转换为数字
        this.gender !== '未设置' ? this.gender : undefined,  // 性别，如果不是"未设置"则使用
        this.phone.trim() || undefined,  // 电话号码，如果为空则使用undefined
        this.email.trim() || undefined,  // 电子邮箱，如果为空则使用undefined
        this.myheight.trim() ? parseFloat(this.myheight) : undefined,  // 身高，如果有值则转换为数字
        this.weight.trim() ? parseFloat(this.weight) : undefined,  // 体重，如果有值则转换为数字
        this.avatarPath || undefined  // 头像路径，如果为空则使用undefined
      );

      // 记录日志，显示尝试保存的用户信息
      hilog.info(0x0000, TAG, `Attempting to save user info: ${JSON.stringify({
        id: user.id,
        age: user.age,
        gender: user.gender,
        phone: user.phone,
        email: user.email,
        height: user.height,
        weight: user.weight,
        avatarPath: user.avatarPath
      })}`);

      // 调用数据库帮助类方法更新用户信息
      const success = await this.dbHelper.updateUserInfo(user);
      // 根据结果显示提示并处理后续操作
      if (success) {
        promptAction.showToast({ message: '保存成功' });
        // 保存成功后返回上一页
        router.back();
      } else {
        promptAction.showToast({ message: '保存失败' });
      }
    } catch (error) {
      // 捕获并处理异常，记录错误日志并显示提示
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to save user info: ${errorMessage}`);
      promptAction.showToast({ message: '保存失败' });
    }
  }

  // 构建UI组件
  build() {
    // 创建列布局作为根容器
    Column() {
      // 标题栏
      Row() {
        // 返回按钮
        Image($r('app.media.backup'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            // 点击返回按钮时返回上一页
            router.back();
          })

        // 页面标题
        Text('个人信息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      // 滚动视图，用于显示内容
      Scroll() {
        // 主内容区域
        Column() {
          // 头像部分
          Column() {
            // 头像标题
            Text('头像')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })
              .alignSelf(ItemAlign.Start)

            // 头像显示区域，使用Stack布局层叠效果
            Stack({ alignContent: Alignment.Center }) {
              // 如果有头像路径，则显示用户头像
              if (this.avatarPath) {
                Image(this.avatarPath)
                  .width(100)
                  .height(100)
                  .borderRadius(50)  // 设置圆形边框
                  .objectFit(ImageFit.Cover)  // 设置图片填充模式
              } else {
                // 如果没有头像路径，则显示默认头像
                Image(this.defaultAvatar)
                  .width(100)
                  .height(100)
                  .borderRadius(50)
              }

              // 如果处于编辑模式，则显示蒙层和编辑图标
              if (this.isEdit) {
                Column() {
                  Image($r('app.media.change_avater'))
                    .width(30)
                    .height(30)
                }
                .width(100)
                .height(100)
                .borderRadius(50)
                .backgroundColor('rgba(0, 0, 0, 0.5)')  // 半透明黑色背景
                .justifyContent(FlexAlign.Center)
              }
            }
            .width(100)
            .height(100)
            .margin({ bottom: 16 })
            .onClick(() => {
              // 点击头像区域时，如果处于编辑模式，则选择头像
              if (this.isEdit) {
                this.selectAvatar();
              }
            })

            // 如果处于编辑模式，则显示提示文本
            if (this.isEdit) {
              Text('点击更换头像')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 10 })
            }
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 20 })
          .alignItems(HorizontalAlign.Center)

          // 基本信息部分
          Column() {
            // 基本信息标题
            Text('基本信息')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })
              .alignSelf(ItemAlign.Start)

            // 用户名（不可编辑）
            Row() {
              Text('用户名')
                .fontSize(16)
                .width('30%')
              Text(this.username)
                .fontSize(16)
                .width('70%')
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })

            // 年龄
            Row() {
              Text('年龄')
                .fontSize(16)
                .width('30%')
              // 根据是否编辑模式显示不同的组件
              if (this.isEdit) {
                // 编辑模式下显示输入框
                TextInput({ text: this.age, placeholder: '请输入年龄' })
                  .type(InputType.Number)  // 设置输入类型为数字
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    // 当输入值变化时更新状态变量
                    this.age = value;
                  })
              } else {
                // 非编辑模式下显示文本
                Text(this.age || '未设置')
                  .fontSize(16)
                  .width('70%')
                  .textAlign(TextAlign.End)
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })

            // 性别
            Row() {
              Text('性别')
                .fontSize(16)
                .width('30%')
              // 根据是否编辑模式显示不同的组件
              if (this.isEdit) {
                // 编辑模式下显示选择器
                Select([
                  { value: '男' },
                  { value: '女' },
                  { value: '未设置' }
                ])
                  .selected(this.gender === '男' ? 0 : this.gender === '女' ? 1 : 2)  // 设置默认选择项
                  .value(this.gender)
                  .font({ size: 16, weight: 500 })
                  .width('70%')
                  .onSelect((index: number) => {
                    // 当选择项变化时更新状态变量
                    this.gender = index === 0 ? '男' : index === 1 ? '女' : '未设置';
                  })
              } else {
                // 非编辑模式下显示文本
                Text(this.gender)
                  .fontSize(16)
                  .width('70%')
                  .textAlign(TextAlign.End)
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 20 })

          // 联系方式部分
          Column() {
            // 联系方式标题
            Text('联系方式')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })
              .alignSelf(ItemAlign.Start)

            // 电话
            Row() {
              Text('电话')
                .fontSize(16)
                .width('30%')
              // 根据是否编辑模式显示不同的组件
              if (this.isEdit) {
                // 编辑模式下显示输入框
                TextInput({ text: this.phone, placeholder: '请输入电话号码' })
                  .type(InputType.PhoneNumber)  // 设置输入类型为电话号码
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    // 当输入值变化时更新状态变量
                    this.phone = value;
                  })
              } else {
                // 非编辑模式下显示文本
                Text(this.phone || '未设置')
                  .fontSize(16)
                  .width('70%')
                  .textAlign(TextAlign.End)
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })

            // 邮箱
            Row() {
              Text('邮箱')
                .fontSize(16)
                .width('30%')
              // 根据是否编辑模式显示不同的组件
              if (this.isEdit) {
                // 编辑模式下显示输入框
                TextInput({ text: this.email, placeholder: '请输入邮箱' })
                  .type(InputType.Email)  // 设置输入类型为邮箱
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    // 当输入值变化时更新状态变量
                    this.email = value;
                  })
              } else {
                // 非编辑模式下显示文本
                Text(this.email || '未设置')
                  .fontSize(16)
                  .width('70%')
                  .textAlign(TextAlign.End)
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 20 })

          // 身体信息部分
          Column() {
            // 身体信息标题
            Text('身体信息')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })
              .alignSelf(ItemAlign.Start)

            // 身高
            Row() {
              Text('身高(cm)')
                .fontSize(16)
                .width('30%')
              // 根据是否编辑模式显示不同的组件
              if (this.isEdit) {
                // 编辑模式下显示输入框
                TextInput({ text: this.myheight, placeholder: '请输入身高' })
                  .type(InputType.Number)  // 设置输入类型为数字
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    // 当输入值变化时更新状态变量
                    this.myheight = value;
                    // 当身高变化时，如果体重也有值，则更新BMI
                    if (this.myheight && this.weight) {
                      const height = parseFloat(this.myheight) / 100;  // 将身高从厘米转换为米
                      const weight = parseFloat(this.weight);
                      if (!isNaN(height) && !isNaN(weight) && height > 0) {
                        // 计算BMI = 体重(kg) / 身高(m)²
                        this.bmi = weight / (height * height);
                      }
                    }
                  })
              } else {
                // 非编辑模式下显示文本
                Text(this.myheight ? `${this.myheight} cm` : '未设置')
                  .fontSize(16)
                  .width('70%')
                  .textAlign(TextAlign.End)
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })

            // 体重
            Row() {
              Text('体重(kg)')
                .fontSize(16)
                .width('30%')
              // 根据是否编辑模式显示不同的组件
              if (this.isEdit) {
                // 编辑模式下显示输入框
                TextInput({ text: this.weight, placeholder: '请输入体重' })
                  .type(InputType.Number)  // 设置输入类型为数字
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    // 当输入值变化时更新状态变量
                    this.weight = value;
                    // 当体重变化时，如果身高也有值，则更新BMI
                    if (this.myheight && this.weight) {
                      const height = parseFloat(this.myheight) / 100;  // 将身高从厘米转换为米
                      const weight = parseFloat(this.weight);
                      if (!isNaN(height) && !isNaN(weight) && height > 0) {
                        // 计算BMI = 体重(kg) / 身高(m)²
                        this.bmi = weight / (height * height);
                      }
                    }
                  })
              } else {
                // 非编辑模式下显示文本
                Text(this.weight ? `${this.weight} kg` : '未设置')
                  .fontSize(16)
                  .width('70%')
                  .textAlign(TextAlign.End)
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })

            // BMI
            Row() {
              Text('BMI')
                .fontSize(16)
                .width('30%')
              // 显示BMI值，如果有效则显示，否则显示"未计算"
              Text(this.bmi > 0 ? this.bmi.toFixed(1) : '未计算')
                .fontSize(16)
                .width('70%')
                .textAlign(TextAlign.End)
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .margin({ bottom: 8 })
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 20 })

          // 操作按钮
          // 根据是否编辑模式显示不同的按钮
          if (this.isEdit) {
            // 编辑模式下显示保存按钮
            Button('保存')
              .width('90%')
              .height(50)
              .backgroundColor('#27AE60')  // 绿色
              .onClick(() => {
                // 点击保存按钮时调用保存方法
                this.saveUserInfo();
              })
          } else {
            // 非编辑模式下显示编辑信息按钮
            Button('编辑信息')
              .width('90%')
              .height(50)
              .backgroundColor('#3498DB')  // 蓝色
              .onClick(() => {
                // 点击编辑信息按钮时切换到编辑模式
                this.isEdit = true;
              })
          }
        }
        .width('100%')
        .padding({ top: 20, bottom: 30 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('calc(100% - 56vp)')  // 减去标题栏高度
      .scrollBar(BarState.Off)  // 隐藏滚动条
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')  // 设置背景色
  }
}