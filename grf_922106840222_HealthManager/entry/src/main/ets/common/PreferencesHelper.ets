import preferences from '@ohos.data.preferences';
const PREFERENCES_NAME = 'user_preferences';
const KEY_USERNAME = 'username';
const KEY_PASSWORD = 'password';
const KEY_REMEMBER_ME = 'remember_me';

interface UserInfo {
  username: string;
  password: string;
  rememberMe: boolean;
}

export class PreferencesHelper {
  private preferences: preferences.Preferences | null = null;
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async initPreferences(): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(this.context, PREFERENCES_NAME);
    } catch (error) {
      console.error(`Failed to init preferences: ${error}`);
    }
  }

  /**
   * 保存用户登录信息到首选项(Preferences)存储中
   * 根据"记住我"选项决定是否保存用户名和密码
   *
   * @param username - 用户的登录名
   * @param password - 用户的登录密码
   * @param rememberMe - 是否记住登录信息的布尔标志
   * @returns Promise<void> - 异步操作完成的Promise
   */
  async saveUserInfo(username: string, password: string, rememberMe: boolean): Promise<void> {
    // 检查preferences对象是否已初始化，如果没有则初始化
    if (!this.preferences) {
      await this.initPreferences();
    }

    try {
      if (rememberMe) {
        // 当"记住我"选项为true时，保存用户名和密码到首选项存储
        await this.preferences?.put(KEY_USERNAME, username);
        await this.preferences?.put(KEY_PASSWORD, password);
      } else {
        // 当"记住我"选项为false时，从首选项存储中删除用户名和密码
        await this.preferences?.delete(KEY_USERNAME);
        await this.preferences?.delete(KEY_PASSWORD);
      }

      // 无论如何都保存"记住我"的设置状态
      await this.preferences?.put(KEY_REMEMBER_ME, rememberMe);

      // 调用flush()将内存中的更改持久化到存储中
      await this.preferences?.flush();
    } catch (error) {
      // 捕获并记录保存过程中可能发生的任何错误
      console.error(`Failed to save user info: ${error}`);
    }
  }

  async getUserInfo(): Promise<UserInfo> {
    if (!this.preferences) {
      await this.initPreferences();
    }
    try {
      const username = await this.preferences?.get(KEY_USERNAME, '');
      const password = await this.preferences?.get(KEY_PASSWORD, '');
      const rememberMe = await this.preferences?.get(KEY_REMEMBER_ME, false);
      const userInfo: UserInfo = {
        username: username as string,
        password: password as string,
        rememberMe: rememberMe as boolean
      };
      return userInfo;
    } catch (error) {
      console.error(`Failed to get user info: ${error}`);
      const defaultUserInfo: UserInfo = {
        username: '',
        password: '',
        rememberMe: false
      };
      return defaultUserInfo;
    }
  }
} 