import 'package:carebridge/components/square_tile.dart';
import 'package:carebridge/pages/Games/language/speechtherapy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Languagehome extends StatelessWidget {
  const Languagehome({super.key});
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue[900],
        elevation: 0,
        title: Text("CAREBRIDGE", style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [IconButton(onPressed: signUserOut, icon: Icon(Icons.logout))],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/talking.png',
                        text: 'TalkTrek',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => SpeechTherapy(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
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
