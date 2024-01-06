import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:project/constants/AppBar_constant.dart';
import 'package:project/constants/AppColor_constants.dart';
import 'package:project/introduction/bloc/bloc_internet/internet_bloc.dart';
import 'package:project/introduction/bloc/bloc_internet/internet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../No_internet/no_internet.dart';
import '../../../constants/AnimatedTextPopUp.dart';
import '../bloc/CustomLeaveRequestApiFiles/custom_leave_request_bloc.dart';
import '../bloc/leaveRequestApiFiles/leave_request_bloc.dart';
import '../bloc/unApprovedLeaveRequestApiFiles/un_approved_leave_request_bloc.dart';
import '../bloc/unApprovedLeaveRequestApiFiles/un_approved_leave_request_event.dart';
import '../bloc/unApprovedLeaveRequestApiFiles/un_approved_leave_request_state.dart';
import '../models/CustomLeaveRequestModel.dart';
import '../models/leaveRequestModel.dart';
import '../models/unApprovedLeaveRequestModel.dart';

class LeaveApprovalPage extends StatefulWidget {
  const LeaveApprovalPage({Key? key});

  @override
  State<LeaveApprovalPage> createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage>
    with TickerProviderStateMixin{
  bool _isMounted = true; // Add this flag

  bool isInternetLost = false;
  late TabController _tabController;
  List<LeaveRequest> leaveRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          // Fetch unapproved leave requests
          context
              .read<UnapprovedLeaveRequestBloc>()
              .add(FetchUnapprovedLeaveRequests());
        } else if (_tabController.index == 1) {
          // Fetch approved leave requests
          context.read<LeaveRequestBloc>().add(FetchLeaveRequests());
        }
      }
    });

    // Fetch all data initially
    context
        .read<UnapprovedLeaveRequestBloc>()
        .add(FetchUnapprovedLeaveRequests());
    context.read<LeaveRequestBloc>().add(FetchLeaveRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _isMounted = false; // Set the flag to false when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InternetBloc, InternetStates>(
      listener: (context, state) {
        if (state is InternetLostState) {
          isInternetLost = true;
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.push(
              context,
              PageTransition(
                child: const NoInternet(),
                type: PageTransitionType.rightToLeft,
              ),
            );
          });
        } else if (state is InternetGainedState) {
          if (isInternetLost) {
            Navigator.pop(context);
          }
          isInternetLost = false;
        }
      },
      builder: (context, internetState) {
        if (internetState is InternetGainedState) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Leave History',
                style: AppBarStyles.appBarTextStyle,
              ),
              centerTitle: true,
              backgroundColor: AppColors.primaryColor,
              iconTheme: IconThemeData(color: AppColors.brightWhite),
            ),
            body: Column(
              children: [
                TabBar(
                  labelColor: Colors.black,
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Pending'), // Tab for unapproved requests
                    Tab(text: 'Approved'), // Tab for approved requests
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      BlocBuilder<UnapprovedLeaveRequestBloc, UnapprovedLeaveRequestState>(
                        builder: (context, state) {
                          if (state is UnapprovedLeaveRequestInitial) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (state is UnapprovedLeaveRequestLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          else if (state is UnapprovedLeaveRequestLoaded) {

                            final unapprovedLeaveRequests = state.unapprovedLeaveRequests;
                            if (unapprovedLeaveRequests.isEmpty) {
                              return Center(
                                child: Text('No Data Available'),
                              );
                            }
                            print("Fetched Unapproved Leave Requests:");
                            for (final leaveRequest in unapprovedLeaveRequests) {
                              print("Leave Request ID: ${leaveRequest.rwId}");
                              print("Reason: ${leaveRequest.reason}");
                              // Add more fields as needed
                            }

                            return ListView.builder(
                              itemCount: unapprovedLeaveRequests.length,
                              itemBuilder: (context, index) {
                                final leaveRequest = unapprovedLeaveRequests[index];
                                return LeaveRequestCard(
                                  id: leaveRequest.rwId,
                                  reason: leaveRequest.reason,
                                  fromDate: leaveRequest.fromdate,
                                  status: "Pending",
                                  applicationDate: leaveRequest.applicationDate,
                                  empId: leaveRequest.empId.toString(),
                                  toDate: leaveRequest.todate,
                                  customLeaveRequestBloc: context.read<CustomLeaveRequestBloc>(),
                                );
                              },
                            );
                          } else if (state is UnapprovedLeaveRequestError) {
                            return Center(
                              child: Text('Error: ${state.error}'),
                            );
                          } else {
                            return const Center(
                              child: Text('Unknown state'),
                            );
                          }
                        },
                      ),

                      BlocBuilder<LeaveRequestBloc, LeaveRequestState>(
                        builder: (context, state) {
                          if (state is LeaveRequestInitial) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (state is LeaveRequestLoading) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (state is LeaveRequestLoaded) {

                            leaveRequests = state.leaveRequests;
                            return ListView.builder(
                              itemCount: leaveRequests.length,
                              itemBuilder: (context, index) {
                                final leaveRequest = leaveRequests[index];
                                return LeaveRequestApproveCard(
                                  reason: leaveRequest.reason,
                                  fromDate: leaveRequest.fromdate,
                                  status: leaveRequest.approvedStatus,
                                  applicationDate: leaveRequest.applicationDate,
                                  toDate: leaveRequest.todate,
                                );
                              },
                            );
                          } else if (state is LeaveRequestError) {
                            return Center(
                              child: Text('Error: ${state.error}'),
                            );
                          } else {
                            return const Center(
                              child: Text('Unknown state'),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}

class LeaveRequestCard extends StatefulWidget {
  final int id;
  final String reason;
  final DateTime fromDate;
  final String status;
  final DateTime applicationDate;
  final CustomLeaveRequestBloc? customLeaveRequestBloc;
  final String empId;
  final DateTime toDate;

  LeaveRequestCard({
    required this.id,
    required this.reason,
    required this.fromDate,
    required this.status,
    required this.applicationDate,
    this.customLeaveRequestBloc,
    required this.empId,
    required this.toDate,
  });

  @override
  State<LeaveRequestCard> createState() => _LeaveRequestCardState();
}

class _LeaveRequestCardState extends State<LeaveRequestCard> with TickerProviderStateMixin {

  late AnimationController addToCartPopUpAnimationController;
  bool _isDisposed = false; // Flag to check if the widget is disposed

  @override
  void initState() {
    addToCartPopUpAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    super.initState();
  }

  @override
  void dispose() {
    addToCartPopUpAnimationController.dispose();
    _isDisposed = true; // Set the flag to true when the widget is disposed
    super.dispose();
  }

  String formatDate(DateTime date) {
    return DateFormat.yMd().format(date); // Formats the date (year, month, day)
  }

  Future<void> _approveLeave(BuildContext context) async {
    try {
      final String formattedFromDate = DateFormat('yyyy-MM-dd').format(widget.fromDate);
      final String formattedToDate = DateFormat('yyyy-MM-dd').format(widget.toDate);
      final String formattedApplicationDate = DateFormat('yyyy-MM-dd').format(widget.applicationDate);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String corporateId = prefs.getString('corporate_id') ?? "";
      final leaveRequest = CustomLeaveRequestModel(
        employeeId: widget.empId,
        fromDate: formattedFromDate,
        toDate: formattedToDate,
        reason: widget.reason,
        leaveId: 0,
        leaveDuration: null,
        approvedBy: corporateId,
        status: "Approved",
        applicationDate: formattedApplicationDate,
        remark: null,
        id: widget.id,
      );

      // Use the BLoC to post the leave request
      widget.customLeaveRequestBloc!.add(PostCustomLeaveRequest(leaveRequest: leaveRequest));

      // Wait for the approval process to complete
      // You can await the response or use a callback, depending on your implementation
      await _waitForApprovalCompletion();

      // Fetch unapproved leave requests after approval
      context.read<UnapprovedLeaveRequestBloc>().add(FetchUnapprovedLeaveRequests());
    } catch (e) {
      print('Error approving leave: $e');
    }
  }

  Future<void> _waitForApprovalCompletion() async {
    // You can implement logic to wait for the approval process to complete
    // For example, await the response from the server or use a callback
    // Adjust this method based on your implementation
    await Future.delayed(Duration(seconds: 2)); // Adjust as needed
  }
  void showPopupWithMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return addToCartPopUpSuccess(
          addToCartPopUpAnimationController,
          message,
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reason,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'From: ${formatDate(widget.fromDate)}',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'To: ${formatDate(widget.toDate)}',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Application Date: ${formatDate(widget.applicationDate)}',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              children: [
                SizedBox(height: 40,),
                ElevatedButton(
                  onPressed: () {
                    if (widget.customLeaveRequestBloc != null) {
                      addToCartPopUpAnimationController.forward();
                      Timer(const Duration(seconds: 2), () {
                        _approveLeave(context);
                        addToCartPopUpAnimationController.reverse();
                        Navigator.pop(context);
                      });
                      showPopupWithMessage("Leave approved!");
                    } else {
                      print("The values passed are null");
                    }
                  },
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LeaveRequestApproveCard extends StatelessWidget {
  final String reason;
  final DateTime fromDate;
  final DateTime toDate;
  final String status;
  final DateTime applicationDate;

  LeaveRequestApproveCard({
    required this.reason,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.applicationDate,
  });

  String formatDate(DateTime date) {
    return DateFormat.yMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(8.0),
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue,
              ),
              child: const Icon(
                Icons.description,
                size: 36.0,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'From: ${formatDate(fromDate)}',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.height > 720 ? 20 : 15),
                      Text(
                        'To: ${formatDate(toDate)}',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20.0,
                        color: Colors.blue,
                      ),
                      Text(
                        status,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Application Date: ${formatDate(applicationDate)}',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
