import relationalStore from '@ohos.data.relationalStore';
import { User } from './UserModel';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from './HealthDataModel';

const TAG: string = 'DatabaseHelper';

interface StoreConfig {
  name: string;
  securityLevel: relationalStore.SecurityLevel;
}

const STORE_CONFIG: StoreConfig = {
  name: 'HealthDB.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

// 更新SQL_CREATE_USER_TABLE语句，添加新的字段
const SQL_CREATE_USER_TABLE = 'CREATE TABLE IF NOT EXISTS user ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'username TEXT NOT NULL, ' +
  'password TEXT NOT NULL, ' +
  'age INTEGER, ' +
  'gender TEXT, ' +
  'phone TEXT, ' +
  'email TEXT, ' +
  'height REAL, ' +
  'weight REAL, ' +
  'emergency_contact TEXT, ' +
  'emergency_phone TEXT, ' +
  'medical_history TEXT, ' +
  'avatar_path TEXT)';

const SQL_CREATE_STEP_TABLE = 'CREATE TABLE IF NOT EXISTS step_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'date TEXT NOT NULL, ' +
  'steps INTEGER NOT NULL, ' +
  'FOREIGN KEY (user_id) REFERENCES user(id))';

const SQL_CREATE_HEART_RATE_TABLE = 'CREATE TABLE IF NOT EXISTS heart_rate_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'date TEXT NOT NULL, ' +
  'time TEXT NOT NULL, ' +
  'rate INTEGER NOT NULL, ' +
  'FOREIGN KEY (user_id) REFERENCES user(id))';

const SQL_CREATE_SLEEP_TABLE = 'CREATE TABLE IF NOT EXISTS sleep_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'date TEXT NOT NULL, ' +
  'duration INTEGER NOT NULL, ' +
  'FOREIGN KEY (user_id) REFERENCES user(id))';

const SQL_CREATE_WATER_TABLE = 'CREATE TABLE IF NOT EXISTS water_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'date TEXT NOT NULL, ' +
  'time TEXT NOT NULL, ' +
  'amount INTEGER NOT NULL, ' +
  'FOREIGN KEY (user_id) REFERENCES user(id))';

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
      await this.rdbStore.executeSql(SQL_CREATE_STEP_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_HEART_RATE_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_SLEEP_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_WATER_TABLE, []);

      // 插入测试用户
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
        const userId = await this.insertUser(testUser);
        if (userId > 0) {
          // 为测试用户添加一些测试健康数据
          await this.insertTestHealthData(userId);
          hilog.info(0x0000, TAG, 'Test user and health data inserted successfully');
        }
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert test user: ${error}`);
    }
  }

  private async insertTestHealthData(userId: number): Promise<void> {
    try {
      const today = new Date();
      const dateStr = today.toISOString().split('T')[0];

      // 插入步数记录
      const stepRecord = new StepRecord(userId, dateStr, 500);
      await this.insertStepRecord(stepRecord);

      // 插入心率记录
      const heartRateRecord = new HeartRateRecord(userId, dateStr, '08:00', 72);
      await this.insertHeartRateRecord(heartRateRecord);

      // 插入睡眠记录
      const sleepRecord = new SleepRecord(userId, dateStr, 9.8 * 60); // 7.5小时转换为分钟
      await this.insertSleepRecord(sleepRecord);

      // 插入饮水记录
      const waterRecord = new WaterRecord(userId, dateStr, '07:30', 4000); // 300ml
      await this.insertWaterRecord(waterRecord);
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert test health data: ${error}`);
    }
  }

  public async insertUser(user: User): Promise<number> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return -1;
    }

    const valuesBucket: relationalStore.ValuesBucket = {
      'username': user.username,
      'password': user.password
    };

    try {
      const rowId = await this.rdbStore.insert('user', valuesBucket);
      hilog.info(0x0000, TAG, `Inserted user with rowId: ${rowId}`);
      return rowId;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert user: ${error}`);
      return -1;
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

  public async validateUser(username: string, password: string): Promise<User | null> {
    try {
      const users = await this.queryUserByUsername(username);
      if (users.length === 0) {
        hilog.info(0x0000, TAG, 'User not found');
        return null;
      }

      const user = users[0];
      const isValid = user.password === password;
      hilog.info(0x0000, TAG, `User validation ${isValid ? 'successful' : 'failed'}`);
      return isValid ? user : null;
    } catch (error) {
      hilog.error(0x0000, TAG, `Error validating user: ${error}`);
      return null;
    }
  }

  // 步数记录相关方法
  public async insertStepRecord(record: StepRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'steps': record.steps
    };

    try {
      const rowId = await this.rdbStore.insert('step_record', valuesBucket);
      return rowId >= 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert step record: ${error}`);
      return false;
    }
  }

  public async getStepRecords(userId: number, date?: string): Promise<StepRecord[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('step_record');
      predicates.equalTo('user_id', userId);
      if (date) {
        predicates.equalTo('date', date);
      }

      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'steps']);
      const records: StepRecord[] = [];

      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const steps = resultSet.getLong(resultSet.getColumnIndex('steps'));

        records.push(new StepRecord(userId, date, steps, id));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query step records: ${error}`);
      return [];
    }
  }

  // 心率记录相关方法
  public async insertHeartRateRecord(record: HeartRateRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'time': record.time,
      'rate': record.rate
    };

    try {
      const rowId = await this.rdbStore.insert('heart_rate_record', valuesBucket);
      return rowId >= 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert heart rate record: ${error}`);
      return false;
    }
  }

  public async getHeartRateRecords(userId: number, date?: string): Promise<HeartRateRecord[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('heart_rate_record');
      predicates.equalTo('user_id', userId);
      if (date) {
        predicates.equalTo('date', date);
      }

      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'time', 'rate']);
      const records: HeartRateRecord[] = [];

      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const time = resultSet.getString(resultSet.getColumnIndex('time'));
        const rate = resultSet.getLong(resultSet.getColumnIndex('rate'));

        records.push(new HeartRateRecord(userId, date, time, rate, id));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query heart rate records: ${error}`);
      return [];
    }
  }

  // 睡眠记录相关方法
  public async insertSleepRecord(record: SleepRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'duration': record.duration
    };

    try {
      const rowId = await this.rdbStore.insert('sleep_record', valuesBucket);
      return rowId >= 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert sleep record: ${error}`);
      return false;
    }
  }

  public async getSleepRecords(userId: number, date?: string): Promise<SleepRecord[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('sleep_record');
      predicates.equalTo('user_id', userId);
      if (date) {
        predicates.equalTo('date', date);
      }

      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'duration']);
      const records: SleepRecord[] = [];

      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const duration = resultSet.getLong(resultSet.getColumnIndex('duration'));

        records.push(new SleepRecord(userId, date, duration, id));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query sleep records: ${error}`);
      return [];
    }
  }

  // 饮水记录相关方法
  public async insertWaterRecord(record: WaterRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'time': record.time,
      'amount': record.amount
    };

    try {
      const rowId = await this.rdbStore.insert('water_record', valuesBucket);
      return rowId >= 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert water record: ${error}`);
      return false;
    }
  }

  public async getWaterRecords(userId: number, date?: string): Promise<WaterRecord[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates('water_record');
      predicates.equalTo('user_id', userId);
      if (date) {
        predicates.equalTo('date', date);
      }

      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'time', 'amount']);
      const records: WaterRecord[] = [];

      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const time = resultSet.getString(resultSet.getColumnIndex('time'));
        const amount = resultSet.getLong(resultSet.getColumnIndex('amount'));

        records.push(new WaterRecord(userId, date, time, amount, id));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query water records: ${error}`);
      return [];
    }
  }

  public closeDatabase() {
    if (this.rdbStore) {
      this.rdbStore.close();
      this.rdbStore = null;
      hilog.info(0x0000, TAG, 'Database closed');
    }
  }
  // Add these methods to DatabaseHelper class

  // Check if the database has been updated since the last check
  public async checkDatabaseUpdates(userId: number, lastCheckTime: number): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    try {
      // Check for any recent health data records
      const stepsUpdated = await this.hasRecentUpdates('step_record', userId, lastCheckTime);
      const heartRateUpdated = await this.hasRecentUpdates('heart_rate_record', userId, lastCheckTime);
      const sleepUpdated = await this.hasRecentUpdates('sleep_record', userId, lastCheckTime);
      const waterUpdated = await this.hasRecentUpdates('water_record', userId, lastCheckTime);

      return stepsUpdated || heartRateUpdated || sleepUpdated || waterUpdated;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to check for database updates: ${error}`);
      return false;
    }
  }

  // Helper method to check if specific table has recent updates
  private async hasRecentUpdates(tableName: string, userId: number, lastCheckTime: number): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    try {
      // In a real app, you would have a lastUpdated timestamp column in each table
      // For now, we'll consider any records for today as potentially new updates
      const today = new Date().toISOString().split('T')[0];

      const predicates = new relationalStore.RdbPredicates(tableName);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('date', today);

      const resultSet = await this.rdbStore.query(predicates, ['id']);
      const hasUpdates = resultSet.rowCount > 0;
      resultSet.close();

      return hasUpdates;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to check for updates in ${tableName}: ${error}`);
      return false;
    }
  }

  // Add method to update health data
  public async updateStepRecord(record: StepRecord): Promise<boolean> {
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        'steps': record.steps
      };

      const predicates = new relationalStore.RdbPredicates('step_record');
      predicates.equalTo('id', record.id);

      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update step record: ${error}`);
      return false;
    }
  }

  // Similar update methods for other health data types
  public async updateHeartRateRecord(record: HeartRateRecord): Promise<boolean> {
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        'rate': record.rate
      };

      const predicates = new relationalStore.RdbPredicates('heart_rate_record');
      predicates.equalTo('id', record.id);

      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update heart rate record: ${error}`);
      return false;
    }
  }
  // 在 DatabaseHelper 类中添加以下方法

  // 在 DatabaseHelper 类中添加以下方法

  public async updateUserInfo(user: User): Promise<boolean> {
    if (!this.rdbStore || !user.id) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized or user id is invalid');
      return false;
    }

    // 构建更新的值，只更新非密码字段，并处理undefined值
    const valuesBucket: relationalStore.ValuesBucket = {};

    // 不更新 username 和 password，这些字段不应该在个人信息编辑中修改

    // 对于数值类型的字段，确保传入正确的类型或null
    if (user.age !== undefined) {
      valuesBucket.age = user.age;
    } else {
      valuesBucket.age = null;
    }

    if (user.gender !== undefined) {
      valuesBucket.gender = user.gender;
    } else {
      valuesBucket.gender = null;
    }

    if (user.phone !== undefined) {
      valuesBucket.phone = user.phone;
    } else {
      valuesBucket.phone = null;
    }

    if (user.email !== undefined) {
      valuesBucket.email = user.email;
    } else {
      valuesBucket.email = null;
    }

    if (user.height !== undefined) {
      valuesBucket.height = user.height;
    } else {
      valuesBucket.height = null;
    }

    if (user.weight !== undefined) {
      valuesBucket.weight = user.weight;
    } else {
      valuesBucket.weight = null;
    }

    if (user.emergencyContact !== undefined) {
      valuesBucket.emergency_contact = user.emergencyContact;
    } else {
      valuesBucket.emergency_contact = null;
    }

    if (user.emergencyPhone !== undefined) {
      valuesBucket.emergency_phone = user.emergencyPhone;
    } else {
      valuesBucket.emergency_phone = null;
    }

    if (user.medicalHistory !== undefined) {
      valuesBucket.medical_history = user.medicalHistory;
    } else {
      valuesBucket.medical_history = null;
    }

    if (user.avatarPath !== undefined) {
      valuesBucket.avatar_path = user.avatarPath;
    } else {
      valuesBucket.avatar_path = null;
    }

    try {
      const predicates = new relationalStore.RdbPredicates('user');
      predicates.equalTo('id', user.id);

      hilog.info(0x0000, TAG, `Updating user info with values: ${JSON.stringify(valuesBucket)}`);

      const rowCount = await this.rdbStore.update(valuesBucket, predicates);
      hilog.info(0x0000, TAG, `Updated user info with ${rowCount} rows affected`);
      return rowCount > 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update user info: ${error}`);
      hilog.error(0x0000, TAG, `ValuesBucket: ${JSON.stringify(valuesBucket)}`);
      return false;
    }
  }

  // 获取用户详细信息
  public async getUserById(userId: number): Promise<User | null> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return null;
    }

    try {
      const predicates = new relationalStore.RdbPredicates('user');
      predicates.equalTo('id', userId);

      const resultSet = await this.rdbStore.query(predicates, [
        'id', 'username', 'password', 'age', 'gender', 'phone', 'email',
        'height', 'weight', 'emergency_contact', 'emergency_phone',
        'medical_history', 'avatar_path'
      ]);

      if (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const username = resultSet.getString(resultSet.getColumnIndex('username'));
        const password = resultSet.getString(resultSet.getColumnIndex('password'));
        const age = resultSet.isColumnNull(resultSet.getColumnIndex('age'))
          ? undefined
          : resultSet.getLong(resultSet.getColumnIndex('age'));
        const gender = resultSet.isColumnNull(resultSet.getColumnIndex('gender'))
          ? undefined
          : resultSet.getString(resultSet.getColumnIndex('gender'));
        const phone = resultSet.isColumnNull(resultSet.getColumnIndex('phone'))
          ? undefined
          : resultSet.getString(resultSet.getColumnIndex('phone'));
        const email = resultSet.isColumnNull(resultSet.getColumnIndex('email'))
          ? undefined
          : resultSet.getString(resultSet.getColumnIndex('email'));
        const height = resultSet.isColumnNull(resultSet.getColumnIndex('height'))
          ? undefined
          : resultSet.getDouble(resultSet.getColumnIndex('height'));
        const weight = resultSet.isColumnNull(resultSet.getColumnIndex('weight'))
          ? undefined
          : resultSet.getDouble(resultSet.getColumnIndex('weight'));
        const emergencyContact = resultSet.isColumnNull(resultSet.getColumnIndex('emergency_contact'))
          ? undefined
          : resultSet.getString(resultSet.getColumnIndex('emergency_contact'));
        const emergencyPhone = resultSet.isColumnNull(resultSet.getColumnIndex('emergency_phone'))
          ? undefined
          : resultSet.getString(resultSet.getColumnIndex('emergency_phone'));
        const medicalHistory = resultSet.isColumnNull(resultSet.getColumnIndex('medical_history'))
          ? undefined
          : resultSet.getString(resultSet.getColumnIndex('medical_history'));
        const avatarPath = resultSet.isColumnNull(resultSet.getColumnIndex('avatar_path'))
          ? undefined
          : resultSet.getString(resultSet.getColumnIndex('avatar_path'));

        resultSet.close();

        const user = new User(
          username,
          password,
          id,
          age,
          gender,
          phone,
          email,
          height,
          weight,
          emergencyContact,
          emergencyPhone,
          medicalHistory,
          avatarPath
        );

        hilog.info(0x0000, TAG, `Retrieved user: ${JSON.stringify({
          id: user.id,
          username: user.username,
          age: user.age,
          gender: user.gender,
          phone: user.phone,
          email: user.email,
          height: user.height,
          weight: user.weight
        })}`);

        return user;
      }

      resultSet.close();
      hilog.info(0x0000, TAG, `No user found for id: ${userId}`);
      return null;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to get user by id: ${error}`);
      return null;
    }
  }
  public async updateSleepRecord(record: SleepRecord): Promise<boolean> {
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        'duration': record.duration
      };

      const predicates = new relationalStore.RdbPredicates('sleep_record');
      predicates.equalTo('id', record.id);

      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update sleep record: ${error}`);
      return false;
    }
  }

  public async updateWaterRecord(record: WaterRecord): Promise<boolean> {
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        'amount': record.amount
      };

      const predicates = new relationalStore.RdbPredicates('water_record');
      predicates.equalTo('id', record.id);

      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update water record: ${error}`);
      return false;
    }
  }
}