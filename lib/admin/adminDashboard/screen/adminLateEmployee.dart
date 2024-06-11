import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/AppBar_constant.dart';
import '../../../constants/AppColor_constants.dart';
import '../models/adminLeaveEmployee_model.dart';
import '../models/adminLeave_repository.dart';

class AdminLeaveEmployeePage extends StatefulWidget {
  const AdminLeaveEmployeePage({super.key});

  @override
  _AdminLeaveEmployeePageState createState() => _AdminLeaveEmployeePageState();
}

class _AdminLeaveEmployeePageState extends State<AdminLeaveEmployeePage> {
  late Future<List<AdminLeaveEmployee>> futurePresentEmployees;
  final LeaveEmployeeRepository repository = LeaveEmployeeRepository('http://62.171.184.216:9595/api/Admin/Dashboard');
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
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
                    return Center(child: Text('Failed to load present employees'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No present employees found'));
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Card No.')),

                                  DataColumn(label: Text('Name')),

                                  DataColumn(label: Text('Status')),
                                ],
                                rows: entry.value.map((employee) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          employee.cardNo.toString(),
                                          overflow: TextOverflow.clip,
                                        ),

                                      ),
                                      DataCell(
                                        Text(
                                          employee.empName,
                                          overflow: TextOverflow.clip,
                                        ),

                                      ),



                                      DataCell(
                                        Text(
                                          employee.status,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
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
}
