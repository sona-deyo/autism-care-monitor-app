import 'package:carebridge/components/square_tile.dart';
import 'package:carebridge/pages/Games/cognitive/cognitivehome.dart';
import 'package:carebridge/pages/Games/language/languagehome.dart';
import 'package:carebridge/pages/Games/sensorygame/sensoryhome.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GameHome extends StatelessWidget {
  const GameHome({super.key});
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
                        imagePath: 'lib/images/cognitive.png',
                        text: 'Cognitive Games',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Cognitivehome(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/sensory.png',
                        text: 'Sensory Games',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Sensoryhome(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/speech.png',
                        text: 'Language Games',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Languagehome(),
                            ),
                          );
                        },
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
