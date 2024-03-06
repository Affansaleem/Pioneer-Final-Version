import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'package:project/constants/AppBar_constant.dart';
import 'package:project/introduction/bloc/bloc_internet/internet_bloc.dart';
import 'package:project/introduction/bloc/bloc_internet/internet_state.dart';
import '../../../No_internet/no_internet.dart';
import '../../../constants/AnimatedTextPopUp.dart';
import '../bloc/pending_leaves_bloc.dart';
import '../bloc/pending_leaves_event.dart';
import '../bloc/pending_leaves_state.dart';
import '../model/ApproveManualPunchRepository.dart';
import '../model/PendingLeavesModel.dart';

class PendingLeavesPage extends StatefulWidget {
  final ApproveManualPunchRepository approveRepository;

  PendingLeavesPage({Key? key, required this.approveRepository})
      : super(key: key);

  @override
  State<PendingLeavesPage> createState() =>
      _PendingLeavesPageState(approveRepository);
}

class _PendingLeavesPageState extends State<PendingLeavesPage> with TickerProviderStateMixin {
  String? errorMessage; // Declare the errorMessage variable
  final ApproveManualPunchRepository approveRepository;
  late AnimationController addToCartPopUpAnimationController;
  DateTime? _selectedDate; // Variable to hold the selected date

  // Constructor to inject the repository
  _PendingLeavesPageState(this.approveRepository);

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
    // Trigger the fetch event when the widget is initialized.
    BlocProvider.of<PendingLeavesBloc>(context).add(FetchPendingLeaves());
  }

  void showPopupWithMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return addToCartPopUpSuccess(addToCartPopUpAnimationController, message);
      },
    );
  }

  void _refreshPendingLeaves() {
    BlocProvider.of<PendingLeavesBloc>(context).add(FetchPendingLeaves());
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
              title: const Text(
                'Attendance Approval',
                style: AppBarStyles.appBarTextStyle,
              ),
              backgroundColor: AppBarStyles.appBarBackgroundColor,
              iconTheme: IconThemeData(color: AppBarStyles.appBarIconColor),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () {
                    _selectDate(context); // Open date picker
                  },
                  icon: Icon(Icons.calendar_today), // Calendar icon
                ),
              ],
            ),
            body: BlocBuilder<PendingLeavesBloc, PendingLeavesState>(
              builder: (context, state) {
                if (state is PendingLeavesLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is PendingLeavesLoaded) {
                  return _buildList(state.pendingLeaves);
                } else if (state is PendingLeavesError &&
                    !(state is PendingLeavesLoading)) {
                  return Center(
                    child: Text('Error: ${state.error}'),
                  );
                } else {
                  return const Placeholder(); // Initial state
                }
              },
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

  Widget _buildList(List<PendingLeavesModel> leaves) {
    if (leaves.isEmpty) {
      return Center(
        child: Text(
          'No Data Available',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    List<PendingLeavesModel> filteredLeaves = leaves;

    if (_selectedDate != null) {
      // Filter leaves based on selected date if it's not null
      filteredLeaves = leaves.where((leave) =>
      leave.punchDatetime.year == _selectedDate!.year &&
          leave.punchDatetime.month == _selectedDate!.month &&
          leave.punchDatetime.day == _selectedDate!.day).toList();
    }

    return ListView.builder(
      itemCount: filteredLeaves.length,
      itemBuilder: (context, index) {
        final leave = filteredLeaves[index];
        final formattedDateTime = DateFormat('yyyy-MM-dd hh:mm a').format(leave.punchDatetime);

        return Card(
          elevation: 3,
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card, size: 36),
                  Text(
                    '${leave.cardNo}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${leave.empName}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${leave.deptName}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Icon(Icons.access_time, size: 36),
                  Text(
                    '$formattedDateTime',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Icon(Icons.location_on, size: 36),
                  Container(
                    width: 200,
                    child: Center(
                      child: Text(
                        '${leave.location}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _approveLeave(leave.cardNo, leave.punchDatetime, leave.id);
                    },
                    child: Text('Approve'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _approveLeave(String cardNo, DateTime punchDatetime, int id) {
    final dateFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
    final formattedPunchDatetime = dateFormat.format(punchDatetime);
    final formattedDateTime1 = dateFormat.format(DateTime.now().toUtc());

    final data = [
      {
        "id": id,
        // id should be added same
        "cardNo": cardNo, // Pass cardNo as leave.cardNo
        "punchDatetime":
        formattedPunchDatetime, // Punch Date-Time = formatted punchDatetime
        "pDay": formattedPunchDatetime, // Pass punchDatetime as pDay
        "ismanual": "string",
        "payCode": cardNo, // PayCode same as card number
        "machineNo": "string",
        "dateime1": formattedPunchDatetime, // DateTime1 = Punch Date-Time
        "viewinfo": 0,
        "showData": 0,
        "remark": "string"
      },
    ];

    approveRepository.postApproveManualPunch(data).then((_) {
      // Handle success if needed
      addToCartPopUpAnimationController.forward();

      // Delay for a few seconds and then reverse the animation
      Timer(const Duration(seconds: 2), () {
        addToCartPopUpAnimationController.reverse();
        Navigator.pop(context);
      });
      showPopupWithMessage("Attendance Approved Successfully!");
      _refreshPendingLeaves();
    }).catchError((error) {
      // Handle the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(), // Set initial date to current date if _selectedDate is null
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }
}
