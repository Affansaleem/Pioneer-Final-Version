import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:project/constants/AppColor_constants.dart';
import 'package:project/constants/globalObjects.dart';
import 'package:project/employee/empDashboard/screens/empDrawerItems.dart';
import '../bloc/employeeDashboardBloc/EmpDashboardk_bloc.dart';
import 'empDrawer.dart';

class CustomDrawer extends StatelessWidget {
  final EmpDashboardkBloc dashBloc;

  CustomDrawer({
    required this.dashBloc,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
            ),
            accountName: Text(GlobalObjects.empName ?? ""),
            accountEmail: Text(GlobalObjects.empMail ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundImage: GlobalObjects.empProfilePic != null &&
                  GlobalObjects.empProfilePic!.isNotEmpty
                  ? Image.memory(
                Uint8List.fromList(
                    base64Decode(GlobalObjects.empProfilePic!)),
              ).image
                  : AssetImage('assets/icons/userrr.png'),
            ),
          ),
          Container(
            child: EmpDrawer(
              onSelectedItems: (selectedItem) {
                Navigator.of(context).pop();
                switch (selectedItem) {
                  case EmpDrawerItems.home:
                    dashBloc.add(NavigateToHomeEvent());
                    break;
                  case EmpDrawerItems.reports:
                    dashBloc.add(NavigateToReportsEvent());
                    break;
                  case EmpDrawerItems.profile:
                    dashBloc.add(NavigateToProfileEvent());
                    break;
                  case EmpDrawerItems.leaves:
                    dashBloc.add(NavigateToLeaveEvent());
                    break;
                  case EmpDrawerItems.logout:
                    dashBloc.add(NavigateToLogoutEvent());
                    break;
                  default:
                    dashBloc.add(NavigateToHomeEvent());
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
