class EmpDashModel {
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int holidayCount;
  final int lateCount;

  EmpDashModel({
    required this.holidayCount,
    required this.lateCount,
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,

  });

  factory EmpDashModel.fromJson(Map<String, dynamic> json) {
    return EmpDashModel(
      presentCount: json['presentCount'] ?? 0,
      absentCount: json['absentCount'] ?? 0,
      leaveCount: json['leaveCount'] ?? 0,
      lateCount: json['late_Count'] ?? 0,
      holidayCount: json['holiday_Count'] ?? 0
    );
  }
}
