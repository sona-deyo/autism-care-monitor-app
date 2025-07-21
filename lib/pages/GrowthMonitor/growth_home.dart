import 'package:carebridge/pages/GrowthMonitor/Game/gamemonitor.dart';
import 'package:carebridge/pages/GrowthMonitor/HeadCircumference/headcirc.dart';
import 'package:carebridge/pages/GrowthMonitor/Height/height.dart';
import 'package:carebridge/pages/GrowthMonitor/Weight/weight.dart';
import 'package:flutter/material.dart';

class GrowthMonitorHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Growth Monitor", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            MonitorOption(
              imagepath: 'lib/images/height.png',
              title: "Height",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Height()),
                );
              },
            ),
            SizedBox(height: 20),
            MonitorOption(
              imagepath: 'lib/images/weight.png',
              title: "Weight",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Weight()),
                );
              },
            ),
            SizedBox(height: 20),
            MonitorOption(
              imagepath: 'lib/images/head.png',
              title: "Head Circumference",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HeadCircf()),
                );
              },
            ),
            SizedBox(height: 20),
            MonitorOption(
              imagepath: 'lib/images/game.png',
              title: "Game Monitor",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GameMonitor()),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class MonitorOption extends StatelessWidget {
  final String imagepath;
  final String title;
  final VoidCallback onTap;
  MonitorOption({
    required this.imagepath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(imagepath, height: 50),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
