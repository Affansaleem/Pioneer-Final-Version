import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/AppBar_constant.dart';
import '../../../constants/AppColor_constants.dart';
import '../models/adminPresentEmployee_model.dart';
import '../models/adminPresent_repository.dart';

class AdminPresentEmployeePage extends StatefulWidget {
  AdminPresentEmployeePage({super.key, required this.date});
  DateTime date;

  @override
  _AdminPresentEmployeePageState createState() => _AdminPresentEmployeePageState();
}

class _AdminPresentEmployeePageState extends State<AdminPresentEmployeePage> {
  late Future<List<AdminPresentEmployee>> futurePresentEmployees;
  final PresentEmployeeRepository repository = PresentEmployeeRepository('http://62.171.184.216:9595/api/Admin/Dashboard');
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.date;
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
              "Present Employees",
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
            const SizedBox(height: 16), // Add spacing between the date picker and the headings

            const SizedBox(height: 8), // Add spacing between the headings and the cards
            Expanded(
              child: FutureBuilder<List<AdminPresentEmployee>>(
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
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
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
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20.0),
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
                    List<AdminPresentEmployee> employees = snapshot.data!;
                    Map<String, List<AdminPresentEmployee>> groupedEmployees = {};

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
                              padding: EdgeInsets.symmetric(horizontal: 13.0),
                              child: Row(
                                children: [

                                    Container(
                                        width:150,
                                        child: Text('Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),


                                    Expanded(child: Text('In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                  Expanded(child: Text('Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ...entry.value.map((employee) {
                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // Adjust padding as needed
                                  title: Row(

                                    children: [
                                      Container(
                                        width:120,
                                        child: Tooltip(

                                          message: employee.empName, // Show full name on hover
                                          child: Text(
                                            employee.empName,
                                            style: const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis, // Handle overflow
                                          ),
                                        ),
                                      ),

                                      Expanded(

                                        child: Text(
                                          '${DateFormat('hh:mm').format(employee.in1)}',
                                          style: const TextStyle(fontSize: 14),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),

                                      Expanded(

                                        child: Text(
                                          '${DateFormat('hh:mm').format(employee.out2)}',
                                          style: const TextStyle(fontSize: 14),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children:[ Container(
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
