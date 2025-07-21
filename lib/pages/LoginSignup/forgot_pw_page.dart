import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carebridge/components/my_textfield.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(content: Text("Password reset sent link!!"));
        },
      );
    } on FirebaseAuthException catch (e) {
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Center(
              child: Text(
                e.message.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue[900], elevation: 0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Text(
              "Enter the email to send the password reset link",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
          ),
          SizedBox(height: 10),
          MyTextField(
            controller: emailController,
            hintText: 'Email',
            obscureText: false,
          ),
          SizedBox(height: 10),
          MaterialButton(
            onPressed: () async {
              await passwordReset();
            },
            color: Colors.white,
            child: Text("Reset Password"),
          ),
        ],
      ),
    );
  }
}
