import 'package:flutter/material.dart';
import '../../../constants/AppColor_constants.dart';
import 'adminconstants.dart';

class AdminStringInfoCard extends StatelessWidget {
  final String imageSrc;
  final String title;
  final String numOfEmployees; // Changed this to a String
  final Color color;

  const AdminStringInfoCard({
    Key? key,
    required this.imageSrc,
    required this.title,
    required this.numOfEmployees,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FractionallySizedBox(
        widthFactor: 1.0,
        child: Container(
          padding: const EdgeInsets.all(defaultPadding),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Image.asset(imageSrc),
                  ),
                  Flexible(
                    child: Text(
                      numOfEmployees,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.darkGrey,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
