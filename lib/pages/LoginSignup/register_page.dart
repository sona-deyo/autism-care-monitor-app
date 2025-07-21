import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carebridge/components/my_button.dart';
import 'package:carebridge/components/my_textfield.dart';
import 'package:intl/intl.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  final usernameController = TextEditingController();
  final childnameController = TextEditingController();
  String? selectedGender;
  DateTime? selectedDate;
  final TextEditingController dobController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  void signUserUp() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      if (passwordController.text != confirmpasswordController.text) {
        Navigator.pop(context);
        showErrorMessage("Passwords don't match");
        return;
      }

      // ignore: unused_local_variable
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      Navigator.pop(context);

      int dobTimestamp = selectedDate!.millisecondsSinceEpoch;

      await addUserDetails(
        usernameController.text.trim(),
        emailController.text.trim(),
        childnameController.text.trim(),
        dobTimestamp,
        selectedGender ?? 'Not specified',
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      showErrorMessage(e.code);
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Center(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Future<void> addUserDetails(
    String username,
    String email,
    String childname,
    int dobTimestamp,
    String gender,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      await docRef.set({
        'username': username,
        'email': email,
        'childname': childname,
        'dob': dobTimestamp,
        'gender': gender,
      });

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception("Data was not stored in Firestore");
      }

      print("User registered successfully in Firestore!");
    } catch (e) {
      print("Error adding user details to Firestore: $e");
      showErrorMessage("Error saving user data: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Image.asset('lib/images/carebridge.jpg', height: 70),
                SizedBox(width: 10),
                Text(
                  'Create an Account',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),

                const SizedBox(height: 10),
                MyTextField(
                  controller: usernameController,
                  hintText: 'username',
                  obscureText: false,
                ),
                const SizedBox(height: 5),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),

                const SizedBox(height: 5),
                MyTextField(
                  controller: childnameController,
                  hintText: 'Child\'s name',
                  obscureText: false,
                ),

                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 5,
                  ),
                  child: TextField(
                    controller: dobController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: "Child's DOB",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.grey[500],
                      ),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(height: 5),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 5,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        dropdownColor: Colors.grey.shade200,
                        isExpanded: true,
                        hint: Text(
                          "Child's Gender",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),

                        value: selectedGender,
                        icon: const Icon(Icons.arrow_drop_down),
                        elevation: 16,
                        borderRadius: BorderRadius.circular(4),
                        style: const TextStyle(color: Colors.black),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedGender = newValue;
                          });
                        },
                        items:
                            <String>[
                              'Male',
                              'Female',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),

                const SizedBox(height: 5),

                MyTextField(
                  controller: confirmpasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),

                const SizedBox(height: 5),

                MyButton(text: "Sign Up", onTap: signUserUp),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.black, fontSize: 17),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Login now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
