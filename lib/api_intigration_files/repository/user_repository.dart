import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/api_intigration_files/models/user_model.dart';

class UserRepository {
  final apiUrl = "http://62.171.184.216:9595/api/login";
  Future<List<Employee>> getData() async {
    final Map<String, dynamic> data = {
      "user_Name": "1999",
      "user_Password": "1999",
      "email": "a",
      "mobile": "a",
      "role": "employee",
      "corporateId": "ptsoffice"
    };

    final headers = {
      'Content-Type': 'application/json', // Set the content type to JSON
    };

    final client = http.Client();

    final response = await client.send(
      http.Request("GET", Uri.parse(apiUrl))
        ..headers.addAll(headers)
        ..body = jsonEncode(data),
    );

    final responseStream = await response.stream.bytesToString();

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: $responseStream");

    if (response.statusCode == 200) {
      final List responseData = json.decode(responseStream);
      print(responseData[0]["empName"]);

      print("helloworld");
      return responseData.map(((e) => Employee.fromJson(e))).toList();
    } else {
      throw Exception(
          "Failed to fetch data from the API. Status code: ${response.statusCode}");
    }
  }
}
