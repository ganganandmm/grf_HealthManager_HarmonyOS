// 导入关系型数据库模块
import relationalStore from '@ohos.data.relationalStore';
// 导入用户模型类
import { User } from './UserModel';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { StepRecord, HeartRateRecord, SleepRecord, WaterRecord } from './HealthDataModel';
import { StepTimeInput } from '../Interface/mainhomeInterface';

// 定义日志标签
const TAG: string = 'DatabaseHelper';

/**
 * 数据库配置接口：定义数据库名称和安全级别
 */
interface StoreConfig {
  name: string;                               // 数据库文件名
  securityLevel: relationalStore.SecurityLevel; // 安全级别
}

/**
 * 数据库配置常量：定义健康数据库的名称和安全级别
 * S1表示基本安全级别，适用于一般性应用数据
 */
const STORE_CONFIG: StoreConfig = {
  name: 'HealthDB.db',                         // 数据库文件名
  securityLevel: relationalStore.SecurityLevel.S1 // 安全级别为S1（基本安全）
};

/**
 * 用户表创建SQL：定义用户基本信息和健康档案
 * 包含ID、用户名、密码、年龄、性别等个人信息和紧急联系人、病史等健康相关字段
 */
const SQL_CREATE_USER_TABLE = 'CREATE TABLE IF NOT EXISTS user ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +   // 自增主键
  'username TEXT NOT NULL, ' +                  // 用户名（必填）
  'password TEXT NOT NULL, ' +                  // 密码（必填）
  'age INTEGER, ' +                             // 年龄
  'gender TEXT, ' +                             // 性别
  'phone TEXT, ' +                              // 电话号码
  'email TEXT, ' +                              // 电子邮箱
  'height REAL, ' +                             // 身高（浮点数）
  'weight REAL, ' +                             // 体重（浮点数）
  'emergency_contact TEXT, ' +                  // 紧急联系人姓名
  'emergency_phone TEXT, ' +                    // 紧急联系人电话
  'medical_history TEXT, ' +                    // 病史记录
  'avatar_path TEXT)';                          // 头像文件路径

/**
 * 步数记录表创建SQL：存储用户每日步数信息
 * 每条记录包含用户ID、日期、时间和步数
 */
const SQL_CREATE_STEP_TABLE = 'CREATE TABLE IF NOT EXISTS step_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +   // 自增主键
  'user_id INTEGER NOT NULL, ' +                // 用户ID（外键）
  'date TEXT NOT NULL, ' +                      // 日期
  'time TEXT NOT NULL, ' +                      // 时间
  'steps INTEGER NOT NULL, ' +                  // 步数
  'FOREIGN KEY (user_id) REFERENCES user(id))'; // 外键约束

/**
 * 心率记录表创建SQL：存储用户心率监测数据
 * 每条记录包含用户ID、日期、时间和心率值
 */
const SQL_CREATE_HEART_RATE_TABLE = 'CREATE TABLE IF NOT EXISTS heart_rate_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +   // 自增主键
  'user_id INTEGER NOT NULL, ' +                // 用户ID（外键）
  'date TEXT NOT NULL, ' +                      // 日期
  'time TEXT NOT NULL, ' +                      // 时间
  'rate INTEGER NOT NULL, ' +                   // 心率值
  'FOREIGN KEY (user_id) REFERENCES user(id))'; // 外键约束

/**
 * 睡眠记录表创建SQL：存储用户每日睡眠时长
 * 每条记录包含用户ID、日期和睡眠时长（分钟）
 */
const SQL_CREATE_SLEEP_TABLE = 'CREATE TABLE IF NOT EXISTS sleep_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +   // 自增主键
  'user_id INTEGER NOT NULL, ' +                // 用户ID（外键）
  'date TEXT NOT NULL, ' +                      // 日期
  'duration INTEGER NOT NULL, ' +               // 睡眠时长（分钟）
  'FOREIGN KEY (user_id) REFERENCES user(id))'; // 外键约束

/**
 * 饮水记录表创建SQL：存储用户饮水记录
 * 每条记录包含用户ID、日期、时间和饮水量（毫升）
 */
const SQL_CREATE_WATER_TABLE = 'CREATE TABLE IF NOT EXISTS water_record ' +
  '(id INTEGER PRIMARY KEY AUTOINCREMENT, ' +   // 自增主键
  'user_id INTEGER NOT NULL, ' +                // 用户ID（外键）
  'date TEXT NOT NULL, ' +                      // 日期
  'time TEXT NOT NULL, ' +                      // 时间
  'amount INTEGER NOT NULL, ' +                 // 饮水量（毫升）
  'FOREIGN KEY (user_id) REFERENCES user(id))'; // 外键约束


/**
 * 数据库操作类：提供健康应用所需的所有数据库操作
 * @Observed 装饰器使该类成为可观察对象，支持UI组件对数据变化的响应
 */
@Observed
export class DatabaseHelper {
  private rdbStore: relationalStore.RdbStore | null = null; // 数据库存储实例
  private context: Context; // 应用上下文

  /**
   * 构造函数：初始化数据库帮助类
   * @param context - 应用上下文，用于获取数据库实例
   */
  constructor(context: Context) {
    this.context = context;
  }

  /**
   * 初始化数据库：创建所有表结构并添加测试数据
   * @returns 操作是否成功
   */
  public async initDatabase(): Promise<boolean> {
    try {
      hilog.info(0x0000, TAG, 'Initializing database'); // 记录初始化开始日志
      // 获取数据库实例
      this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);

      // 创建所有基本表
      await this.rdbStore.executeSql(SQL_CREATE_USER_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_STEP_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_HEART_RATE_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_SLEEP_TABLE, []);
      await this.rdbStore.executeSql(SQL_CREATE_WATER_TABLE, []);

      // 插入测试用户数据，用于开发测试
      await this.insertTestUser();
      hilog.info(0x0000, TAG, 'Database initialized successfully'); // 记录初始化成功日志
      return true;
    } catch (error) {
      // 记录初始化失败日志
      hilog.error(0x0000, TAG, `Failed to initialize database: ${error}`);
      return false;
    }
  }

  /**
   * 插入测试用户：仅在开发测试阶段使用
   * 检查admin用户是否存在，不存在则创建，并添加测试健康数据
   */
  private async insertTestUser(): Promise<void> {
    try {
      // 检查admin用户是否已存在
      const users = await this.queryUserByUsername('admin');
      if (users.length === 0) {
        // 如果不存在，添加测试用户
        const testUser = new User('admin', '123456');
        const userId = await this.insertUser(testUser);
        if (userId > 0) {
          // 为测试用户添加健康数据样本
          await this.insertTestHealthData(userId);
          hilog.info(0x0000, TAG, 'Test user and health data inserted successfully');
        }
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert test user: ${error}`);
    }
  }

  /**
   * 插入测试健康数据：为测试用户添加样本数据
   * 包括步数、心率、睡眠和饮水记录
   * @param userId - 测试用户ID
   */
  private async insertTestHealthData(userId: number): Promise<void> {
    try {
      // 获取当天日期字符串
      const today = new Date();
      const dateStr = today.toISOString().split('T')[0];

      // 插入步数记录样本
      const stepRecord = new StepRecord(userId, dateStr,"2025-04-01",10,500);
      await this.insertStepRecord(stepRecord);

      // 插入心率记录样本
      const heartRateRecord = new HeartRateRecord(userId, dateStr, '08:00', 72);
      await this.insertHeartRateRecord(heartRateRecord);

      // 插入睡眠记录样本（9.8小时转换为分钟）
      const sleepRecord = new SleepRecord(userId, dateStr, 9.8 * 60);
      await this.insertSleepRecord(sleepRecord);

      // 插入饮水记录样本
      const waterRecord = new WaterRecord(userId, dateStr, '07:30', 4000); // 4000ml
      await this.insertWaterRecord(waterRecord);
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert test health data: ${error}`);
    }
  }

  /**
   * 插入新用户：注册功能使用
   * @param user - 用户对象，包含用户名和密码
   * @returns 新用户ID，失败返回-1
   */
  public async insertUser(user: User): Promise<number> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return -1;
    }

    // 准备用户数据
    const valuesBucket: relationalStore.ValuesBucket = {
      'username': user.username,
      'password': user.password
    };

    try {
      // 插入用户记录
      const rowId = await this.rdbStore.insert('user', valuesBucket);
      hilog.info(0x0000, TAG, `Inserted user with rowId: ${rowId}`);
      return rowId;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert user: ${error}`);
      return -1;
    }
  }

  /**
   * 批量保存步数记录：处理多个时间点的步数数据
   * @param userId - 用户ID
   * @param date - 日期字符串
   * @param timeStepsArray - 包含时间和步数的数组
   * @returns 操作是否成功
   */
  async batchSaveStepRecords(userId: number, date: string, timeStepsArray: StepTimeInput[]): Promise<boolean> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return false;
    }

    hilog.info(0x0000, TAG, `batchSaveStepRecords: Starting for user ${userId}, date ${date}, records: ${timeStepsArray.length}`);

    try {
      // 检查用户是否存在
      const user = await this.getUserById(userId);
      if (!user) {
        hilog.error(0x0000, TAG, `User with ID ${userId} not found`);
        return false;
      }

      // 开始事务处理，确保数据完整性
      hilog.info(0x0000, TAG, 'Starting database transaction');
      await this.rdbStore.beginTransaction();

      let recordsInserted = 0; // 成功插入的记录计数器

      // 遍历并插入每条步数记录
      for (const timeStep of timeStepsArray) {
        // 数据验证：跳过无效记录
        if (!timeStep.time || timeStep.steps <= 0) {
          hilog.warn(0x0000, TAG, `Skipping invalid time record: time=${timeStep.time}, steps=${timeStep.steps}`);
          continue;
        }

        // 准备步数记录数据
        const valuesBucket: relationalStore.ValuesBucket = {
          'user_id': userId,
          'date': date,
          'time': timeStep.time,
          'steps': timeStep.steps
        };

        try {
          // 插入单条步数记录
          const rowId = await this.rdbStore.insert('step_record', valuesBucket);

          // 检查插入是否成功
          if (rowId < 0) {
            hilog.error(0x0000, TAG, `Failed to insert step record for time: ${timeStep.time}, rowId: ${rowId}`);
            await this.rdbStore.rollBack(); // 失败时回滚事务
            return false;
          }

          // 更新计数器并记录日志
          recordsInserted++;
          hilog.debug(0x0000, TAG, `Inserted step record: time=${timeStep.time}, steps=${timeStep.steps}, rowId=${rowId}`);
        } catch (insertError) {
          // 记录错误并回滚事务
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
      // 发生异常，回滚事务
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

  /**
   * 通过用户名查询用户：用于登录验证和用户信息检索
   * @param username - 用户名
   * @returns 用户对象数组，未找到返回空数组
   */
  public async queryUserByUsername(username: string): Promise<User[]> {
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'grf_RdbStore is not initialized');
      return [];
    }

    try {
      // 创建查询条件：匹配用户名
      const predicates = new relationalStore.RdbPredicates('user');
      predicates.equalTo('username', username);

      // 执行查询
      const resultSet = await this.rdbStore.query(predicates, ['id', 'username', 'password']);

      const users: User[] = [];
      // 处理结果集
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const username = resultSet.getString(resultSet.getColumnIndex('username'));
        const password = resultSet.getString(resultSet.getColumnIndex('password'));
        users.push(new User(username, password, id));
      }

      resultSet.close(); // 关闭结果集释放资源
      return users;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query user: ${error}`);
      return [];
    }
  }

  /**
   * 验证用户：检查用户名和密码是否匹配
   * @param username - 用户名
   * @param password - 密码
   * @returns 验证成功返回用户对象，失败返回null
   */
  public async validateUser(username: string, password: string): Promise<User | null> {
    try {
      // 先查询用户是否存在
      const users = await this.queryUserByUsername(username);
      if (users.length === 0) {
        hilog.info(0x0000, TAG, 'User not found');
        return null;
      }

      // 验证密码
      const user = users[0];
      const isValid = user.password === password;
      hilog.info(0x0000, TAG, `User validation ${isValid ? 'successful' : 'failed'}`);
      return isValid ? user : null;
    } catch (error) {
      hilog.error(0x0000, TAG, `Error validating user: ${error}`);
      return null;
    }
  }

  /**
   * 插入步数记录：记录单条步数信息
   * @param record - 步数记录对象
   * @returns 操作是否成功
   */
  public async insertStepRecord(record: StepRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    // 准备步数记录数据
    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'time': record.time,
      'steps': record.steps
    };

    try {
      // 插入记录
      const rowId = await this.rdbStore.insert('step_record', valuesBucket);
      return rowId >= 0; // 返回操作是否成功
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert step record: ${error}`);
      return false;
    }
  }

  /**
   * 获取步数记录：查询用户的步数数据
   * @param userId - 用户ID
   * @param date - 可选，特定日期，不提供则返回所有日期的记录
   * @returns 步数记录对象数组
   */
  public async getStepRecords(userId: number, date?: string): Promise<StepRecord[]> {
    if (!this.rdbStore) {
      return [];
    }
    try {
      // 创建查询条件：匹配用户ID
      const predicates = new relationalStore.RdbPredicates('step_record');
      predicates.equalTo('user_id', userId);
      // 如果提供了日期，则按日期筛选
      if (date) {
        predicates.equalTo('date', date);
      }
      predicates.orderByAsc('time'); // 按时间升序排序

      // 执行查询
      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'time', 'steps']);
      const records: StepRecord[] = [];

      // 处理结果集
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const time = resultSet.getString(resultSet.getColumnIndex('time'));
        const steps = resultSet.getLong(resultSet.getColumnIndex('steps'));

        records.push(new StepRecord(userId, date, time, steps, id));
      }

      resultSet.close(); // 关闭结果集释放资源
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query step records: ${error}`);
      return [];
    }
  }

  /**
   * 插入心率记录：记录单条心率信息
   * @param record - 心率记录对象
   * @returns 操作是否成功
   */
  public async insertHeartRateRecord(record: HeartRateRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    // 准备心率记录数据
    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'time': record.time,
      'rate': record.rate
    };

    try {
      // 插入记录
      const rowId = await this.rdbStore.insert('heart_rate_record', valuesBucket);
      return rowId >= 0; // 返回操作是否成功
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert heart rate record: ${error}`);
      return false;
    }
  }

  /**
   * 获取心率记录：查询用户的心率数据
   * @param userId - 用户ID
   * @param date - 可选，特定日期，不提供则返回所有日期的记录
   * @returns 心率记录对象数组
   */
  public async getHeartRateRecords(userId: number, date?: string): Promise<HeartRateRecord[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      // 创建查询条件：匹配用户ID
      const predicates = new relationalStore.RdbPredicates('heart_rate_record');
      predicates.equalTo('user_id', userId);
      // 如果提供了日期，则按日期筛选
      if (date) {
        predicates.equalTo('date', date);
      }

      // 执行查询
      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'time', 'rate']);
      const records: HeartRateRecord[] = [];

      // 处理结果集
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const time = resultSet.getString(resultSet.getColumnIndex('time'));
        const rate = resultSet.getLong(resultSet.getColumnIndex('rate'));

        records.push(new HeartRateRecord(userId, date, time, rate, id));
      }

      resultSet.close(); // 关闭结果集释放资源
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query heart rate records: ${error}`);
      return [];
    }
  }

  /**
   * 插入睡眠记录：记录单日睡眠信息
   * @param record - 睡眠记录对象
   * @returns 操作是否成功
   */
  public async insertSleepRecord(record: SleepRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    // 准备睡眠记录数据
    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'duration': record.duration
    };

    try {
      // 插入记录
      const rowId = await this.rdbStore.insert('sleep_record', valuesBucket);
      return rowId >= 0; // 返回操作是否成功
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert sleep record: ${error}`);
      return false;
    }
  }

  /**
   * 获取睡眠记录：查询用户的睡眠数据
   * @param userId - 用户ID
   * @param date - 可选，特定日期，不提供则返回所有日期的记录
   * @returns 睡眠记录对象数组
   */
  public async getSleepRecords(userId: number, date?: string): Promise<SleepRecord[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      // 创建查询条件：匹配用户ID
      const predicates = new relationalStore.RdbPredicates('sleep_record');
      predicates.equalTo('user_id', userId);
      // 如果提供了日期，则按日期筛选
      if (date) {
        predicates.equalTo('date', date);
      }

      // 执行查询
      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'duration']);
      const records: SleepRecord[] = [];

      // 处理结果集
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const duration = resultSet.getLong(resultSet.getColumnIndex('duration'));

        records.push(new SleepRecord(userId, date, duration, id));
      }

      resultSet.close(); // 关闭结果集释放资源
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query sleep records: ${error}`);
      return [];
    }
  }

  /**
   * 插入饮水记录：记录单条饮水信息
   * @param record - 饮水记录对象
   * @returns 操作是否成功
   */
  public async insertWaterRecord(record: WaterRecord): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }

    // 准备饮水记录数据
    const valuesBucket: relationalStore.ValuesBucket = {
      'user_id': record.userId,
      'date': record.date,
      'time': record.time,
      'amount': record.amount
    };

    try {
      // 插入记录
      const rowId = await this.rdbStore.insert('water_record', valuesBucket);
      return rowId >= 0; // 返回操作是否成功
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to insert water record: ${error}`);
      return false;
    }
  }

  /**
   * 获取饮水记录：查询用户的饮水数据
   * @param userId - 用户ID
   * @param date - 可选，特定日期，不提供则返回所有日期的记录
   * @returns 饮水记录对象数组
   */
  public async getWaterRecords(userId: number, date?: string): Promise<WaterRecord[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      // 创建查询条件：匹配用户ID
      const predicates = new relationalStore.RdbPredicates('water_record');
      predicates.equalTo('user_id', userId);
      // 如果提供了日期，则按日期筛选
      if (date) {
        predicates.equalTo('date', date);
      }

      // 执行查询
      const resultSet = await this.rdbStore.query(predicates, ['id', 'user_id', 'date', 'time', 'amount']);
      const records: WaterRecord[] = [];

      // 处理结果集
      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const userId = resultSet.getLong(resultSet.getColumnIndex('user_id'));
        const date = resultSet.getString(resultSet.getColumnIndex('date'));
        const time = resultSet.getString(resultSet.getColumnIndex('time'));
        const amount = resultSet.getLong(resultSet.getColumnIndex('amount'));

        records.push(new WaterRecord(userId, date, time, amount, id));
      }

      resultSet.close(); // 关闭结果集释放资源
      return records;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to query water records: ${error}`);
      return [];
    }
  }

  /**
   * 关闭数据库：释放数据库连接资源
   * 在应用退出或不再需要数据库连接时调用
   */
  public closeDatabase() {
    if (this.rdbStore) {
      this.rdbStore.close();
      this.rdbStore = null;
      hilog.info(0x0000, TAG, 'Database closed');
    }
  }

  /**
   * 检查数据库更新：检查用户健康数据是否有新的记录
   * 主要用于UI刷新和数据同步判断是否需要重新加载数据
   *
   * @param userId - 需要检查数据的用户ID
   * @param lastCheckTime - 上次检查数据的时间戳（注：当前实现未实际使用此参数）
   * @returns 如果任何一种健康数据有更新则返回true，否则返回false
   */
  public async checkDatabaseUpdates(userId: number, lastCheckTime: number): Promise<boolean> {
    // 检查数据库连接是否有效
    if (!this.rdbStore) {
      return false;
    }

    try {
      // 分别检查四种健康数据类型是否有更新
      // 每种数据类型都单独调用辅助方法检查
      const stepsUpdated = await this.hasRecentUpdates('step_record', userId, lastCheckTime);
      const heartRateUpdated = await this.hasRecentUpdates('heart_rate_record', userId, lastCheckTime);
      const sleepUpdated = await this.hasRecentUpdates('sleep_record', userId, lastCheckTime);
      const waterUpdated = await this.hasRecentUpdates('water_record', userId, lastCheckTime);

      // 只要有任何一种数据更新，就返回true
      return stepsUpdated || heartRateUpdated || sleepUpdated || waterUpdated;
    } catch (error) {
      // 记录错误日志并返回false
      hilog.error(0x0000, TAG, `Failed to check for database updates: ${error}`);
      return false;
    }
  }

  /**
   * 检查特定表中是否有当天的记录
   * 这是一个辅助方法，用于检查指定表是否包含当天的数据记录
   *
   * @param tableName - 要检查的数据表名称
   * @param userId - 用户ID
   * @param lastCheckTime - 上次检查时间（注：当前实现未实际使用此参数）
   * @returns 如果表中存在当天的记录则返回true，否则返回false
   * @private - 这是一个私有辅助方法
   */
  private async hasRecentUpdates(tableName: string, userId: number, lastCheckTime: number): Promise<boolean> {
    // 检查数据库连接是否有效
    if (!this.rdbStore) {
      return false;
    }

    try {
      // 获取当天的日期字符串，格式为"YYYY-MM-DD"
      const today = new Date().toISOString().split('T')[0];

      // 创建查询条件：指定用户ID和当天日期
      const predicates = new relationalStore.RdbPredicates(tableName);
      predicates.equalTo('user_id', userId);
      predicates.equalTo('date', today);

      // 执行查询，只需获取ID字段即可判断是否有记录
      const resultSet = await this.rdbStore.query(predicates, ['id']);
      // 检查是否有记录（行数大于0）
      const hasUpdates = resultSet.rowCount > 0;
      // 关闭结果集，释放资源
      resultSet.close();

      return hasUpdates;
    } catch (error) {
      // 记录错误日志并返回false
      hilog.error(0x0000, TAG, `Failed to check for updates in ${tableName}: ${error}`);
      return false;
    }
  }

  /**
   * 更新步数记录：修改已存在的步数数据
   * @param record - 包含更新信息的步数记录对象
   * @returns 操作是否成功
   */
  public async updateStepRecord(record: StepRecord): Promise<boolean> {
    // 检查数据库连接和记录ID是否有效
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      // 准备更新的数据
      const valuesBucket: relationalStore.ValuesBucket = {
        'steps': record.steps // 要更新的步数值
      };

      // 如果提供了时间，也一并更新
      if (record.time) {
        valuesBucket.time = record.time;
      }

      // 创建更新条件：匹配记录ID
      const predicates = new relationalStore.RdbPredicates('step_record');
      predicates.equalTo('id', record.id);

      // 执行更新操作
      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0; // 返回是否有记录被更新
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update step record: ${error}`);
      return false;
    }
  }

  /**
   * 更新心率记录：修改已存在的心率数据
   * @param record - 包含更新信息的心率记录对象
   * @returns 操作是否成功
   */
  public async updateHeartRateRecord(record: HeartRateRecord): Promise<boolean> {
    // 检查数据库连接和记录ID是否有效
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      // 准备更新的数据
      const valuesBucket: relationalStore.ValuesBucket = {
        'rate': record.rate // 要更新的心率值
      };

      // 创建更新条件：匹配记录ID
      const predicates = new relationalStore.RdbPredicates('heart_rate_record');
      predicates.equalTo('id', record.id);

      // 执行更新操作
      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0; // 返回是否有记录被更新
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update heart rate record: ${error}`);
      return false;
    }
  }

  /**
   * 更新用户信息：修改用户个人资料
   * @param user - 包含更新信息的用户对象
   * @returns 操作是否成功
   */
  public async updateUserInfo(user: User): Promise<boolean> {
    // 检查数据库连接和用户ID是否有效
    if (!this.rdbStore || !user.id) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized or user id is invalid');
      return false;
    }

    // 准备用户信息更新数据
    // 对每个字段进行检查，仅更新有效值，无效值设为null
    const valuesBucket: relationalStore.ValuesBucket = {};

    // 年龄字段处理
    if (user.age !== undefined) {
      valuesBucket.age = user.age;
    } else {
      valuesBucket.age = null;
    }

    // 性别字段处理
    if (user.gender !== undefined) {
      valuesBucket.gender = user.gender;
    } else {
      valuesBucket.gender = null;
    }

    // 电话字段处理
    if (user.phone !== undefined) {
      valuesBucket.phone = user.phone;
    } else {
      valuesBucket.phone = null;
    }

    // 邮箱字段处理
    if (user.email !== undefined) {
      valuesBucket.email = user.email;
    } else {
      valuesBucket.email = null;
    }

    // 身高字段处理
    if (user.height !== undefined) {
      valuesBucket.height = user.height;
    } else {
      valuesBucket.height = null;
    }

    // 体重字段处理
    if (user.weight !== undefined) {
      valuesBucket.weight = user.weight;
    } else {
      valuesBucket.weight = null;
    }

    // 头像路径字段处理
    if (user.avatarPath !== undefined) {
      valuesBucket.avatar_path = user.avatarPath;
    } else {
      valuesBucket.avatar_path = null;
    }

    try {
      // 创建更新条件：匹配用户ID
      const predicates = new relationalStore.RdbPredicates('user');
      predicates.equalTo('id', user.id);

      // 记录更新操作日志
      hilog.info(0x0000, TAG, `Updating user info with values: ${JSON.stringify(valuesBucket)}`);

      // 执行更新操作
      const rowCount = await this.rdbStore.update(valuesBucket, predicates);
      hilog.info(0x0000, TAG, `Updated user info with ${rowCount} rows affected`);
      return rowCount > 0; // 返回是否有记录被更新
    } catch (error) {
      // 记录错误日志
      hilog.error(0x0000, TAG, `Failed to update user info: ${error}`);
      hilog.error(0x0000, TAG, `ValuesBucket: ${JSON.stringify(valuesBucket)}`);
      return false;
    }
  }

  /**
   * 根据用户ID获取用户详细信息
   * @param userId - 用户ID
   * @returns 用户对象，未找到则返回null
   */
  public async getUserById(userId: number): Promise<User | null> {
    // 检查数据库连接是否有效
    if (!this.rdbStore) {
      hilog.error(0x0000, TAG, 'RdbStore is not initialized');
      return null;
    }

    try {
      // 创建查询条件：匹配用户ID
      const predicates = new relationalStore.RdbPredicates('user');
      predicates.equalTo('id', userId);

      // 执行查询，获取用户所有字段
      const resultSet = await this.rdbStore.query(predicates, [
        'id', 'username', 'password', 'age', 'gender', 'phone', 'email',
        'height', 'weight', 'emergency_contact', 'emergency_phone',
        'medical_history', 'avatar_path'
      ]);

      // 处理结果集
      if (resultSet.goToNextRow()) {
        // 获取基本字段
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const username = resultSet.getString(resultSet.getColumnIndex('username'));
        const password = resultSet.getString(resultSet.getColumnIndex('password'));

        // 获取可选字段，处理可能为null的情况
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

        // 关闭结果集释放资源
        resultSet.close();

        // 创建并返回用户对象
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

        // 记录用户信息日志（不包含敏感信息如密码）
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

      // 未找到用户
      resultSet.close();
      hilog.info(0x0000, TAG, `No user found for id: ${userId}`);
      return null;
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to get user by id: ${error}`);
      return null;
    }
  }

  /**
   * 更新睡眠记录：修改已存在的睡眠数据
   * @param record - 包含更新信息的睡眠记录对象
   * @returns 操作是否成功
   */
  public async updateSleepRecord(record: SleepRecord): Promise<boolean> {
    // 检查数据库连接和记录ID是否有效
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      // 准备更新的数据
      const valuesBucket: relationalStore.ValuesBucket = {
        'duration': record.duration // 要更新的睡眠时长
      };

      // 创建更新条件：匹配记录ID
      const predicates = new relationalStore.RdbPredicates('sleep_record');
      predicates.equalTo('id', record.id);

      // 执行更新操作
      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0; // 返回是否有记录被更新
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update sleep record: ${error}`);
      return false;
    }
  }

  /**
   * 更新饮水记录：修改已存在的饮水数据
   * @param record - 包含更新信息的饮水记录对象
   * @returns 操作是否成功
   */
  public async updateWaterRecord(record: WaterRecord): Promise<boolean> {
    // 检查数据库连接和记录ID是否有效
    if (!this.rdbStore || !record.id) {
      return false;
    }

    try {
      // 准备更新的数据
      const valuesBucket: relationalStore.ValuesBucket = {
        'amount': record.amount // 要更新的饮水量
      };

      // 创建更新条件：匹配记录ID
      const predicates = new relationalStore.RdbPredicates('water_record');
      predicates.equalTo('id', record.id);

      // 执行更新操作
      const count = await this.rdbStore.update(valuesBucket, predicates);
      return count > 0; // 返回是否有记录被更新
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to update water record: ${error}`);
      return false;
    }
  }
}