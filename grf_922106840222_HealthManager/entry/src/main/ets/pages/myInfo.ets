import router from '@ohos.router';
import { hilog } from '@kit.PerformanceAnalysisKit';
import promptAction from '@ohos.promptAction';
import { DatabaseHelper } from '../common/DatabaseHelper';
import { User } from '../common/UserModel';

const TAG: string = 'MyInfo';

interface RouteParams {
  username?: string;
  userId?: number;
  isEdit?: boolean;
}

@Entry
@Component
struct MyInfo {
  @State userId: number = -1;
  @State username: string = '';
  @State age: string = '';
  @State gender: string = '未设置';
  @State phone: string = '';
  @State email: string = '';
  @State myheight: string = '';
  @State weight: string = '';
  @State emergencyContact: string = '';
  @State emergencyPhone: string = '';
  @State medicalHistory: string = '';
  @State isEdit: boolean = false;
  private dbHelper: DatabaseHelper = new DatabaseHelper(getContext(this));

  aboutToAppear() {
    const params = router.getParams() as RouteParams;
    if (params) {
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

    // 初始化数据库并加载用户数据
    this.initData();
  }

  async initData() {
    try {
      await this.dbHelper.initDatabase();

      hilog.info(0x0000, TAG, `Initializing data for userId: ${this.userId}`);

      if (this.userId > 0) {
        const userInfo = await this.dbHelper.getUserById(this.userId);
        hilog.info(0x0000, TAG, `Retrieved user info: ${userInfo ? JSON.stringify(userInfo) : 'null'}`);

        if (userInfo) {
          this.username = userInfo.username || this.username;
          this.age = userInfo.age?.toString() || '';
          this.gender = userInfo.gender || '未设置';
          this.phone = userInfo.phone || '';
          this.email = userInfo.email || '';
          this.myheight = userInfo.height?.toString() || '';
          this.weight = userInfo.weight?.toString() || '';
          this.emergencyContact = userInfo.emergencyContact || '';
          this.emergencyPhone = userInfo.emergencyPhone || '';
          this.medicalHistory = userInfo.medicalHistory || '';

          hilog.info(0x0000, TAG, 'User info loaded successfully');
        } else {
          hilog.warn(0x0000, TAG, `No user found with id: ${this.userId}`);
          promptAction.showToast({ message: '无法获取用户信息', duration: 2000 });
        }
      } else {
        hilog.error(0x0000, TAG, 'Invalid userId');
        promptAction.showToast({ message: '用户ID无效', duration: 2000 });
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to initialize data: ${errorMessage}`);
      promptAction.showToast({ message: '加载用户信息失败', duration: 2000 });
    }
  }

  async saveUserInfo() {
    if (this.userId < 0) {
      promptAction.showToast({ message: '用户ID无效' });
      return;
    }

    try {
      // 获取当前用户信息，保持原有的 username 和 password
      const currentUser = await this.dbHelper.getUserById(this.userId);
      if (!currentUser) {
        promptAction.showToast({ message: '无法获取用户信息' });
        return;
      }

      // 创建更新对象，只包含需要更新的字段
      const user = new User(
        currentUser.username, // 保持原有用户名
        currentUser.password, // 保持原有密码
        this.userId,
        this.age.trim() ? parseInt(this.age) : undefined,
        this.gender !== '未设置' ? this.gender : undefined,
        this.phone.trim() || undefined,
        this.email.trim() || undefined,
        this.myheight.trim() ? parseFloat(this.myheight) : undefined,
        this.weight.trim() ? parseFloat(this.weight) : undefined,
        this.emergencyContact.trim() || undefined,
        this.emergencyPhone.trim() || undefined,
        this.medicalHistory.trim() || undefined,
        undefined // avatarPath
      );

      // 验证数值输入
      if (this.age.trim() && isNaN(parseInt(this.age))) {
        promptAction.showToast({ message: '年龄必须是数字' });
        return;
      }

      if (this.myheight.trim() && isNaN(parseFloat(this.myheight))) {
        promptAction.showToast({ message: '身高必须是数字' });
        return;
      }

      if (this.weight.trim() && isNaN(parseFloat(this.weight))) {
        promptAction.showToast({ message: '体重必须是数字' });
        return;
      }

      hilog.info(0x0000, TAG, `Attempting to save user info: ${JSON.stringify({
        id: user.id,
        age: user.age,
        gender: user.gender,
        phone: user.phone,
        email: user.email,
        height: user.height,
        weight: user.weight
      })}`);

      const success = await this.dbHelper.updateUserInfo(user);
      if (success) {
        promptAction.showToast({ message: '保存成功' });
        router.back();
      } else {
        promptAction.showToast({ message: '保存失败' });
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      hilog.error(0x0000, TAG, `Failed to save user info: ${errorMessage}`);
      promptAction.showToast({ message: '保存失败' });
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Image($r('app.media.backup'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            router.back();
          })

        Text('个人信息')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      Scroll() {
        Column() {
          // 基本信息
          Column() {
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
              if (this.isEdit) {
                TextInput({ text: this.age, placeholder: '请输入年龄' })
                  .type(InputType.Number)
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    this.age = value;
                  })
              } else {
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
              if (this.isEdit) {
                Select([
                  { value: '男' },
                  { value: '女' },
                  { value: '未设置' }
                ])
                  .selected(this.gender === '男' ? 0 : this.gender === '女' ? 1 : 2)
                  .value(this.gender)
                  .font({ size: 16, weight: 500 })
                  .width('70%')
                  .onSelect((index: number) => {
                    this.gender = index === 0 ? '男' : index === 1 ? '女' : '未设置';
                  })
              } else {
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

          // 联系方式
          Column() {
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
              if (this.isEdit) {
                TextInput({ text: this.phone, placeholder: '请输入电话号码' })
                  .type(InputType.PhoneNumber)
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    this.phone = value;
                  })
              } else {
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
              if (this.isEdit) {
                TextInput({ text: this.email, placeholder: '请输入邮箱' })
                  .type(InputType.Email)
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    this.email = value;
                  })
              } else {
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

          // 身体信息
          Column() {
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
              if (this.isEdit) {
                TextInput({ text: this.myheight, placeholder: '请输入身高' })
                  .type(InputType.Number)
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    this.myheight = value;
                  })
              } else {
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
              if (this.isEdit) {
                TextInput({ text: this.weight, placeholder: '请输入体重' })
                  .type(InputType.Number)
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    this.weight = value;
                  })
              } else {
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
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 20 })

          // 紧急联系人
          Column() {
            Text('紧急联系人')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })
              .alignSelf(ItemAlign.Start)

            // 联系人姓名
            Row() {
              Text('联系人')
                .fontSize(16)
                .width('30%')
              if (this.isEdit) {
                TextInput({ text: this.emergencyContact, placeholder: '请输入联系人姓名' })
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    this.emergencyContact = value;
                  })
              } else {
                Text(this.emergencyContact || '未设置')
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

            // 联系人电话
            Row() {
              Text('联系电话')
                .fontSize(16)
                .width('30%')
              if (this.isEdit) {
                TextInput({ text: this.emergencyPhone, placeholder: '请输入联系人电话' })
                  .type(InputType.PhoneNumber)
                  .width('70%')
                  .textAlign(TextAlign.End)
                  .onChange((value: string) => {
                    this.emergencyPhone = value;
                  })
              } else {
                Text(this.emergencyPhone || '未设置')
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

          // 医疗信息
          Column() {
            Text('医疗信息')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })
              .alignSelf(ItemAlign.Start)

            // 病史
            Column() {
              Text('病史')
                .fontSize(16)
                .margin({ bottom: 8 })
                .alignSelf(ItemAlign.Start)

              if (this.isEdit) {
                TextArea({ text: this.medicalHistory, placeholder: '请输入病史信息' })
                  .width('100%')
                  .height(100)
                  .onChange((value: string) => {
                    this.medicalHistory = value;
                  })
              } else {
                Text(this.medicalHistory || '未设置')
                  .fontSize(16)
                  .width('100%')
                  .padding(10)
                  .backgroundColor('#ffffff')
                  .borderRadius(8)
              }
            }
            .width('100%')
          }
          .width('90%')
          .padding(15)
          .borderRadius(8)
          .backgroundColor('#f7f7f7')
          .margin({ bottom: 30 })

          // 操作按钮
          if (this.isEdit) {
            Button('保存')
              .width('90%')
              .height(50)
              .backgroundColor('#27AE60')
              .onClick(() => {
                this.saveUserInfo();
              })
          } else {
            Button('编辑信息')
              .width('90%')
              .height(50)
              .backgroundColor('#3498DB')
              .onClick(() => {
                this.isEdit = true;
              })
          }
        }
        .width('100%')
        .padding({ top: 20, bottom: 30 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('calc(100% - 56vp)')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}