import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameMonitor extends StatefulWidget {
  const GameMonitor({super.key});

  @override
  State<GameMonitor> createState() => _GameMonitorState();
}

extension DateTimeExtension on DateTime {
  DateTime startOfDay() {
    return DateTime(year, month, day, 0, 0, 0, 0, 0);
  }

  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999, 999);
  }
}

class _GameMonitorState extends State<GameMonitor> {
  double speechScore = 0.0;
  double shapeScore = 0.0;
  double colorsScore = 0.0;
  double tracingScore = 0.0;
  double bubblepopScore = 0.0;
  bool isLoading = true;
  bool hasData = false;
  DateTime selectedWeek = DateTime.now();
  Map<String, List<Map<String, dynamic>>> weeklyData = {};

  @override
  void initState() {
    super.initState();
    selectedWeek = DateTime.now();
    selectedWeek =
        selectedWeek
            .subtract(Duration(days: selectedWeek.weekday - 1))
            .startOfDay();
    fetchWeeklyData();
  }

  Future<void> fetchWeeklyData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final mondayOfWeek =
          selectedWeek
              .subtract(Duration(days: selectedWeek.weekday - 1))
              .startOfDay();
      final nextMonday = mondayOfWeek.add(const Duration(days: 7));
      final startTimestamp = Timestamp.fromDate(mondayOfWeek);
      final endTimestamp = Timestamp.fromDate(nextMonday);

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('game_history')
              .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
              .where('timestamp', isLessThan: endTimestamp)
              .get();

      Map<String, List<Map<String, dynamic>>> groupedData = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final gameType = data['game_type'];
        if (!groupedData.containsKey(gameType)) {
          groupedData[gameType] = [];
        }
        groupedData[gameType]!.add(data);
      }

      setState(() {
        weeklyData = groupedData;
        hasData = groupedData.isNotEmpty;
        if (groupedData.containsKey('colors')) {
          final colorGames = groupedData['colors']!;
          final total = colorGames.fold(
            0.0,
            (sum, game) => sum + (game['score'] as num),
          );
          colorsScore =
              colorGames.isEmpty ? 0.0 : (total / colorGames.length) / 100;
        } else {
          colorsScore = 0.0;
        }
        if (groupedData.containsKey('speech')) {
          final speechGames = groupedData['speech']!;
          final total = speechGames.fold(
            0.0,
            (sum, game) => sum + (game['score'] as num),
          );
          speechScore =
              speechGames.isEmpty ? 0.0 : (total / speechGames.length) / 100;
        } else {
          speechScore = 0.0;
        }
        if (groupedData.containsKey('shape')) {
          final shapeGames = groupedData['shape']!;
          final total = shapeGames.fold(
            0.0,
            (sum, game) => sum + (game['score'] as num),
          );
          shapeScore =
              shapeGames.isEmpty ? 0.0 : (total / shapeGames.length) / 100;
        } else {
          shapeScore = 0.0;
        }
        if (groupedData.containsKey('tracing')) {
          final tracingGames = groupedData['tracing']!;
          final total = tracingGames.fold(
            0.0,
            (sum, game) => sum + (game['score'] as num),
          );
          tracingScore =
              tracingGames.isEmpty ? 0.0 : (total / tracingGames.length) / 100;
        } else {
          tracingScore = 0.0;
        }
        if (groupedData.containsKey('bubbles')) {
          final bubbleGames = groupedData['bubbles']!;
          final total = bubbleGames.fold(
            0.0,
            (sum, game) => sum + (game['score'] as num),
          );
          bubblepopScore =
              bubbleGames.isEmpty ? 0.0 : (total / bubbleGames.length) / 100;
        } else {
          bubblepopScore = 0.0;
        }
      });
    } catch (e) {
      log("Error fetching weekly data: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildWeekSelector() {
    final mondayOfWeek =
        selectedWeek
            .subtract(Duration(days: selectedWeek.weekday - 1))
            .startOfDay();
    // ignore: unused_local_variable
    final sundayOfWeek = mondayOfWeek.add(const Duration(days: 6));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final previousMonday = mondayOfWeek.subtract(
              const Duration(days: 7),
            );
            setState(() {
              selectedWeek = previousMonday;
              fetchWeeklyData();
            });
          },
        ),
        Text(
          "Week of ${mondayOfWeek.month}/${mondayOfWeek.day}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            final nextMonday = mondayOfWeek.add(const Duration(days: 7));
            if (nextMonday.isBefore(DateTime.now())) {
              setState(() {
                selectedWeek = nextMonday;
                fetchWeeklyData();
              });
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Game Monitor",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
      ),
      body: Center(
        child:
            isLoading
                ? const CircularProgressIndicator()
                : hasData
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    buildWeekSelector(),
                    const SizedBox(height: 5),
                    const Text(
                      "Your Performance Overview",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildStatCard(
                            "Speech Therapy",
                            speechScore,
                            Colors.blueAccent,
                          ),
                          buildStatCard(
                            "Shape Matching",
                            shapeScore,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildStatCard(
                            "Color Matching",
                            colorsScore,
                            Colors.redAccent,
                          ),
                          buildStatCard(
                            "Tracing Shape",
                            tracingScore,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildStatCard(
                            "Bubble Pop",
                            bubblepopScore,
                            const Color.fromARGB(217, 243, 113, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildWeekSelector(),
                    const SizedBox(height: 20),
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "No scores to display. \nPlay games to see the score",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget buildStatCard(String title, double percentage, Color color) {
    return Container(
      width: 150,
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 8.0,
            percent: percentage.clamp(0.0, 1.0),
            center: Text(
              "${(percentage * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            progressColor: color,
            backgroundColor: Colors.grey.shade300,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
