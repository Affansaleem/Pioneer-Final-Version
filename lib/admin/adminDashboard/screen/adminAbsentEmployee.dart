import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project/constants/apis.dart';
import '../../../constants/AppBar_constant.dart';
import '../../../constants/AppColor_constants.dart';
import '../models/adminAbsentEmployee_model.dart';
import '../models/adminAbsent_repository.dart';


class AdminAbsentEmployeePage extends StatefulWidget {
   AdminAbsentEmployeePage({super.key,required this.date});
  DateTime date;
  @override
  _AdminAbsentEmployeePageState createState() => _AdminAbsentEmployeePageState();
}

class _AdminAbsentEmployeePageState extends State<AdminAbsentEmployeePage> {
  late Future<List<AdminAbsentEmployee>> futurePresentEmployees;
  final AbsentEmployeeRepository repository = AbsentEmployeeRepository('${Apis.adminUrl}/Dashboard');
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
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 55.0),
            child: Text(
              "Absent Employees",
              style: AppBarStyles.appBarTextStyle,
            ),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFffffff),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${DateFormat('EEEE, dd-MM-yyyy').format(selectedDate)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<AdminAbsentEmployee>>(
                future: futurePresentEmployees,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                    List<AdminAbsentEmployee> employees = snapshot.data!;
                    Map<String, List<AdminAbsentEmployee>> groupedEmployees = {};

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
                             Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                      width: 120,
                                      child: Text('Card No.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                  Expanded(

                                      child: Text('Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                  Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            ...entry.value.map((employee) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: EdgeInsets.only(left:8,
                                    right: 12),

                                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero, // Remove default padding if needed
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        width: 110,
                                        child: Text(
                                          employee.cardNo ?? "",
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis, // Handles overflow
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          employee.empName,
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Container(
                                        width: 40.0,
                                        height: 40.0,
                                        padding: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(employee.status),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            employee.status,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
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
    switch (status) {
      case 'P':
        return Colors.blue;
      case 'A':
        return Colors.red;
      case 'AL':
        return Colors.green;
      case 'A-LT':
        return Colors.orangeAccent;
      case 'L':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
