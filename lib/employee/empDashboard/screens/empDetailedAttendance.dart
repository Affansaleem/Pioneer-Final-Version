import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/constants/AppBar_constant.dart'; // For date formatting

class EmpDetailedAttendance extends StatelessWidget {
  const EmpDetailedAttendance({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data for the attendance summary list
    final List<Map<String, dynamic>> attendanceSummary = [
      {'Date/Day': '2024-03-20', 'Status': 'Present', 'Reason': ''},
      {'Date/Day': '2024-03-19', 'Status': 'Absent', 'Reason': 'Sick leave'},
      // Add more entries as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Details', style: AppBarStyles.appBarTextStyle),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppBarStyles.appBarBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[900]),
            ),
            SizedBox(height: 20),
            // Redesigned summary boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRedesignedSummaryBox('Total Present', '10'),
                _buildRedesignedSummaryBox('Total Absent', '2'),
                _buildRedesignedSummaryBox('Total Leave', '3'),
                _buildRedesignedSummaryBox('Working Days', '15'),
              ],
            ),
            SizedBox(height: 20),
            // Attendance summary table
            DataTable(
              columns: const [
                DataColumn(label: Text('Date/Day')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Reason')),
              ],
              rows: attendanceSummary.map((data) {
                return DataRow(
                  cells: [
                    DataCell(Text(data['Date/Day'].toString(), style: TextStyle(fontFamily: 'YourCustomFont'))),
                    DataCell(Text(data['Status'].toString(), style: TextStyle(fontFamily: 'YourCustomFont'))),
                    DataCell(Text(data['Reason'].toString(), style: TextStyle(fontFamily: 'YourCustomFont'))),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedesignedSummaryBox(String title, String value) {
    return Container(
      width: 85, // Set a fixed width for the box
      height: 50, // Set a fixed height for the box
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15), // Rounded corners
        gradient: LinearGradient(
          colors: [
            Colors.blue[100] ?? Colors.blue, // Fallback to Colors.blue if Colors.blue[100] is null
            Colors.blue[200] ?? Colors.blue, // Fallback to Colors.blue if Colors.blue[200] is null
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
            SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
