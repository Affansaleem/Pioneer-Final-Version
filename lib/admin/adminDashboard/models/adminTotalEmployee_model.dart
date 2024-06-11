class AdminTotalEmployees {
  final int empId;
  final String empName;
  final String? fatherName;
  final String departmentName;
  final String branchName;
  final String designationName;
  final String cardNo;
  final String? pwd;
  final String? emailAddress;
  final String? phoneNo;
  final String? profilePic;
  final double? lat;
  final double? lon;
  final double? radius;

  AdminTotalEmployees({
    required this.empId,
    required this.empName,
    this.fatherName,
    required this.departmentName,
    required this.branchName,
    required this.designationName,
    required this.cardNo,
    this.pwd,
    this.emailAddress,
    this.phoneNo,
    this.profilePic,
    this.lat,
    this.lon,
    this.radius,
  });

  factory AdminTotalEmployees.fromJson(Map<String, dynamic> json) {
    return AdminTotalEmployees(
      empId: json['empId'],
      empName: json['empName'],
      fatherName: json['fatherName'],
      departmentName: json['departmentName'],
      branchName: json['branchName'],
      designationName: json['designationName'],
      cardNo: json['cardNo'],
      pwd: json['pwd'],
      emailAddress: json['emailAddress'],
      phoneNo: json['phoneNo'],
      profilePic: json['profilePic'],
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
      radius: json['radius']?.toDouble(),
    );
  }
}
