class AdminPresentEmployee {
  final int empId;
  final String? cardNo;
  final String empName;
  final String? deptNames;
  final DateTime in1;
  final DateTime out2;
  final int hoursWorked;
  final String status;

  AdminPresentEmployee({
    required this.empId,
    required this.empName,
    this.cardNo,
    this.deptNames,
    required this.in1,
    required this.out2,
    required this.hoursWorked,
    required this.status,
  });

  factory AdminPresentEmployee.fromJson(Map<String, dynamic> json) {
    return AdminPresentEmployee(
      empId: json['empId'] ?? 0,
      empName: json['empName'] ?? '',
      cardNo: json['cardNo'],
      deptNames: json['deptNames'],
      in1: json['in1'] != null ? DateTime.parse(json['in1']) : DateTime.now(),
      out2: json['out2'] != null ? DateTime.parse(json['out2']) : DateTime.now(),
      hoursWorked: json['hoursworked'] ?? 0,
      status: json['status'] ?? '',
    );
  }
}
