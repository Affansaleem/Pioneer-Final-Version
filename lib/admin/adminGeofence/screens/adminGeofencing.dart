import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_transition/page_transition.dart';
import 'package:project/constants/AppBar_constant.dart';
import 'package:project/constants/AppColor_constants.dart';
import 'package:project/introduction/bloc/bloc_internet/internet_bloc.dart';
import 'package:project/introduction/bloc/bloc_internet/internet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../No_internet/no_internet.dart';
import '../../../constants/AnimatedTextPopUp.dart';
import '../../adminReportsFiles/bloc/getActiveEmployeeApiFiles/get_active_employee_bloc.dart';
import '../../adminReportsFiles/bloc/getActiveEmployeeApiFiles/get_active_employee_event.dart';
import '../../adminReportsFiles/bloc/getActiveEmployeeApiFiles/get_active_employee_state.dart';
import '../../adminReportsFiles/models/branchRepository.dart';
import '../../adminReportsFiles/models/companyRepository.dart';
import '../../adminReportsFiles/models/departmentModel.dart';
import '../../adminReportsFiles/models/departmentRepository.dart';
import '../../adminReportsFiles/models/getActiveEmployeesModel.dart';
import 'adminMapdisplay.dart';

class AdminGeofencing extends StatefulWidget {
  const AdminGeofencing({Key? key}) : super();

  @override
  State<AdminGeofencing> createState() => _AdminGeofencingState();
}

class _AdminGeofencingState extends State<AdminGeofencing> with TickerProviderStateMixin{
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
  late AnimationController addToCartPopUpAnimationController;

  @override
  void dispose() {
    addToCartPopUpAnimationController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    addToCartPopUpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    super.initState();
    _fetchCorporateIdFromPrefs();
    _fetchDepartmentNames();
    _fetchBranchNames(); // Fetch department names when the widget initializes
    _fetchCompanyNames(); // Fetch company names when the widget initializes
    companyDropdownValue = null;
  }
  void showPopupWithMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return addToCartPopUpNoCrossMessage(
          addToCartPopUpAnimationController,
          message
        );
      },
    );
  }

  Future<void> _fetchDepartmentNames() async {
    try {
      final departments =
          await DepartmentRepository().getAllActiveDepartments(corporateId);

      // Extract department names from the departments list and filter out null values
      final departmentNames = departments
          .map((department) => department?.deptName)
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

  bool isInternetLost = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternetBloc, InternetStates>(
      listener: (context, state) {
        // TODO: implement listener
        if (state is InternetLostState) {
          // Set the flag to true when internet is lost
          isInternetLost = true;
          Future.delayed(Duration(seconds: 2), () {
            Navigator.push(
              context,
              PageTransition(
                child: NoInternet(),
                type: PageTransitionType.rightToLeft,
              ),
            );
          });
        } else if (state is InternetGainedState) {
          // Check if internet was previously lost
          if (isInternetLost) {
            // Navigate back to the original page when internet is regained
            Navigator.pop(context);
          }
          isInternetLost = false; // Reset the flag
        }
      },
      builder: (context, state) {
        if (state is InternetGainedState) {
          return Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.white),
              backgroundColor: AppColors.primaryColor,
              elevation: 0,
              title: const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 55.0), // Add right padding
                  child: Text(
                    "Geofencing",
                    style: AppBarStyles.appBarTextStyle,
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
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedEmployees != null &&
                              selectedEmployees.isNotEmpty) {
                            // Selected employees are not null or empty
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminMapDisplay(
                                    selectedEmployees: selectedEmployees),
                              ),
                            );
                          } else {
                            addToCartPopUpAnimationController.forward();

                            // Delay for a few seconds and then reverse the animation
                            Timer(const Duration(seconds: 2), () {
                              addToCartPopUpAnimationController.reverse();
                              Navigator.pop(context);
                            });
                            showPopupWithMessage("Please Select Employee!");
                          }
                        },
                        style: selectedEmployees != null &&
                            selectedEmployees.isNotEmpty
                            ? ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 24,
                                ),
                              )
                            : ElevatedButton.styleFrom(
                                primary: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 24,
                                ),
                              ),
                        child: const Text(
                          "Start Geofencing",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      contentPadding: const EdgeInsets.all(
                                          0), // Remove default padding
                                      shape: const RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                      ),
                                      content: SingleChildScrollView(
                                        child: SizedBox(
                                          width: 900,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Card(
                                              color: AppColors.primaryColor,
                                              child: Padding(
                                                padding: const EdgeInsets.all(20.0),
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
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
                                                    const SizedBox(height: 10),
                                                    // Department Dropdown
                                                    // Department Dropdown
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                                4.0),
                                                          ),
                                                          child: DropdownButtonFormField<
                                                              String>(
                                                            isExpanded: true,
                                                            value:
                                                            departmentDropdownValue,
                                                            onChanged: (newValue) {

                                                              departmentDropdownValue =
                                                                  newValue;

                                                            },
                                                            items: [
                                                              DropdownMenuItem<String>(
                                                                value: '',
                                                                child: Text(
                                                                  'All',
                                                                  style: GoogleFonts
                                                                      .openSans(
                                                                    textStyle:
                                                                    const TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight:
                                                                      FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              ...departmentNames
                                                                  .map((String value) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: value,
                                                                  child: Text(
                                                                    value,
                                                                    style: GoogleFonts
                                                                        .openSans(
                                                                      textStyle:
                                                                      const TextStyle(
                                                                        fontSize: 14,
                                                                        color:
                                                                        Colors.black,
                                                                        fontWeight:
                                                                        FontWeight
                                                                            .bold,
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

                                                    const SizedBox(height: 10),
                                                    // Branch Dropdown
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                                4.0),
                                                          ),
                                                          child: DropdownButtonFormField<
                                                              String>(
                                                            isExpanded: true,
                                                            value: branchDropdownValue,
                                                            onChanged: (newValue) {

                                                              branchDropdownValue =
                                                              newValue!;
                                                            },
                                                            items: [
                                                              DropdownMenuItem<String>(
                                                                value: '',
                                                                child: Text(
                                                                  'All',
                                                                  style: GoogleFonts
                                                                      .openSans(
                                                                    textStyle:
                                                                    const TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight:
                                                                      FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              ...branchNames
                                                                  .map((String value) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: value,
                                                                  child: Text(
                                                                    value,
                                                                    style: GoogleFonts
                                                                        .openSans(
                                                                      textStyle:
                                                                      const TextStyle(
                                                                        fontSize: 14,
                                                                        color:
                                                                        Colors.black,
                                                                        fontWeight:
                                                                        FontWeight
                                                                            .bold,
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
                                                    const SizedBox(height: 10),
                                                    // Company Dropdown
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                                4.0),
                                                          ),
                                                          child: DropdownButtonFormField<
                                                              String>(
                                                            isExpanded: true,
                                                            value: companyDropdownValue,
                                                            onChanged: (newValue) {
                                                              companyDropdownValue =
                                                              newValue!;
                                                            },
                                                            items: [
                                                              DropdownMenuItem<String>(
                                                                value: '',
                                                                child: Text(
                                                                  'All',
                                                                  style: GoogleFonts
                                                                      .openSans(
                                                                    textStyle:
                                                                    const TextStyle(
                                                                      fontSize: 14,
                                                                      fontWeight:
                                                                      FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              ...companyNames
                                                                  .map((String value) {
                                                                return DropdownMenuItem<
                                                                    String>(
                                                                  value: value,
                                                                  child: Text(
                                                                    value,
                                                                    style: GoogleFonts
                                                                        .openSans(
                                                                      textStyle:
                                                                      const TextStyle(
                                                                        fontSize: 14,
                                                                        color:
                                                                        Colors.black,
                                                                        fontWeight:
                                                                        FontWeight
                                                                            .bold,
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
                                                    const SizedBox(height: 10),
                                                    // Search Bar
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            setState(() {
                                                            });
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: const Text("Apply"),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: const Text("close"),
                                                        ),

                                                      ],
                                                    ),

                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: const Text("Apply Filters"),
                            ),
                            ElevatedButton(
                              onPressed: _toggleSelectAll,
                              child: Text(
                                selectAll ? 'Deselect All' : 'Select All',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.blueAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Employee List in DataTable form
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double cardWidth = constraints.maxWidth > 600 ? 600 : constraints.maxWidth;
                          double screenHeight = MediaQuery.of(context).size.height;
                          double containerHeight = screenHeight * 0.6;
                          return Container(
                            height: containerHeight,
                            margin: const EdgeInsets.all(20),
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: filterEmployees(employees, searchQuery).length,
                              itemBuilder: (context, index) {
                                var employee = filterEmployees(employees, searchQuery)[index];

                                return Card(
                                  margin: const EdgeInsets.all(8),
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'ID: ${employee.empCode}',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            Row(
                                              children: [
                                                Checkbox(
                                                  value: employee.isSelected,
                                                  onChanged: (_) {
                                                    _toggleEmployeeSelection(employee);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Name: ',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: '${employee.empName ?? ""}',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Branch: ',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: '${employee.branchNames ?? ""}',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: 'Department: ',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: '${employee.deptNames ?? ""}',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _showRemarksDialog(employee);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets
                                                .all(10), // Remove padding around the button text
                                          ),
                                          child: const Text(
                                            'Remarks',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
