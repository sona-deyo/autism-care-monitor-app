import 'package:carebridge/components/square_tile.dart';
import 'package:carebridge/pages/Games/cognitive/colourmatching.dart';
import 'package:carebridge/pages/Games/cognitive/shapematching.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Cognitivehome extends StatelessWidget {
  const Cognitivehome({super.key});
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
                    Padding(padding: EdgeInsets.all(10)),
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/color-wheel.png',
                        text: 'Colour Matching',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ColorMatchingGame(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/shapes.png',
                        text: 'Shape Matching',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ShapeMatchingGame(),
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
