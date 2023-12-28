import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../Sqlite/admin_sqliteHelper.dart';
import 'AdminProfileModel.dart'; // Import your SQLite helper

class AdminProfileRepository {

  Future<AdminProfileModel?> fetchAdminProfile(String employeeId) async {
    try {
      // Retrieve corporate_id from SQLite table
      final adminDbHelper = AdminDatabaseHelper();
      final adminData = await adminDbHelper.getAdmins();
      if (adminData.isNotEmpty) {
        final String? corporateId = adminData.first['corporate_id'];

        if (corporateId == null) {
          print('Corporate ID is null in SQLite table');
          return null;
        }

        final url = Uri.parse('http://62.171.184.216:9595/api/admin/dashboard/profile?CorporateId=$corporateId&employeeId=$employeeId');

        final response = await http.get(url);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return AdminProfileModel.fromJson(jsonData);
        } else {
          print('Failed to fetch admin profile data. Status code: ${response.statusCode}');
          return null;
        }
      } else {
        print('No admin data found in the SQLite table');
        return null;
      }
    } catch (e) {
      // Handle any network or exception errors here.
      print('Exception occurred while fetching admin profile data: $e');
      return null;
    }
  }
}
