import relationalStore from '@ohos.data.relationalStore';
import { User } from './UserModel';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'DatabaseHelper';

interface StoreConfig {
  name: string;
  securityLevel: relationalStore.SecurityLevel;
}

const STORE_CONFIG: StoreConfig = {
  name: 'health_management.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

const SQL_CREATE_USER_TABLE = 'CREATE TABLE IF NOT EXISTS user ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'username TEXT NOT NULL, ' +
  'password TEXT NOT NULL)';

interface UserData {
  username: string;
  password: string;
}

export class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  public async initDatabase(): Promise<boolean> {
    try {
      this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
      await this.rdbStore.executeSql(SQL_CREATE_USER_TABLE, []);
      // 在此处插入测试用户，实际应用中可能使用注册页面添加用户
      await this.insertTestUser();
      hilog.info(0x0000, TAG, 'Database initialized successfully');
      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to initialize database: ${error}`);
      return false;
    }
  }

  private async insertTestUser(): Promise<void> {
    try {
      // 检查测试用户是否已存在
      const users = await this.queryUserByUsername('admin');
      if (users.length === 0) {
        // 添加一个测试用户
        const testUser = new User('admin', '123456');
        await this.insertUser(testUser);
        hilog.info(0x0000, TAG, 'Test user inserted successfully');
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert test user: ${error}`);
    }
  }

  public async insertUser(user: User): Promise<boolean> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return false;
    }

    const valuesBucket: relationalStore.ValuesBucket = {
      'username': user.username,
      'password': user.password
    };

    try {
      const rowId = await this.rdbStore.insert('user', valuesBucket);
      hilog.info(0x0000, TAG, `Inserted user with rowId: ${rowId}`);
      return rowId !== undefined && rowId >= 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert user: ${error}`);
      return false;
    }
  }

  public async queryUserByUsername(username: string): Promise<User[]> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('user');
      predicates.equalTo('username', username);

      const resultSet = await this.rdbStore.query(predicates, ['id', 'username', 'password']);

      const users: User[] = [];
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const username = resultSet.getString(resultSet.getColumnIndex('username'));
        const password = resultSet.getString(resultSet.getColumnIndex('password'));
        users.push(new User(username, password, id));
      }

      resultSet.close();
      return users;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query user: ${error}`);
      return [];
    }
  }

  public async validateUser(username: string, password: string): Promise<boolean> {
    try {
      const users = await this.queryUserByUsername(username);
      if (users.length === 0) {
        hilog.info(0x0000, TAG, 'User not found');
        return false;
      }

      const isValid = users[0].password === password;
      hilog.info(0x0000, TAG, `User validation ${isValid ? 'successful' : 'failed'}`);
      return isValid;
    } catch (error) {
      hilog.error(0x0000, TAG, `Error validating user: ${error}`);
      return false;
    }
  }

  public closeDatabase() {
    if (this.rdbStore) {
      this.rdbStore.close();
      this.rdbStore = null;
      hilog.info(0x0000, TAG, 'Database closed');
    }
  }
}