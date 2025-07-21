import 'package:carebridge/components/square_tile.dart';
import 'package:carebridge/pages/Games/sensorygame/bublepop.dart';
import 'package:carebridge/pages/Games/sensorygame/shapetracing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Sensoryhome extends StatelessWidget {
  const Sensoryhome({super.key});
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
                        imagePath: 'lib/images/bubbles.png',
                        text: 'Pop the Bubble',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BubblePopPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/shapes.png',
                        text: 'Trace the shape',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ShapeTracingGame(),
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
