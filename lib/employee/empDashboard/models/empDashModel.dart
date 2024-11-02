class EmpDashModel {
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int holidayCount;
  final int lateCount;

  EmpDashModel({
    required this.lateCount,
    required this.presentCount,
    required this.absentCount,
    required this.holidayCount,
    required this.leaveCount,

  });

  factory EmpDashModel.fromJson(Map<String, dynamic> json) {
    return EmpDashModel(
      presentCount: json['present_Count'] ?? 0,
      absentCount: json['absent_Count'] ?? 0,
      leaveCount: json['leave_Count'] ?? 0,
      holidayCount: json['holiday_Count'] ?? 0,
      lateCount: json['leave_Count'] ?? 0,
    );
  }
}
