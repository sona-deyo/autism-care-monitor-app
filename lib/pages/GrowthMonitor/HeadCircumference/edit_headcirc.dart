import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditHeadCircfPage extends StatefulWidget {
  @override
  _EditHeadCircfPageState createState() => _EditHeadCircfPageState();
}

class _EditHeadCircfPageState extends State<EditHeadCircfPage> {
  DateTime? selectedDate;
  DateTime? dobDate;
  TextEditingController headcircumferenceController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadUserDOB();
  }

  Future<void> _loadUserDOB() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = user.uid;

      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      if (userData.containsKey('dob') && userData['dob'] != null) {
        var dobValue = userData['dob'];
        if (dobValue is Timestamp) {
          setState(() {
            dobDate = dobValue.toDate();
          });
        } else if (dobValue is int) {
          setState(() {
            dobDate = DateTime.fromMillisecondsSinceEpoch(dobValue);
          });
        } else if (dobValue is String) {}
      }
    } catch (e) {
      print("Error loading DOB: $e");
    }
  }

  Future<void> saveMeasurement() async {
    if (selectedDate == null || headcircumferenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a date and enter head circumference."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User not logged in"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = user.uid;

      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("User data not found"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      DateTime dob;
      if (!userData.containsKey('dob') || userData['dob'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Date of birth not found or invalid"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print("Debug - DOB value: ${userData['dob']}");

      try {
        var dobValue = userData['dob'];
        if (dobValue is Timestamp) {
          dob = dobValue.toDate();
        } else if (dobValue is int) {
          dob = DateTime.fromMillisecondsSinceEpoch(dobValue);
        } else if (dobValue is String) {
          try {
            dob = DateTime.parse(dobValue);
          } catch (e) {
            try {
              List<String> parts = dobValue.split('/');
              if (parts.length == 3) {
                dob = DateTime(
                  int.parse(parts[2]),
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                );
              } else {
                throw FormatException("Invalid date format");
              }
            } catch (e) {
              print("Error parsing date: $e");
              throw FormatException("Invalid date format");
            }
          }
        } else {
          throw FormatException("Invalid date type");
        }
      } catch (e) {
        print("Date parsing error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid date format: ${userData['dob']}"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      double ageInYears = selectedDate!.difference(dob).inDays / 365.25;
      Map<String, dynamic> existingHeadCircumferenceData = {};

      if (userData.containsKey('headcircumference_data') &&
          userData['headcircumference_data'] is Map) {
        userData['headcircumference_data'].forEach((key, value) {
          existingHeadCircumferenceData[key.toString()] =
              value is num ? value.toDouble() : 0.0;
        });
      }
      String dateKey = selectedDate!.toIso8601String();
      double headcircumferenceValue =
          double.tryParse(headcircumferenceController.text) ?? 0.0;
      existingHeadCircumferenceData[dateKey] = headcircumferenceValue;

      await firestore.collection('users').doc(userId).set({
        'headcircumference_data': existingHeadCircumferenceData,
        'latest_headcircumference_measurement': {
          'headcircumference': headcircumferenceValue,
          'age': ageInYears,
          'date': dateKey,
        },
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Measurement saved successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print("Error saving measurement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showDatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 380,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Select Date",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: SfDateRangePicker(
                  backgroundColor: Colors.white,
                  onSelectionChanged: (dateRangePickerSelectionChangedArgs) {
                    if (dateRangePickerSelectionChangedArgs.value is DateTime &&
                        !(dateRangePickerSelectionChangedArgs.value as DateTime)
                            .isAfter(DateTime.now())) {
                      setState(() {
                        selectedDate =
                            dateRangePickerSelectionChangedArgs.value;
                      });
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Cannot select a future date"),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  selectionMode: DateRangePickerSelectionMode.single,
                  maxDate: DateTime.now(),
                  minDate: dobDate,
                  monthCellStyle: DateRangePickerMonthCellStyle(
                    textStyle: TextStyle(color: Colors.black),
                    todayTextStyle: TextStyle(color: Colors.blue[900]),
                  ),
                  monthViewSettings: DateRangePickerMonthViewSettings(
                    viewHeaderStyle: DateRangePickerViewHeaderStyle(
                      textStyle: TextStyle(
                        color: Colors.blue[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  headerStyle: DateRangePickerHeaderStyle(
                    textStyle: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.white,
                  ),
                  selectionColor: Colors.blue[900],
                  todayHighlightColor: Colors.blue[900],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Edit Head Circumference"),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showDatePicker,
                  child: Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[900]!, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate == null
                              ? "Select Date"
                              : "Date: ${selectedDate!.toLocal().toString().split(' ')[0]}",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        Icon(Icons.calendar_today, color: Colors.blue[900]),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[900]!, width: 1.5),
                  ),
                  child: TextField(
                    controller: headcircumferenceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: "Enter Head Circumference (cm))",
                      labelStyle: TextStyle(color: Colors.black),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.person, color: Colors.blue[900]),
                    ),
                  ),
                ),
                SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saveMeasurement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: EdgeInsets.symmetric(vertical: 14),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Save Measurement",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
