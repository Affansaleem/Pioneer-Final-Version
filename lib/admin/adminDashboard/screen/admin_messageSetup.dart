import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';
import 'package:background_sms/background_sms.dart';
import 'package:project/constants/AppBar_constant.dart';

import 'admin_messageTemplate.dart'; // Import the BackgroundSms package

class AdminMessageSetupPage extends StatefulWidget {
  @override
  _AdminMessageSetupPageState createState() => _AdminMessageSetupPageState();
}

class _AdminMessageSetupPageState extends State<AdminMessageSetupPage> {
  String _selectedDate = '2024-04-20'; // Initial date
  List<dynamic> employees = []; // Change list type to dynamic
  bool _isLoading = false;
  String _error = '';

  Future<void> _fetchEmployees(String date) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final url =
        'http://62.171.184.216:9595/api/Admin/User/GetEmployeesForSms?CorporateId=ptsoffice&date=$date';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          employees = data as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch employees: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEmployees(_selectedDate);
  }

  // Method to send SMS messages to all users
// Method to send SMS messages to all users
  void sendMessages(String messageTemplate) async {
    if (await Permission.sms.isGranted) {
      // If SMS permission is already granted
      for (var employee in employees) {
        final message = _replacePlaceholders(messageTemplate, employee);
        final number = employee['contact'];
        smsFunction(message: message, number: number);
      }
      Fluttertoast.showToast(
        msg: 'Messages sent successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );
    } else {
      // If SMS permission is not granted, request permission
      final status = await Permission.sms.request();
      if (status.isGranted) {
        // If permission is granted after requesting
        for (var employee in employees) {
          final message = _replacePlaceholders(messageTemplate, employee);
          final number = employee['contact']; // Get the phone number from the employee data
          smsFunction(message: message, number: number);
        }
      }
    }
  }

// Method to replace placeholders in the message template with employee-specific information
  String _replacePlaceholders(String template, Map<String, dynamic> employee) {
    String message = template;
    message = message.replaceAll('[name]', employee['name'] ?? '');
    message = message.replaceAll('[in1]', employee['in1'] ?? '');
    message = message.replaceAll('[out2]', employee['out2'] ?? '');
    message = message.replaceAll('[branch]', employee['branch'] ?? '');
    message = message.replaceAll('[dept]', employee['dept'] ?? '');
    return message;
  }

  // Method to send individual SMS message
  // Method to send individual SMS message
  void smsFunction({required String message, required String number}) async {
    String formattedNumber = number.startsWith('+') ? number.substring(1) : number;
    SmsStatus res = await BackgroundSms.sendMessage(phoneNumber: formattedNumber, message: message);
    print('SMS Status: $res'); // Print the SMS status for debugging
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Setup',style: AppBarStyles.appBarTextStyle,),
        backgroundColor: AppBarStyles.appBarBackgroundColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppBarStyles.appBarIconColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              // Show date picker
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              ).then((selectedDate) {
                if (selectedDate != null) {
                  setState(() {
                    _selectedDate = selectedDate.toString().split(' ')[0];
                  });
                  _fetchEmployees(_selectedDate);
                }
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$_selectedDate',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(child: Text(_error))
              : Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title: Text(
                              '${employee['empId']} - ${employee['name']}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Divider(height: 0, color: Colors.grey[300]),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20.0),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Message Count: ${employees.length}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to AdminMessageTemplate page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminMessageTemplate(),
                    ),
                  );
                },
                icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                label: Text('Msg Template', style: TextStyle(fontSize: 14, color: Colors.blue)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final messageTemplate = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => AdminMessageTemplate()),
                  );
                  if (messageTemplate != null) {
                    if (employees.isNotEmpty) {
                      sendMessages(messageTemplate);
                    } else {
                      print('No employees found.');
                    }
                  }
                },

                icon: Icon(Icons.send, size: 20, color: Colors.blue),
                label: Text(
                  'Send SMS',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
