import relationalStore from '@ohos.data.relationalStore';
import { User } from './UserModel';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord, StepTimeRecord, StepTimeInput } from './HealthDataModel';

const TAG: string = 'DatabaseHelper';

interface StoreConfig {
  name: string;
  securityLevel: relationalStore.SecurityLevel;
}

const STORE_CONFIG: StoreConfig = {
  name: 'HealthDB.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

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


@Observed
export class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  // 修改initDatabase方法，确保步数时间记录表创建
  public async initDatabase(): Promise<boolean> {
    try {
      hilog.info(0x0000, TAG, 'Initializing database');
      this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);

      // 创建基本表
      await this.rdbStore.executeSql(SQL_CREATE_USER_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_STEP_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_HEART_RATE_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_SLEEP_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_WATER_TABLE, []);

      // 创建步数时间记录表，添加详细日志
      const stepTimeTableCreated = await this.createStepTimeRecordsTable();
      if (!stepTimeTableCreated) {
        hilog.error(0x0000, TAG, 'Failed to create step time records table');
      }

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
  // 在DatabaseHelper.ets中，修复步数时间记录表的创建方法
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
  async insertStepTimeRecord(record: StepTimeRecord): Promise<boolean> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return false;
    }

    try {
      hilog.info(0x0000, TAG, `Inserting step time record: stepRecordId=${record.stepRecordId}, time=${record.time}, steps=${record.steps}`);

      // 验证表是否存在
      try {
        const checkTableSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='step_time_record'";
        const resultSet = await this.rdbStore.querySql(checkTableSql, []);
        const tableExists = resultSet.rowCount > 0;
        resultSet.close();

        if (!tableExists) {
          hilog.error(0x0000, TAG, 'step_time_record table does not exist, attempting to create');
          const created = await this.createStepTimeRecordsTable();
          if (!created) {
            hilog.error(0x0000, TAG, 'Failed to create step_time_record table');
            return false;
          }
        }
      } catch (checkError) {
        hilog.error(0x0000, TAG, `Error checking if table exists: ${checkError}`);
      }

      const valuesBucket: relationalStore.ValuesBucket = {
        'step_record_id': record.stepRecordId,
        'time': record.time,
        'steps': record.steps
      };

      hilog.debug(0x0000, TAG, `ValuesBucket for insertion: ${JSON.stringify(valuesBucket)}`);

      const rowId = await this.rdbStore.insert('step_time_record', valuesBucket);
      hilog.info(0x0000, TAG, `Inserted step time record with rowId: ${rowId}`);
      return rowId >= 0;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert step time record: ${error}`);
      return false;
    }
  }

  // 查询指定步数记录的所有时间点记录
  async getStepTimeRecords(stepRecordId: number): Promise<StepTimeRecord[]> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return [];
    }

    try {
      hilog.info(0x0000, TAG, `Querying step time records for stepRecordId: ${stepRecordId}`);

      // 验证表是否存在
      try {
        const checkTableSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='step_time_record'";
        const resultSet = await this.rdbStore.querySql(checkTableSql, []);
        const tableExists = resultSet.rowCount > 0;
        resultSet.close();

        if (!tableExists) {
          hilog.warn(0x0000, TAG, 'step_time_record table does not exist, creating and returning empty array');
          await this.createStepTimeRecordsTable();
          return [];
        }
      } catch (checkError) {
        hilog.error(0x0000, TAG, `Error checking if table exists: ${checkError}`);
      }

      const predicates = new relationalStore.RdbPredicates('step_time_record');
      predicates.equalTo('step_record_id', stepRecordId);
      predicates.orderByAsc('time');

      hilog.debug(0x0000, TAG, `Executing query with predicates: step_record_id=${stepRecordId}`);

      const resultSet = await this.rdbStore.query(predicates, ['id', 'step_record_id', 'time', 'steps']);
      hilog.info(0x0000, TAG, `Query returned ${resultSet.rowCount} records`);

      const records: StepTimeRecord[] = [];

      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const recordId = resultSet.getLong(resultSet.getColumnIndex('step_record_id'));
        const time = resultSet.getString(resultSet.getColumnIndex('time'));
        const steps = resultSet.getLong(resultSet.getColumnIndex('steps'));

        hilog.debug(0x0000, TAG, `Found record: id=${id}, stepRecordId=${recordId}, time=${time}, steps=${steps}`);

        const record = new StepTimeRecord(recordId, time, steps);
        record.id = id;
        records.push(record);
      }

      resultSet.close();
      hilog.info(0x0000, TAG, `Retrieved ${records.length} step time records`);
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query step time records: ${error}`);
      return [];
    }
  }
  async deleteStepTimeRecords(stepRecordId: number): Promise<boolean> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return false;
    }

    try {
      hilog.info(0x0000, TAG, `Deleting step time records for stepRecordId: ${stepRecordId}`);

      // 验证表是否存在
      try {
        const checkTableSql = "SELECT name FROM sqlite_master WHERE type='table' AND name='step_time_record'";
        const resultSet = await this.rdbStore.querySql(checkTableSql, []);
        const tableExists = resultSet.rowCount > 0;
        resultSet.close();

        if (!tableExists) {
          hilog.warn(0x0000, TAG, 'step_time_record table does not exist, nothing to delete');
          return true; // 表不存在，视为删除成功
        }
      } catch (checkError) {
        hilog.error(0x0000, TAG, `Error checking if table exists: ${checkError}`);
      }

      const predicates = new relationalStore.RdbPredicates('step_time_record');
      predicates.equalTo('step_record_id', stepRecordId);

      const deletedRows = await this.rdbStore.delete(predicates);
      hilog.info(0x0000, TAG, `Deleted ${deletedRows} step time records`);
      return true;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to delete step time records: ${error}`);
      return false;
    }
  }

  // 在DatabaseHelper.ets中增强batchSaveStepRecords方法
  async batchSaveStepRecords(userId: number, date: string, timeStepsArray: StepTimeInput[]): Promise<boolean> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return false;
    }

    hilog.info(0x0000, TAG, `batchSaveStepRecords: Starting for user ${userId}, date ${date}, records: ${timeStepsArray.length}`);

    try {
      // 计算总步数
      let totalSteps = 0;
      for (const timeStep of timeStepsArray) {
        totalSteps += timeStep.steps;
        hilog.debug(0x0000, TAG, `Record: time=${timeStep.time}, steps=${timeStep.steps}`);
      }
      hilog.info(0x0000, TAG, `Total steps to save: ${totalSteps}`);

      // 检查用户存在性
      const user = await this.getUserById(userId);
      if (!user) {
        hilog.error(0x0000, TAG, `User with ID ${userId} not found`);
        return false;
      }

      // 开始事务
      hilog.info(0x0000, TAG, 'Starting database transaction');
      await this.rdbStore.beginTransaction();

      // 查询是否已有当日记录
      hilog.info(0x0000, TAG, `Querying existing step records for date: ${date}`);
      const stepRecords = await this.getStepRecords(userId, date);
      hilog.info(0x0000, TAG, `Found ${stepRecords.length} existing records for the date`);

      let stepRecordId: number;

      if (stepRecords.length > 0) {
        // 更新现有记录
        const existingRecord = stepRecords[0];
        hilog.info(0x0000, TAG, `Updating existing record with ID: ${existingRecord.id}, current steps: ${existingRecord.steps}, new steps: ${totalSteps}`);

        existingRecord.steps = totalSteps;
        const updated = await this.updateStepRecord(existingRecord);

        if (!updated) {
          hilog.error(0x0000, TAG, `Failed to update step record with ID: ${existingRecord.id}`);
          await this.rdbStore.rollBack();
          return false;
        }

        stepRecordId = Number(existingRecord.id);
        hilog.info(0x0000, TAG, `Successfully updated step record, ID: ${stepRecordId}`);

        // 删除现有的时间点记录
        hilog.info(0x0000, TAG, `Deleting existing time records for step record ID: ${stepRecordId}`);
        await this.deleteStepTimeRecords(stepRecordId);
      } else {
        // 创建新记录
        hilog.info(0x0000, TAG, `Creating new step record for date: ${date}, steps: ${totalSteps}`);

        // 使用valueBucket，确保数据类型正确
        const valuesBucket: relationalStore.ValuesBucket = {
          'user_id': userId,
          'date': date,
          'steps': totalSteps
        };

        const rowId = await this.rdbStore.insert('step_record', valuesBucket);

        if (rowId < 0) {
          hilog.error(0x0000, TAG, `Failed to insert main step record, rowId: ${rowId}`);
          await this.rdbStore.rollBack();
          return false;
        }

        stepRecordId = rowId;
        hilog.info(0x0000, TAG, `Successfully inserted new step record, ID: ${stepRecordId}`);
      }

      // 插入时间点记录
      hilog.info(0x0000, TAG, `Inserting ${timeStepsArray.length} step time records`);
      let timeRecordsInserted = 0;

      for (const timeStep of timeStepsArray) {
        if (!timeStep.time || timeStep.steps <= 0) {
          hilog.warn(0x0000, TAG, `Skipping invalid time record: time=${timeStep.time}, steps=${timeStep.steps}`);
          continue; // 跳过无效记录
        }

        const timeRecord = new StepTimeRecord(stepRecordId, timeStep.time, timeStep.steps);

        // 使用明确的valueBucket定义，确保数据类型正确
        const timeValuesBucket: relationalStore.ValuesBucket = {
          'step_record_id': stepRecordId,
          'time': timeStep.time,
          'steps': timeStep.steps
        };

        try {
          const timeRowId = await this.rdbStore.insert('step_time_record', timeValuesBucket);

          if (timeRowId < 0) {
            hilog.error(0x0000, TAG, `Failed to insert step time record for time: ${timeStep.time}, rowId: ${timeRowId}`);
            await this.rdbStore.rollBack();
            return false;
          }

          timeRecordsInserted++;
          hilog.debug(0x0000, TAG, `Inserted time record: time=${timeStep.time}, steps=${timeStep.steps}, rowId=${timeRowId}`);
        } catch (insertError) {
          hilog.error(0x0000, TAG, `Exception inserting time record: ${insertError}`);
          await this.rdbStore.rollBack();
          return false;
        }
      }

      hilog.info(0x0000, TAG, `Successfully inserted ${timeRecordsInserted} time records`);

      // 提交事务
      hilog.info(0x0000, TAG, 'Committing transaction');
      await this.rdbStore.commit();
      hilog.info(0x0000, TAG, `Successfully saved batch step records. Total steps: ${totalSteps}`);
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

  // 辅助方法：插入记录并返回ID
  private async insertAndGetId(tableName: string, values: relationalStore.ValuesBucket): Promise<number> {
    if (!this.rdbStore) {
      return -1;
    }

    try {
      const rowId = await this.rdbStore.insert(tableName, values);
      return rowId;
    } catch (error) {
      hilog.error(0x0000, TAG, `grf_Failed to insert into ${tableName}: ${error}`);
      return -1;
    }
  }
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

        records.push(new StepRecord(userId, date, steps, id.toString()));
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