import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/constants/apis.dart';
import '../../../Sqlite/admin_sqliteHelper.dart';
import 'companyModel.dart';

class CompanyRepository {
  final String baseUrl = '${Apis.adminUrl}/Company';

  Future<List<Company>> getAllActiveCompanies() async {
    try {
      // Retrieve corporate_id from SQLite table
      final adminDbHelper = AdminDatabaseHelper();
      final adminData = await adminDbHelper.getAdmins();
      if (adminData.isNotEmpty) {
        final String? corporateId = adminData.first['corporate_id'];

        if (corporateId == null) {
          print('Corporate ID is null in SQLite table');
          return [];
        }

        final Uri uri = Uri.parse('$baseUrl/GetAllActive?CorporateId=$corporateId');

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final List<Company> companies =
          data.map((item) => Company.fromJson(item)).toList();
          return companies;
        } else {
          print('HTTP Status Code: ${response.statusCode}');
          throw Exception('Failed to load companies');
        }
      } else {
        print('No admin data found in the SQLite table');
        return [];
      }
    } catch (e) {
      // Handle any network or exception errors here.
      print('Exception occurred while fetching companies: $e');
      return [];
    }
  }
}
