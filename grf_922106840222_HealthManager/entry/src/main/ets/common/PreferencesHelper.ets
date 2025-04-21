import preferences from '@ohos.data.preferences';

const TAG: string = 'PreferencesHelper';
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

  async saveUserInfo(username: string, password: string, rememberMe: boolean): Promise<void> {
    if (!this.preferences) {
      await this.initPreferences();
    }
    try {
      if (rememberMe) {
        await this.preferences?.put(KEY_USERNAME, username);
        await this.preferences?.put(KEY_PASSWORD, password);
      } else {
        await this.preferences?.delete(KEY_USERNAME);
        await this.preferences?.delete(KEY_PASSWORD);
      }
      await this.preferences?.put(KEY_REMEMBER_ME, rememberMe);
      await this.preferences?.flush();
    } catch (error) {
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