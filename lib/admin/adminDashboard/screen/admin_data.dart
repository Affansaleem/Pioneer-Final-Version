import 'package:flutter/material.dart';
import '../models/AdminDashBoard_model.dart';
import 'adminAbsentEmployee.dart';
import 'adminFile_info_card.dart';
import 'adminLateEmployee.dart';
import 'adminPresentEmployee.dart';
import 'adminResponsive.dart';
import 'adminString_info_card.dart';
import 'adminTotalEmployee.dart';
import 'adminconstants.dart';


class AdminData extends StatefulWidget {
  final int totalEmployees;
  final int presentEmployees;
  final int absentEmployees;
  final int lateEmployees;
  DateTime selectedDate = DateTime.now();

   AdminData({
    Key? key,
    required this.totalEmployees,
    required this.presentEmployees,
    required this.absentEmployees,
    required this.lateEmployees,
    required this.selectedDate,
    required demoMyFiles, required AdminDashBoard adminData,
  }) : super(key: key);

  @override
  State<AdminData> createState() => _AdminDataState();
}

class _AdminDataState extends State<AdminData> {
  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;

    return Column(
      children: [

        const SizedBox(height: defaultPadding),
        AdminResponsive(
          mobile: FileInfoCardGridView(
            crossAxisCount: _size.width < 650 ? 2 : 4,
            childAspectRatio: _size.width < 650 && _size.width > 350 ? 1.3 : 1,
            totalEmployees: widget.totalEmployees,
            presentEmployees: widget.presentEmployees,
            absentEmployees: widget.absentEmployees,
            lateEmployees: widget.lateEmployees,
            selectedDate: widget.selectedDate,
          ),
          tablet:  FileInfoCardGridView(
            totalEmployees: 20,
            presentEmployees: 30,
            absentEmployees: 40,
            lateEmployees: 50,
            selectedDate: widget.selectedDate,
          ),
          desktop:  FileInfoCardGridView(
              totalEmployees: 10,
              presentEmployees: 10,
              absentEmployees: 10,
              lateEmployees: 10,
            selectedDate: widget.selectedDate,
          ),
        ),
      ],
    );
  }
}

class FileInfoCardGridView extends StatelessWidget {
   FileInfoCardGridView({
    Key? key,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1,
    required this.totalEmployees,
    required this.presentEmployees,
    required this.absentEmployees,
    required this.lateEmployees,
    required this.selectedDate,

  }) : super(key: key);

  final int crossAxisCount;
  final double childAspectRatio;
  final int totalEmployees;
  final int presentEmployees;
  final int absentEmployees;
  final int lateEmployees;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 4,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        Widget card;
        switch (index) {
          case 0:
            card = AdminFileInfoCard(
              imageSrc: "assets/icons/employees.png",
              title: "Total",
              numOfEmployees: totalEmployees,
              color: Colors.blue, selectedDate: selectedDate,

            );
            break;
          case 1:
            String title = "Present/Late";
            card = AdminStringInfoCard(
              imageSrc: "assets/icons/present.png",
              title: title,
              numOfEmployees: '$presentEmployees / $lateEmployees',
              color: const Color(0xFFFFA113),
              selectedDate: selectedDate,
            );
            break;

          case 2:
            card = AdminFileInfoCard(
              imageSrc: "assets/icons/absent.png",
              title: "Absent",
              numOfEmployees: absentEmployees,
              color: const Color(0xFFA4CDFF),
              selectedDate: selectedDate,
            );
            break;
          case 3:
            card = AdminFileInfoCard(
              imageSrc: "assets/icons/late.png",
              title: "Leave",
              numOfEmployees: lateEmployees,
              color: Colors.red,
              selectedDate: selectedDate,
            );
            break;
          default:
            return const SizedBox();
        }

        return InkWell(
          onTap: () {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminTotalEmployeePage()),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPresentEmployeePage(date: selectedDate,)),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminAbsentEmployeePage(date: selectedDate,)),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminLeaveEmployeePage(date: selectedDate,)),
                );
                break;
              default:
                break;
            }
          },
          child: card,
        );
      },

    );
  }
}

