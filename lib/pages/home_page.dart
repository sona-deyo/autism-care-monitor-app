import 'package:carebridge/components/square_tile.dart';
import 'package:carebridge/pages/CommunityForum/forum_home.dart';
import 'package:carebridge/pages/DailySchedule/daily_schedule.dart';
import 'package:carebridge/pages/Games/games_home.dart';
import 'package:carebridge/pages/GrowthMonitor/growth_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  String username = "Loading...";
  String childname = "Loading...";
  int age = 0;

  @override
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      getUserData();
    });
  }

  Future<void> getUserData() async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        print("User data retrieved: $data");
        int dobTimestamp = data['dob'] ?? 0;
        DateTime dob = DateTime.fromMillisecondsSinceEpoch(dobTimestamp);

        DateTime today = DateTime.now();
        int calculatedAge = today.year - dob.year;

        if (today.month < dob.month ||
            (today.month == dob.month && today.day < dob.day)) {
          calculatedAge--;
        }
        setState(() {
          username = data['username'] ?? "No Name";
          childname = data['childname'] ?? "No Child Name";
          age = calculatedAge;
        });

        print("Updated state: $username, $childname, $age");
      } else {
        print("User document does not exist in Firestore!");
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

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

      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            children: [
              DrawerHeader(
                child: Image.asset('lib/images/carebridge.jpg', height: 20),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: Image.asset('lib/images/gm.png', height: 40),
                title: Text('Growth Monitor', style: TextStyle(fontSize: 20)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GrowthMonitorHomePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: Image.asset('lib/images/ds.png', height: 40),
                title: Text('Daily Schedule', style: TextStyle(fontSize: 20)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => DailySchedule(
                            appName: '',
                            appUserModelId: '',
                            guid: '',
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: Image.asset('lib/images/game.png', height: 40),
                title: Text('Games', style: TextStyle(fontSize: 20)),
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => GameHome()));
                },
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: Image.asset('lib/images/cf.png', height: 40),
                title: Text('Community Forum', style: TextStyle(fontSize: 20)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommunityForumPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Name: $username",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Child's Name: $childname",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Child's Age: $age",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/gm.png',
                        text: 'Growth Monitor',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => GrowthMonitorHomePage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/ds.png',
                        text: 'Daily Schedule',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => DailySchedule(
                                    appName: '',
                                    appUserModelId: '',
                                    guid: '',
                                  ),
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
                        imagePath: 'lib/images/game.png',
                        text: 'Games',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => GameHome()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Flexible(
                      child: SquareTile(
                        imagePath: 'lib/images/cf.png',
                        text: 'Community Forum',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CommunityForumPage(),
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
