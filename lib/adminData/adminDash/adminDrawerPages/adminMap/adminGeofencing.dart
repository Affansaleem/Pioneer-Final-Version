import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project/adminData/adminDash/adminDrawerPages/adminMap/adminMapdisplay.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api_intigration_files/GetActiveEmployee_apiFiles/get_active_employee_bloc.dart';
import '../../../../api_intigration_files/GetActiveEmployee_apiFiles/get_active_employee_event.dart';
import '../../../../api_intigration_files/GetActiveEmployee_apiFiles/get_active_employee_state.dart';
import '../../../../api_intigration_files/models/Department_model.dart';
import '../../../../api_intigration_files/models/GetActiveEmployees_model.dart';
import '../../../../api_intigration_files/repository/Branch_repository.dart';
import '../../../../api_intigration_files/repository/Company_repository.dart';
import '../../../../api_intigration_files/repository/Department_repository.dart';

class AdminGeofencing extends StatefulWidget {
  final VoidCallback openDrawer;
  const AdminGeofencing({Key? key, required this.openDrawer}) : super(key: key);

  @override
  State<AdminGeofencing> createState() => _AdminGeofencingState();
}

class _AdminGeofencingState extends State<AdminGeofencing> {
  String corporateId = '';
  List<GetActiveEmpModel> employees = [];
  List<GetActiveEmpModel> selectedEmployees = [];
  bool selectAll = false;
  final TextEditingController _remarksController = TextEditingController();
  String filterOption = 'Default'; // Initialize with Default
  String filterId = '';
  List<String> departmentNames = [];
  String? departmentDropdownValue;
  String searchQuery = '';
  Department? selectedDepartment;
  String? branchDropdownValue;
  List<String> branchNames = [];
  String? companyDropdownValue;
  List<String> companyNames = [];

  @override
  void initState() {
    super.initState();
    _fetchCorporateIdFromPrefs();
    _fetchDepartmentNames();
    _fetchBranchNames(); // Fetch department names when the widget initializes
    _fetchCompanyNames(); // Fetch company names when the widget initializes
    companyDropdownValue = null;
  }

  Future<void> _fetchDepartmentNames() async {
    try {
      final departments =
      await DepartmentRepository().getAllActiveDepartments(corporateId);

      // Extract department names from the departments list and filter out null values
      final departmentNames = departments
          .map((department) => department.deptName)
          .where((name) => name != null) // Filter out null values
          .map((name) => name!) // Convert non-nullable String? to String
          .toList();

      setState(() {
        this.departmentNames = departmentNames;
      });
    } catch (e) {
      print('Error fetching department names: $e');
    }
  }

  Future<void> _fetchCorporateIdFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCorporateId = prefs.getString('corporate_id');
    print("Stored corporate id: $storedCorporateId");
    setState(() {
      corporateId = storedCorporateId ?? '';
    });

    context.read<GetEmployeeBloc>().add(FetchEmployees(corporateId));
  }

  Future<void> _fetchBranchNames() async {
    try {
      final branches =
      await BranchRepository().getAllActiveBranches(corporateId);

      // Extract branch names from the branches list and filter out null values
      final branchNames = branches
          .map((branch) => branch.branchName)
          .where((name) => name != null) // Filter out null values
          .map((name) => name!) // Convert non-nullable String? to String
          .toList();

      setState(() {
        this.branchNames = branchNames;
      });
    } catch (e) {
      print('Error fetching branch names: $e');
    }
  }

  Future<void> _fetchCompanyNames() async {
    try {
      final companies =
      await CompanyRepository().getAllActiveCompanies(corporateId);

      final companyNames = companies
          .map((company) => company.companyName)
          .where((name) => name != null) // Filter out null values
          .map((name) => name!) // Convert non-nullable String? to String
          .toList();

      setState(() {
        this.companyNames = companyNames;
      });
    } catch (e) {
      print('Error fetching company names: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<GetEmployeeBloc>().state;

    if (state is GetEmployeeLoaded) {
      final employees = state.employees;
      setState(() {
        this.employees = employees;
      });
      _updateSelectAll();
    }
  }

  void _toggleEmployeeSelection(GetActiveEmpModel employee) {
    setState(() {
      employee.isSelected = !employee.isSelected;
      if (employee.isSelected) {
        selectedEmployees.add(employee);
      } else {
        selectedEmployees.remove(employee);
      }
      print('Employee ${employee.empName} isSelected: ${employee.isSelected}');
      print('Selected Employees: $selectedEmployees');
    });
  }

  void _updateSelectAll() {
    bool allSelected = employees.every((employee) => employee.isSelected);
    setState(() {
      selectAll = allSelected;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      print('Select All: $selectAll');

      for (var employee in employees) {
        employee.isSelected = selectAll;
      }

      if (selectAll) {
        selectedEmployees = List.from(employees);
      } else {
        selectedEmployees.clear();
      }
      print('Selected Employees: $selectedEmployees');
    });
  }

  void _showRemarksDialog(GetActiveEmpModel employee) {
    _remarksController.text = employee.remarks;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Remarks'),
          content: TextField(
            controller: _remarksController,
            decoration: const InputDecoration(
              hintText: 'Enter remarks...',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the remarks when OK is pressed
                employee.remarks = _remarksController.text;
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  bool _employeeMatchesFilter(GetActiveEmpModel employee) {
    bool departmentMatch = true;
    bool branchMatch = true;
    bool companyMatch = true;

    if (departmentDropdownValue != null) {
      departmentMatch = employee.deptNames == departmentDropdownValue;
    }

    if (branchDropdownValue != null) {
      branchMatch = employee.branchNames == branchDropdownValue;
    }

    if (companyDropdownValue != null) {
      companyMatch = employee.companyNames == companyDropdownValue;
    }

    bool searchMatch = searchQuery.isEmpty ||
        (employee.empName?.toLowerCase().contains(searchQuery.toLowerCase()) ??
            false) ||
        (employee.empCode?.toLowerCase().contains(searchQuery.toLowerCase()) ??
            false);

    // Return true if all conditions are met, otherwise, return false
    return departmentMatch && branchMatch && companyMatch && searchMatch;
  }

  List<GetActiveEmpModel> filterEmployees(
      List<GetActiveEmpModel> employees, String query) {
    return employees.where((employee) {
      bool matchesFilter = true;

      // Check if a department is selected and match it with the employee's department
      if (departmentDropdownValue != null &&
          departmentDropdownValue!.isNotEmpty) {
        matchesFilter =
            matchesFilter && employee.deptNames == departmentDropdownValue;
      }

      // Check if a branch is selected and match it with the employee's branch
      if (branchDropdownValue != null && branchDropdownValue!.isNotEmpty) {
        matchesFilter =
            matchesFilter && employee.branchNames == branchDropdownValue;
      }

      // Check if a company is selected and match it with the employee's company
      if (companyDropdownValue != null && companyDropdownValue!.isNotEmpty) {
        matchesFilter =
            matchesFilter && employee.companyNames == companyDropdownValue;
      }

      // Check if the search query matches employee's name, code, or EmpId
      bool searchMatch = query.isEmpty ||
          (employee.empName?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (employee.empCode?.toLowerCase().contains(query.toLowerCase()) ??
              false) ||
          (employee.empId.toString().contains(query)); // Check for EmpId match

      // Return true if all conditions are met (selected department, branch, company, and search query), otherwise, return false
      return matchesFilter && searchMatch;
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.bars),
          color: Colors.white,
          onPressed: widget.openDrawer,
        ),
        backgroundColor: const Color(0xFFE26142),
        elevation: 0,
        title: const Center(
          child: Padding(
            padding: EdgeInsets.only(right: 55.0), // Add right padding
            child: Text(
              "GEOFENCING",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AdminMapDisplay()));
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text(
                    "Start Geofencing",
                    style: TextStyle(
                      fontSize: 16, // Adjust the font size as needed
                      fontWeight:
                      FontWeight.bold, // Adjust the font weight as needed
                      color: Colors.white, // Change text color as needed
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: const Color(0xFFE26142),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            "FILTERS",
                            style: GoogleFonts.openSans(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          // Department Dropdown
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Department:',
                                      style: GoogleFonts.openSans(
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.0,
                                        ),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: departmentDropdownValue,
                                        onChanged: (newValue) {
                                          setState(() {
                                            departmentDropdownValue = newValue!;
                                          });
                                        },
                                        items: [
                                          DropdownMenuItem<String>(
                                            value: '',
                                            child: Text(
                                              'All',
                                              style: GoogleFonts.openSans(
                                                textStyle: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ...departmentNames.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: GoogleFonts.openSans(
                                                  textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              // Branch Dropdown
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Branch:',
                                      style: GoogleFonts.openSans(
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.0,
                                        ),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: branchDropdownValue,
                                        onChanged: (newValue) {
                                          setState(() {
                                            branchDropdownValue = newValue!;
                                          });
                                        },
                                        items: [
                                          DropdownMenuItem<String>(
                                            value: '',
                                            child: Text(
                                              'All',
                                              style: GoogleFonts.openSans(
                                                textStyle: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ...branchNames.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: GoogleFonts.openSans(
                                                  textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // Company Dropdown
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Company:',
                                      style: GoogleFonts.openSans(
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.0,
                                        ),
                                        borderRadius: BorderRadius.circular(4.0),
                                      ),
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: companyDropdownValue,
                                        onChanged: (newValue) {
                                          setState(() {
                                            companyDropdownValue = newValue!;
                                          });
                                        },
                                        items: [
                                          DropdownMenuItem<String>(
                                            value: '',
                                            child: Text(
                                              'All',
                                              style: GoogleFonts.openSans(
                                                textStyle: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          ...companyNames.map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(
                                                value,
                                                style: GoogleFonts.openSans(
                                                  textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10),
                              // Search Bar
                              Expanded(
                                flex: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .white, // Change background color to white
                                    border: Border.all(
                                      color: Colors.white,
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search by name or code...',
                                      icon: Icon(Icons.search,
                                          color: Colors
                                              .black), // Change icon color to black
                                      hintStyle: GoogleFonts.openSans(
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Colors
                                              .black, // Change hint text color to black
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal:
                                          12.0), // Adjust padding as needed
                                      border: InputBorder
                                          .none, // Remove the default border
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // "Select All" Button
                ElevatedButton(
                  onPressed: _toggleSelectAll,
                  child: Text(
                    selectAll ? 'Deselect All' : 'Select All',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),

                // Employee List in DataTable form
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black), // Add border styling
                    ),
                    child: DataTable(
                      headingRowColor: const MaterialStatePropertyAll(
                        Color(0xFFE26142),
                      ),
                      columnSpacing: 20.0,
                      columns: const [
                        DataColumn(
                            label: Text(
                              'EmpId',
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            )),
                        DataColumn(
                            label: Text(
                              'EmpName',
                              style: TextStyle(fontSize: 12, color: Colors.white),
                            )),
                        DataColumn(
                          label: Text(
                            'DeptName',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'BranchName',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Add Remarks',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ), // Add Remarks column
                        DataColumn(
                          label: Text(
                            'Select',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ),
                      ],
                      rows: filterEmployees(employees, searchQuery).map((employee) {
                        return DataRow(
                          cells: [
                            DataCell(Text(
                              employee.empId.toString(),
                              style: const TextStyle(fontSize: 12),
                            )),
                            DataCell(Text(
                              employee.empName ?? '',
                              style: const TextStyle(fontSize: 12),
                            )),
                            DataCell(Text(
                              employee.deptNames ?? '',
                              style: const TextStyle(fontSize: 12),
                            )),
                            DataCell(Text(
                              employee.branchNames ?? '',
                              style: const TextStyle(fontSize: 12),
                            )), // Ensure BranchName data is available
                            DataCell(
                              SizedBox(
                                width: 100, // Adjust the width as needed
                                height: 30, // Adjust the height as needed
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showRemarksDialog(employee);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets
                                        .zero, // Remove padding around the button text
                                  ),
                                  child: const Text(
                                    'Add Remarks',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),

                            DataCell(
                              Checkbox(
                                value: employee.isSelected,
                                onChanged: (_) {
                                  _toggleEmployeeSelection(employee);
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
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