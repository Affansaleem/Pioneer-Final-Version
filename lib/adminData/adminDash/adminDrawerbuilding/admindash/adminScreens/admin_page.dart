import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:project/bloc_internet/internet_bloc.dart';
import 'package:project/bloc_internet/internet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../api_intigration_files/models/AdminDashBoard_model.dart';
import '../../../../../api_intigration_files/repository/AdminDashBoard_repository.dart';
import '../adminConstants/adminconstants.dart';
import '../adminModels/adminMyFiles.dart';
import '../adminResponsive.dart';
import '../admincomponents/adminOptions_detail.dart';
import 'admin_data.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime selectedDate = DateTime.now(); // Initialize with the current date
  final adminDashboardRepository = AdminDashboardRepository(
      'http://62.171.184.216:9595'); // Replace with your API base URL
  AdminDashBoard? adminData;

  // Function to update the selected date and fetch data
  Future<void> _updateSelectedDate(DateTime newDate) async {
    setState(() {
      selectedDate = newDate;
    });
    // Fetch data based on the new selected date and corporate ID here
    final prefs = await SharedPreferences.getInstance();
    final corporateId = prefs.getString('corporate_id') ?? '';
    _fetchDataForSelectedDate(selectedDate, corporateId);
  }

  // Function to fetch data based on the selected date and corporate ID
  void _fetchDataForSelectedDate(DateTime date, String corporateId) async {
    try {
      final adminDashboardData =
          await adminDashboardRepository.fetchDashboardData(corporateId, date);
      // Update the UI with the fetched data
      setState(() {
        adminData =
            adminDashboardData; // Assuming you have a variable adminData in your widget state
      });
    } catch (e) {
      // Handle errors here
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<AdminCloudStorageInfo> demoMyFiles = createDemoMyFiles(adminData);
    return BlocBuilder<InternetBloc, InternetStates>(
      builder: (context, state) {
        if (state is InternetGainedState) {
          return Scaffold(
            key: _scaffoldKey,
            body: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                children: [
                  const SizedBox(height: defaultPadding),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    final newDate = selectedDate
                                        .subtract(const Duration(days: 1));
                                    _updateSelectedDate(newDate);
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.green,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${selectedDate.day} ${selectedDate.month}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('EEEE').format(selectedDate),
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    final newDate =
                                        selectedDate.add(const Duration(days: 1));
                                    _updateSelectedDate(newDate);
                                  },
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            // Inside your build method
                            AdminData(
                              adminData: adminData ??
                                  AdminDashBoard(
                                    presentCount: 0,
                                    absentCount: 0,
                                    lateCount: 0,
                                    totalEmployeeCount: 0,
                                  ),
                              demoMyFiles: demoMyFiles, // Pass demoMyFiles here
                              totalEmployees: adminData?.totalEmployeeCount ?? 0, // You can provide the totalEmployees value here
                              presentEmployees: adminData?.presentCount ?? 0, // You can provide the presentEmployees value here
                              absentEmployees: adminData?.absentCount ?? 0, // You can provide the absentEmployees value here
                              lateEmployees: adminData?.lateCount ?? 0, // You can provide the lateEmployees value here
                            ),

                            const SizedBox(height: defaultPadding),
                            if (AdminResponsive.isMobile(context))
                              const AdminStorageDetails(),
                            const SizedBox(height: defaultPadding),
                            if (AdminResponsive.isMobile(context))
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    children: [
                                      Text(
                                        "Contact Details",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 10),
                                      ),
                                      Text(
                                        "FOR SUPPORT: 123456789",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 10),
                                      ),
                                      Text(
                                        "POWERED BY: PIONEER 2023",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  FloatingActionButton.extended(
                                    onPressed: () {
                                      // Save data
                                    },
                                    label: const Icon(Icons.message_outlined),
                                  ),
                                ],
                              ),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        } else if (state is InternetLostState) {
          return Expanded(
            child: Scaffold(
              body: Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "No Internet Connection!",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Lottie.asset('assets/no_wifi.json'),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return Expanded(
            child: Scaffold(
              body: Container(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "No Internet Connection!",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Lottie.asset('assets/no_wifi.json'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
