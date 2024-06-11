import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../Sqlite/admin_sqliteHelper.dart';
import 'adminLeaveEmployee_model.dart';

class LeaveEmployeeRepository {
  final String baseUrl;

  LeaveEmployeeRepository(this.baseUrl);

  Future<List<AdminLeaveEmployee>> getPresentEmployees(DateTime date) async {
    final formattedDate = "${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}-${date.year}";

    // Check if formattedDate is null
    if (formattedDate != null) {
      // Retrieve corporate_id from SQLite table
      final adminDbHelper = AdminDatabaseHelper();
      final adminData = await adminDbHelper.getAdmins();
      if (adminData.isNotEmpty) {
        final corporateId = adminData.first['corporate_id'];
        final url = Uri.parse('$baseUrl/GetOnLeaveEmployees?CorporateId=$corporateId&Date=$formattedDate');

        try {
          final response = await http.get(url);

          if (response.statusCode == 200) {
            List<dynamic> jsonResponse = jsonDecode(response.body);
            return jsonResponse.map((data) => AdminLeaveEmployee.fromJson(data)).toList();
          } else {
            throw Exception('Failed to load present employees');
          }
        } catch (e) {
          throw Exception('Error: $e');
        }
      } else {
        throw Exception('No admin data found in the SQLite table');
      }
    } else {
      throw Exception('Formatted date is null');
    }
  }
}
