import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:project/admin/adminDashboard/models/adminTotalEmployee_model.dart';
import 'package:project/constants/apis.dart';
import '../../../constants/AppBar_constant.dart';
import '../../../constants/AppColor_constants.dart';
import '../models/adminTotal_repository.dart';

class AdminTotalEmployeePage extends StatefulWidget {
  const AdminTotalEmployeePage({super.key});

  @override
  _AdminTotalEmployeePageState createState() => _AdminTotalEmployeePageState();
}

class _AdminTotalEmployeePageState extends State<AdminTotalEmployeePage> {
  late Future<List<AdminTotalEmployees>> futureEmployees;
  final AdminTotalEmployeeRepository repository = AdminTotalEmployeeRepository('${Apis.adminUrl}/Dashboard');

  @override
  void initState() {
    super.initState();
    futureEmployees = repository.getTotalEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 55.0),
            child: Text(
              "Total Employees",
              style: AppBarStyles.appBarTextStyle,
            ),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(10.0),
        child: FutureBuilder<List<AdminTotalEmployees>>(
          future: futureEmployees,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('No Data Found'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No Data Found'));
            } else {
              List<AdminTotalEmployees> employees = snapshot.data!;
              return Column(
                children: [

                  Text(
                    'Total: ${employees.length}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  ),
                  SizedBox(height: 10),
                  // Display list of employees
                  Expanded(
                    child: ListView.builder(
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        AdminTotalEmployees employee = employees[index];
                        return Card(
                          child: ListTile(
                            contentPadding: EdgeInsets.all(10),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(employee.empName,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                                    Text('ID: ${employee.empId}',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
                                  ],
                                ),
                                Text('${employee.departmentName}',style: TextStyle(fontSize: 12),),
                                Text('${employee.branchName}',style: TextStyle(fontSize: 12),),

                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
