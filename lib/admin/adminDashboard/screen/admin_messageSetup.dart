import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:background_sms/background_sms.dart';
import 'package:project/constants/AppBar_constant.dart';
import 'package:project/constants/apis.dart';
import 'admin_messageTemplate.dart';

class AdminMessageSetupPage extends StatefulWidget {
  @override
  _AdminMessageSetupPageState createState() => _AdminMessageSetupPageState();
}

class _AdminMessageSetupPageState extends State<AdminMessageSetupPage> {
  String _selectedDate = DateTime.now().toString().split(' ')[0];
  List<dynamic> employees = [];
  bool _isLoading = false;
  String _error = '';
  @override
  void initState() {
    super.initState();
    _fetchEmployees(_selectedDate);
  }
  Future<void> _fetchEmployees(String date) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final url =
        '${Apis.adminUrl}/User/GetEmployeesForSms?CorporateId=ptsoffice&date=$date';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Map each employee to include an 'isSelected' property set to true
        final updatedEmployees = data.map((employee) => Map<String, dynamic>.from(employee)
          ..['isSelected'] = true // Ensure the map has string keys and set isSelected to true
        ).toList();

        setState(() {
          employees = updatedEmployees;
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
  void sendMessages(String messageTemplate) async {
    int sentCount = 0;
    int notSentCount = 0;

    // Show "Sending..." toast
    Fluttertoast.showToast(
      msg: 'Sending...',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );

    if (await Permission.sms.isGranted) {
      // If SMS permission is already granted
      for (var employee in employees) {
        // Check if the employee is selected, has a non-empty contact number, and isSelected is true
        if ((employee['isSelected'] ?? false) && (employee['contact']?.isNotEmpty ?? false)) {
          final message = _replacePlaceholders(messageTemplate, employee);
          final number = employee['contact'];
          final status = await smsFunction(message: message, number: number);

          if (status == SmsStatus.sent) {
            sentCount++;
          } else {
            notSentCount++;
          }
        } else {
          notSentCount++; // Increment the count for employees with no contact or isSelected is false
        }
      }
    } else {
      // Request SMS permission if not granted
      final status = await Permission.sms.request();
      if (status.isGranted) {
        // If permission is granted after requesting
        for (var employee in employees) {
          // Check if the employee is selected, has a non-empty contact number, and isSelected is true
          if ((employee['isSelected'] ?? false) && (employee['contact']?.isNotEmpty ?? false)) {
            final message = _replacePlaceholders(messageTemplate, employee);
            final number = employee['contact'];
            final status = await smsFunction(message: message, number: number);

            if (status == SmsStatus.sent) {
              sentCount++;
            } else {
              notSentCount++;
            }
          } else {
            notSentCount++; // Increment the count for employees with no contact or isSelected is false
          }
        }
      } else {
        // Increment the count for all employees since SMS permission is not granted
        notSentCount += employees.length;
      }
    }

    // Show toast with counts
    Fluttertoast.showToast(
      msg: 'Messages sent successfully to $sentCount users. Failed to send to $notSentCount users.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }
  String _replacePlaceholders(String template, Map<String, dynamic> employee) {
    String message = template;
    message = message.replaceAll('[name]', employee['name'] ?? '');
    message = message.replaceAll('[in1]', employee['in1'] ?? '');
    message = message.replaceAll('[out2]', employee['out2'] ?? '');
    message = message.replaceAll('[branch]', employee['branch'] ?? '');
    message = message.replaceAll('[dept]', employee['dept'] ?? '');

    // Print employee data for debugging
    print('Employee Data: $employee');

    // Print the message with placeholders replaced
    print('Message with Placeholders Replaced: $message');

    return message;
  }
  Future<SmsStatus> smsFunction({required String message, required String number}) async {
    String formattedNumber = number.startsWith('+') ? number.substring(1) : number;
    SmsStatus res = await BackgroundSms.sendMessage(phoneNumber: formattedNumber, message: message);
    print('SMS Status: $res'); // Print the SMS status for debugging
    return res;
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
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        child: Column(
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedDate.split('-').reversed.join('-')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Employees",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              ],
            ),
            const SizedBox(height: 20,),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? Center(child: Text(_error))
                : Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: // Assuming each employee object now includes an 'isSelected' property
                    ListView.builder(
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        bool isSelected = employee['isSelected'] ?? false; // Use the isSelected property from the employee object

                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${employee['empId']} - ${employee['name']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4), // Add spacing between name and department
                                  Text(
                                    '${employee['dept']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    employee['isSelected'] = value ?? false; // Update the isSelected property of the employee object
                                  });
                                },
                              ),
                            ),

                            Divider(height: 0, color: Colors.grey[300]),
                          ],
                        );
                      },
                    )



                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.message, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Message Count: ${employees.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  label: const Text('Msg Template', style: TextStyle(fontSize: 14, color: Colors.blue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                  icon: const Icon(Icons.send, size: 20, color: Colors.blue),
                  label: const Text(
                    'Send SMS',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
