import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project/constants/AppColor_constants.dart';

import '../../../constants/AppBar_constant.dart';

class AdminMessageTemplate extends StatefulWidget {
  @override
  _AdminMessageTemplateState createState() => _AdminMessageTemplateState();
}

class _AdminMessageTemplateState extends State<AdminMessageTemplate> {
  TextEditingController _controller = TextEditingController();
  String _placeholderText =
      '[name] has clocked in at [in1] and clocked out at [out2]\n\n[branch]\n[dept]';

  @override
  void initState() {
    super.initState();
    _controller.text = _placeholderText;
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template',style: AppBarStyles.appBarTextStyle,),
        backgroundColor: AppBarStyles.appBarBackgroundColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppBarStyles.appBarIconColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Message Template:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _controller,
                readOnly: true,
                maxLines: 10,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 150, // Set the width of the button
                  child: ElevatedButton(
                    onPressed: () {
                      Fluttertoast.showToast(msg: "Saved!");
                      // Pass the message template back to AdminMessageSetupPage
                      Navigator.pop(context, _controller.text);
                    },
                    child: Text(
                      'Save Template',
                      style: TextStyle(fontSize: 14,color: Colors.white), // Set the font size of the button text
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 10), // Set vertical padding
                    ),
                  ),
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
