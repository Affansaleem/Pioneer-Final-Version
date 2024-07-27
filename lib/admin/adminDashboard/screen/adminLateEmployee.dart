import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/AppBar_constant.dart';
import '../../../constants/AppColor_constants.dart';
import '../models/adminLeaveEmployee_model.dart';
import '../models/adminLeave_repository.dart';

class AdminLeaveEmployeePage extends StatefulWidget {
  AdminLeaveEmployeePage({super.key,required this.date});
  DateTime date;

  @override
  _AdminLeaveEmployeePageState createState() => _AdminLeaveEmployeePageState();
}

class _AdminLeaveEmployeePageState extends State<AdminLeaveEmployeePage> {
  late Future<List<AdminLeaveEmployee>> futurePresentEmployees;
  final LeaveEmployeeRepository repository = LeaveEmployeeRepository('http://62.171.184.216:9595/api/Admin/Dashboard');
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate= widget.date;
    futurePresentEmployees = repository.getPresentEmployees(selectedDate);
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        futurePresentEmployees = repository.getPresentEmployees(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 55.0),
            child: Text(
              "Leave Employees",
              style: AppBarStyles.appBarTextStyle,
            ),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xFFffffff),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${DateFormat('EEEE, dd-MM-yyyy').format(selectedDate)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<AdminLeaveEmployee>>(
                future: futurePresentEmployees,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'No Data Found',

                          ),
                        ),
                        // Bottom "Please make sure you have processed the attendance" Text
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20.0), // Adjust bottom padding as needed
                            child: Text(
                              "Please make sure you have processed the attendance",
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'No Data Found',

                          ),
                        ),
                        // Bottom "Please make sure you have processed the attendance" Text
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20.0), // Adjust bottom padding as needed
                            child: Text(
                              "Please make sure you have processed the attendance",
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    List<AdminLeaveEmployee> employees = snapshot.data!;
                    Map<String, List<AdminLeaveEmployee>> groupedEmployees = {};

                    for (var employee in employees) {
                      if (!groupedEmployees.containsKey(employee.deptNames)) {
                        groupedEmployees[employee.deptNames ?? ""] = [];
                      }
                      groupedEmployees[employee.deptNames]!.add(employee);
                    }

                    return ListView(
                      children: groupedEmployees.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                entry.key, // Department name
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            ...entry.value.map((employee) {
                              return Card(
                                margin: EdgeInsets.zero,
                                // margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: ListTile(

                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        employee.empName,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        '${DateFormat('hh:mm').format(employee.in1)} ',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Text(
                                        '${DateFormat('hh:mm').format(employee.out2)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(employee.status),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            employee.status,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),

    );

  }
  Color _getStatusColor(String status) {
    // Define colors for different statuses
    switch (status) {
      case 'P':
        return Colors.green;
      case 'A':
        return Colors.red;
    // Add other cases as needed
      default:
        return Colors.grey;
    }
  }
}
