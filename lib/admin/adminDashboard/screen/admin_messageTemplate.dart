import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminMessageTemplate extends StatefulWidget {
  @override
  _AdminMessageTemplate createState() => _AdminMessageTemplate();
}

class _AdminMessageTemplate extends State<AdminMessageTemplate> {
  TextEditingController _controller = TextEditingController();
  List<String> placeholders = ['name', 'in1', 'out2', 'branch', 'dept']; // List of placeholders
  FocusNode _textFieldFocusNode=FocusNode();
  @override
  void initState() {
    super.initState();
    // Start with an empty text field
    _controller.text = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Template',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue, // Example color
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // Example color
        ),
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
              // Fixed-size scrollable text field
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode()); // Request focus to dismiss the keyboard
                  _controller.selection = TextSelection.collapsed(offset: _controller.text.length); // Move cursor to the end of the text
                  FocusScope.of(context).requestFocus(_textFieldFocusNode); // Request focus on the text field
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black), // Set container border color
                    borderRadius: BorderRadius.circular(10.0), // Set container border radius for rounded corners
                  ),
                  height: 200, // Set the height of the container
                  width: double.infinity, // Set the width of the container
                  child: SingleChildScrollView(
                    child: TextField(
                      focusNode: _textFieldFocusNode,
                      controller: _controller,
                      maxLines: null, // Allow unlimited lines
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        border: InputBorder.none, // Remove text field border
                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0), // Increase padding to increase size
                      ),
                      style: TextStyle(color: Colors.black), // Set text color to black
                      onChanged: (value) {
                        setState(() {}); // Update state when text changes
                      },
                    ),
                  ),
                ),
              ),


              SizedBox(height: 20),
              // Dropdown menu for selecting placeholders
              DropdownButtonFormField<String>(
                value: null,
                hint: Text('Select Placeholder'),
                items: placeholders
                    .map((placeholder) => DropdownMenuItem<String>(
                  value: placeholder,
                  child: Text(placeholder),
                ))
                    .toList(),
                onChanged: (selectedPlaceholder) {
                  // Append selected placeholder into the text field
                  final text = _controller.text;
                  final newText = text + '[$selectedPlaceholder] ';
                  _controller.text = newText;
                  setState(() {});
                },
              ),
              SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 150, // Set the width of the button
                  child: ElevatedButton(
                    onPressed: () {
                      Fluttertoast.showToast(msg: "Saved!");
                      // Pass the message template back to AdminMessageSetupPage
                      print(_controller.text);
                      Navigator.pop(context, _controller.text);
                    },
                    child: Text(
                      'Save Template',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ), // Set the font size of the button text
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Example color
                      padding: EdgeInsets.symmetric(
                          vertical: 10), // Set vertical padding
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
    _textFieldFocusNode.dispose(); // Dispose of the FocusNode
    _controller.dispose();
    super.dispose();
  }
}
