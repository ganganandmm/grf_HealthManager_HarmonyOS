import relationalStore from '@ohos.data.relationalStore';
import { User } from './UserModel';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from './HealthDataModel';
import { StepTimeInput } from '../pages/mainhomeInterface';

const TAG: string = 'DatabaseHelper';

interface StoreConfig {
  name: string;
  securityLevel: relationalStore.SecurityLevel;
}

const STORE_CONFIG: StoreConfig = {
  name: 'HealthDB.db',
  securityLevel: relationalStore.SecurityLevel.S1
};
// 用户信息表定义
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

// 步数信息表定义
const SQL_CREATE_STEP_TABLE = 'CREATE TABLE IF NOT EXISTS step_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'date TEXT NOT NULL, ' +
  'time TEXT NOT NULL, ' + // 确保包含 time 列
  'steps INTEGER NOT NULL, ' +
  'FOREIGN KEY (user_id) REFERENCES user(id))';

// 心率信息表定义
const SQL_CREATE_HEART_RATE_TABLE = 'CREATE TABLE IF NOT EXISTS heart_rate_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'date TEXT NOT NULL, ' +
  'time TEXT NOT NULL, ' +
  'rate INTEGER NOT NULL, ' +
  'FOREIGN KEY (user_id) REFERENCES user(id))';

//睡眠信息表定义
const SQL_CREATE_SLEEP_TABLE = 'CREATE TABLE IF NOT EXISTS sleep_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'date TEXT NOT NULL, ' +
  'duration INTEGER NOT NULL, ' +
  'FOREIGN KEY (user_id) REFERENCES user(id))';

// 饮水量信息表定义
const SQL_CREATE_WATER_TABLE = 'CREATE TABLE IF NOT EXISTS water_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
  'user_id INTEGER NOT NULL, ' +
  'date TEXT NOT NULL, ' +
  'time TEXT NOT NULL, ' +
  'amount INTEGER NOT NULL, ' +
  'FOREIGN KEY (user_id) REFERENCES user(id))';


// 数据库操作类
@Observed
export class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: Context;

  constructor(context: Context) { // 构造器
    this.context = context;
  }

  // 初始化数据库
  public async initDatabase(): Promise<boolean> {
    try {
      hilog.info(0x0000, TAG, 'Initializing database');
      this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);

      // 检查 step_record 表是否需要升级
      await this.upgradeStepRecordTable();

      // 创建基本表
      await this.rdbStore.executeSql(SQL_CREATE_USER_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_STEP_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_HEART_RATE_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_SLEEP_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_WATER_TABLE, []);

      // 插入测试用户，用来开发测试用
      await this.insertTestUser();
      hilog.info(0x0000, TAG, 'Database initialized successfully');
      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to initialize database: ${error}`);
      return false;
    }
  }
  // 插入测试用户方法，用来开发测试用
  private async insertTestUser(): Promise<void> {
    try {
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

  // 插入测试用户的测试信息
  private async insertTestHealthData(userId: number): Promise<void> {
    try {
      const today = new Date();
      const dateStr = today.toISOString().split('T')[0];

      // 插入步数记录
      const stepRecord = new StepRecord(userId, dateStr,"2025-04-01",10,500);
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

  // 插入新注册用户方法，用于注册
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
  // 步数时间记录表的创建方法
  async createStepTimeRecordsTable(): Promise<boolean> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return false;
    }

    try {
      hilog.info(0x0000, TAG, 'Creating step_time_record table if not exists');

      const SQL_CREATE_STEP_TIME_RECORDS_TABLE =
        'CREATE TABLE IF NOT EXISTS step_time_record ' +
          '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
          'step_record_id INTEGER NOT NULL, ' +
          'time TEXT NOT NULL, ' +
          'steps INTEGER NOT NULL, ' +
          'FOREIGN KEY (step_record_id) REFERENCES step_record(id))';

      // 检查表是否已存在
      try {
        const checkTableSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='step_time_record'";
        const resultSet = await this.rdbStore.querySql(checkTableSql, []);
        const tableExists = resultSet.rowCount > 0;
        resultSet.close();

        if (tableExists) {
          hilog.info(0x0000, TAG, 'step_time_record table already exists');
        } else {
          hilog.info(0x0000, TAG, 'step_time_record table does not exist, creating now');
        }
      } catch (checkError) {
        hilog.error(0x0000, TAG, `Error checking if table exists: ${checkError}`);
      }

      // 执行创建表SQL
      await this.rdbStore.executeSql(SQL_CREATE_STEP_TIME_RECORDS_TABLE, []);

      // 验证表是否创建成功
      try {
        const verifyTableSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='step_time_record'";
        const resultSet = await this.rdbStore.querySql(verifyTableSql, []);
        const tableExists = resultSet.rowCount > 0;
        resultSet.close();

        if (tableExists) {
          hilog.info(0x0000, TAG, 'Successfully created or verified step_time_record table');
        } else {
          hilog.error(0x0000, TAG, 'Failed to create step_time_record table, not found after creation attempt');
          return false;
        }
      } catch (verifyError) {
        hilog.error(0x0000, TAG, `Error verifying table creation: ${verifyError}`);
      }

      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to create step_time_record table: ${error}`);
      return false;
    }
  }
  //更新升级步数信息表
  private async upgradeStepRecordTable(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    try {
      // 检查表是否存在
      const checkTableSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='step_record'";
      const tableResult = await this.rdbStore.querySql(checkTableSql, []);
      const tableExists = tableResult.rowCount > 0;
      tableResult.close();

      if (tableExists) {
        // 检查表结构
        const checkColumnSql = "PRAGMA table_info(step_record)";
        const columnResult = await this.rdbStore.querySql(checkColumnSql, []);

        let hasTimeColumn = false;
        while (columnResult.goToNextRow()) {
          const columnName = columnResult.getString(columnResult.getColumnIndex('name'));
          if (columnName === 'time') {
            hasTimeColumn = true;
            break;
          }
        }
        columnResult.close();

        if (!hasTimeColumn) {
          hilog.info(0x0000, TAG, 'step_record表缺少time列，进行表结构升级');

          // 创建新表
          const tempTableSql = 'CREATE TABLE IF NOT EXISTS step_record_new ' +
            '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
            'user_id INTEGER NOT NULL, ' +
            'date TEXT NOT NULL, ' +
            'time TEXT NOT NULL, ' +
            'steps INTEGER NOT NULL, ' +
            'FOREIGN KEY (user_id) REFERENCES user(id))';

          await this.rdbStore.executeSql(tempTableSql, []);

          // 迁移数据
          const currentTime = new Date().toTimeString().substring(0, 5); // 默认时间为当前时间，格式为HH:MM
          const migrateSql = `INSERT INTO step_record_new (user_id, date, time, steps)
                            SELECT user_id, date, '${currentTime}', steps FROM step_record`;
          await this.rdbStore.executeSql(migrateSql, []);

          // 删除旧表
          await this.rdbStore.executeSql('DROP TABLE step_record', []);

          // 重命名新表
          await this.rdbStore.executeSql('ALTER TABLE step_record_new RENAME TO step_record', []);

          hilog.info(0x0000, TAG, 'step_record表结构升级完成');
        }
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `升级step_record表结构失败: ${error}`);
    }
  }

  //批量保存步数记录方法
  async batchSaveStepRecords(userId: number, date: string, timeStepsArray: StepTimeInput[]): Promise<boolean> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return false;
    }

    hilog.info(0x0000, TAG, `batchSaveStepRecords: Starting for user ${userId}, date ${date}, records: ${timeStepsArray.length}`);

    try {
      // 检查用户存在性
      const user = await this.getUserById(userId);
      if (!user) {
        hilog.error(0x0000, TAG, `User with ID ${userId} not found`);
        return false;
      }

      // 开始事务
      hilog.info(0x0000, TAG, 'Starting database transaction');
      await this.rdbStore.beginTransaction();

      let recordsInserted = 0; //插入的记录数量，初始为0

      for (const timeStep of timeStepsArray) {
        if (!timeStep.time || timeStep.steps <= 0) {
          hilog.warn(0x0000, TAG, `Skipping invalid time record: time=${timeStep.time}, steps=${timeStep.steps}`);
          continue; // 跳过无效记录
        }

        // 使用明确的valueBucket定义，确保数据类型正确
        const valuesBucket: relationalStore.ValuesBucket = {
          'user_id': userId,
          'date': date,
          'time': timeStep.time,
          'steps': timeStep.steps
        };

        try {
          const rowId = await this.rdbStore.insert('step_record', valuesBucket); //插入一条记录

          if (rowId < 0) {
            hilog.error(0x0000, TAG, `Failed to insert step record for time: ${timeStep.time}, rowId: ${rowId}`);
            await this.rdbStore.rollBack();
            return false;
          }

          recordsInserted++;
          hilog.debug(0x0000, TAG, `Inserted step record: time=${timeStep.time}, steps=${timeStep.steps}, rowId=${rowId}`);
        } catch (insertError) {
          hilog.error(0x0000, TAG, `Exception inserting step record: ${insertError}`);
          await this.rdbStore.rollBack();
          return false;
        }
      }

      hilog.info(0x0000, TAG, `Successfully inserted ${recordsInserted} step records`);

      // 提交事务
      hilog.info(0x0000, TAG, 'Committing transaction');
      await this.rdbStore.commit();
      hilog.info(0x0000, TAG, `Successfully saved batch step records. Total records: ${recordsInserted}`);
      return true;
    } catch (error) {
      // 回滚事务
      hilog.error(0x0000, TAG, `Exception in batch saving step records: ${error}`);
      try {
        if (this.rdbStore) {
          hilog.info(0x0000, TAG, 'Rolling back transaction due to error');
          await this.rdbStore.rollBack();
        }
      } catch (rollbackError) {
        hilog.error(0x0000, TAG, `Error during rollback: ${rollbackError}`);
      }
      return false;
    }
  }

  //通过用户名查询用户信息方法
  public async queryUserByUsername(username: string): Promise<User[]> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'grf_RdbStore is not initialized');
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

  // 查询用户是否合法
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

  // 步数记录相关方法，插入一条数据记录
  public async insertStepRecord(record: StepRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'time': record.time,
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
      predicates.orderByAsc('time'); // 按时间顺序排序

      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'time', 'steps']);
      const records: StepRecord[] = [];

      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const time = resultSet.getString(resultSet.getColumnIndex('time'));
        const steps = resultSet.getLong(resultSet.getColumnIndex('steps'));

        records.push(new StepRecord(userId, date, time, steps, id));
      }

      resultSet.close();
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query step records: ${error}`);
      return [];
    }
  }

  // 心率记录相关方法。插入一条记录
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

  // 返回心率记录方法
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

  // 睡眠记录插入方法
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

  // 获取用户睡眠时间方法
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

  // 饮水记录插入方法
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


  //获取用户饮水数据方法
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

  //关闭数据库方法
  public closeDatabase() {
    if (this.rdbStore) {
      this.rdbStore.close();
      this.rdbStore = null;
      hilog.info(0x0000, TAG, 'Database closed');
    }
  }


  // C检查数据是否更新
  public async checkDatabaseUpdates(userId: number, lastCheckTime: number): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    try {
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


  private async hasRecentUpdates(tableName: string, userId: number, lastCheckTime: number): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    try {
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

  // 更新步数信息
  public async updateStepRecord(record: StepRecord): Promise<boolean> {
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        'steps': record.steps
      };

      if (record.time) {
        valuesBucket.time = record.time;
      }

      const predicates = new relationalStore.RdbPredicates('step_record');
      predicates.equalTo('id', record.id);

      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update step record: ${error}`);
      return false;
    }
  }

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

  public async updateUserInfo(user: User): Promise<boolean> {
    if (!this.rdbStore || !user.id) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized or user id is invalid');
      return false;
    }

    const valuesBucket: relationalStore.ValuesBucket = {};

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

  // 根据用户Id获取用户详细信息
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