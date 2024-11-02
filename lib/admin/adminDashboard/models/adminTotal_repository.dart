import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/admin/adminDashboard/models/adminTotalEmployee_model.dart';
import '../../../Sqlite/admin_sqliteHelper.dart';

class AdminTotalEmployeeRepository {
  final String baseUrl;

  AdminTotalEmployeeRepository(this.baseUrl);

  Future<List<AdminTotalEmployees>> getTotalEmployees() async {
    final adminDbHelper = AdminDatabaseHelper();
    final adminData = await adminDbHelper.getAdmins();
    if (adminData.isNotEmpty) {
      final corporateId = adminData.first['corporate_id'];
      final url = Uri.parse('$baseUrl/GetTotalEmployees?CorporateId=$corporateId');
      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          List<dynamic> jsonResponse = jsonDecode(response.body);
          return jsonResponse.map((data) => AdminTotalEmployees.fromJson(data)).toList();
        } else {
          throw Exception('Failed to load employees');
        }
      } catch (e) {
        throw Exception('Error: $e');
      }
    } else {
      throw Exception('No admin data found in the SQLite table');
    }
  }
}
