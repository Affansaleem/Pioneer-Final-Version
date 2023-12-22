import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  Database? _database;
  static DatabaseHelper? _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper();
    return _instance!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'pioneer.db');
    return await openDatabase(path, version: 3, onCreate: _createDB);
  }


  void _createDB(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS employee (
        id INTEGER PRIMARY KEY,
        corporate_id TEXT
      )
    ''');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS employeeProfileData (
        id INTEGER PRIMARY KEY,
        empCode INTEGER,
        profilePic TEXT,
        empName TEXT,
        emailAddress TEXT
      )
    ''');
    } catch (e) {
      print('Error creating database tables: $e');
    }
  }

  Future<void> insertEmployee(int id, String corporateId) async {
    final db = await database;
    await db.insert('employee', {'id': id, 'corporate_id': corporateId});
    print("data inserted in employee table");

  }

  Future<void> printProfileData() async {
    try {
      final db = await database;
      List<Map<String, dynamic>> result = await db.query('employeeProfileData');
      print('Employee Profile Data:');
      result.forEach((row) {
        print('ID: ${row['id']}, EmpCode: ${row['empCode']}, EmpName: ${row['empName']}, EmailAddress: ${row['emailAddress']}');
      });
    } catch (e) {
      print("Error printing profile data: $e");
    }
  }


  Future<Map<String, dynamic>> getProfileDataById(int employeeId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'employeeProfileData',
      where: 'id = ?',
      whereArgs: [employeeId],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return {}; // or any other default value
    }
  }

  Future<void> insertProfileData(int id, String empCode, String profilePic, String empName, String emailAddress) async {
    final db = await database;
    await db.insert(
      'employeeProfileData',
      {
        'id': id,
        'empCode': empCode,
        'profilePic': profilePic,
        'empName': empName,
        'emailAddress': emailAddress,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print("Data inserted in profile table for ID: $id");
  }

  Future<void> deleteProfileData(int id) async {
    try {
      final db = await database;
      await db.delete('employeeProfileData', where: 'id = ?', whereArgs: [id]);
      print('Data deleted from profile table for ID: $id');
    } catch (e) {
      print('Error deleting profile data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final db = await database;
    return await db.query('employee');
  }

  Future<int> getLoggedInEmployeeId() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query('employee');
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return 0; // or any other default value
    }
  }

  Future<Map<String, dynamic>?> getFirstEmployee() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query('employee', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<String?> getCoorporateId() async {
    final firstEmployee = await getFirstEmployee();
    return firstEmployee != null ? firstEmployee['corporate_id'] as String : null;
  }

  Future<void> deleteEmployee(int employeeId) async {
    final db = await database;
    await db.delete('employee', where: 'id = ?', whereArgs: [employeeId]);
  }
}
