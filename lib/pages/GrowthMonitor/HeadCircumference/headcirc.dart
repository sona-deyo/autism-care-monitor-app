import 'package:carebridge/pages/GrowthMonitor/HeadCircumference/edit_headcirc.dart';
import 'package:carebridge/pages/GrowthMonitor/infopage2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HeadCircf extends StatefulWidget {
  @override
  _HeadCircfState createState() => _HeadCircfState();
}

class _HeadCircfState extends State<HeadCircf> {
  double latestHeadCircumference = 0;
  double latestAge = 0;
  String latestPercentile = "-";
  List<FlSpot> headcircumference3rdPercentile = [];
  List<FlSpot> headcircumference15thPercentile = [];
  List<FlSpot> headcircumference50thPercentile = [];
  List<FlSpot> headcircumference85thPercentile = [];
  List<FlSpot> headcircumference97thPercentile = [];
  List<FlSpot> userHeadCircumferenceData = [];
  bool isLoadingChartData = true;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await fetchGrowthChartData();
    await fetchUserHeadCircumferenceData();
  }

  Future<void> fetchUserHeadCircumferenceData() async {
    userHeadCircumferenceData.clear();

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = user.uid;

      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> weightData =
          userData['headcircumference_data'] ?? {};
      DateTime dob;
      var dobValue = userData['dob'];
      if (dobValue is int) {
        dob = DateTime.fromMillisecondsSinceEpoch(dobValue);
      } else if (dobValue is String) {
        dob = DateTime.parse(dobValue);
      } else {
        dob = DateTime.now();
        print("Warning: Unable to parse DOB, using current date as fallback");
      }

      List<FlSpot> tempUserData = [];
      Map<String, double> dateToHeadCircumferenceMap = {};

      weightData.forEach((dateStr, weight) {
        DateTime measurementDate = DateTime.parse(dateStr);
        double ageAtMeasurement =
            measurementDate.difference(dob).inDays / 365.25;
        double headCircumferenceValue = (weight as num).toDouble();

        tempUserData.add(FlSpot(ageAtMeasurement, headCircumferenceValue));
        dateToHeadCircumferenceMap[dateStr] = headCircumferenceValue;
      });

      tempUserData.sort((a, b) => a.x.compareTo(b.x));

      if (tempUserData.isNotEmpty) {
        FlSpot latestMeasurement = tempUserData.last;

        String percentile = "-";
        if (!isLoadingChartData && headcircumference50thPercentile.isNotEmpty) {
          percentile = calculatePercentile(
            latestMeasurement.x,
            latestMeasurement.y,
          );
        }

        setState(() {
          userHeadCircumferenceData = tempUserData;
          latestAge = latestMeasurement.x;
          latestHeadCircumference = latestMeasurement.y;
          latestPercentile = percentile;
        });
      } else {
        setState(() {
          userHeadCircumferenceData = [];
          latestAge = 0;
          latestHeadCircumference = 0;
          latestPercentile = "-";
        });
      }
    } catch (e) {
      print("Error fetching user weight data: $e");
    }
  }

  String calculatePercentile(double age, double headcircumference) {
    List<MapEntry<String, double>> percentileHeadCircumference = [];

    double closestAge = 0;
    double minAgeDiff = double.infinity;

    for (var spot in headcircumference50thPercentile) {
      double diff = (spot.x - age).abs();
      if (diff < minAgeDiff) {
        minAgeDiff = diff;
        closestAge = spot.x;
      }
    }

    for (var spot in headcircumference3rdPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeadCircumference.add(MapEntry('3rd', spot.y));
      }
    }

    for (var spot in headcircumference15thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeadCircumference.add(MapEntry('15th', spot.y));
      }
    }

    for (var spot in headcircumference50thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeadCircumference.add(MapEntry('50th', spot.y));
      }
    }

    for (var spot in headcircumference85thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeadCircumference.add(MapEntry('85th', spot.y));
      }
    }

    for (var spot in headcircumference97thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeadCircumference.add(MapEntry('97th', spot.y));
      }
    }

    percentileHeadCircumference.sort((a, b) => a.value.compareTo(b.value));

    if (percentileHeadCircumference.length < 2) return "-";

    if (headcircumference < percentileHeadCircumference.first.value)
      return "<3rd";
    if (headcircumference >= percentileHeadCircumference.last.value)
      return ">97th";

    for (int i = 0; i < percentileHeadCircumference.length - 1; i++) {
      if (headcircumference >= percentileHeadCircumference[i].value &&
          headcircumference < percentileHeadCircumference[i + 1].value) {
        return "${percentileHeadCircumference[i].key}-${percentileHeadCircumference[i + 1].key}";
      }
    }

    return "~50th";
  }

  String formatAge(double ageInYears) {
    int years = ageInYears.floor();
    int months = ((ageInYears - years) * 12).round();

    if (months == 12) {
      years += 1;
      months = 0;
    }

    if (years == 0) {
      return "$months months";
    } else if (months == 0) {
      return "$years years";
    } else {
      return "$years years $months months";
    }
  }

  Widget measurementContainer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Age: ${formatAge(latestAge)}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Head Circ.: ${latestHeadCircumference.toStringAsFixed(1)} cm",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                "Percentile: ${latestPercentile}",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ],
          ),

          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.blue[900]),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditHeadCircfPage()),
                );

                if (result == true) {
                  fetchUserHeadCircumferenceData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchGrowthChartData() async {
    setState(() {
      isLoadingChartData = true;
    });
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = user.uid;

      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String gender = userData['gender'] ?? 'male';
      DocumentSnapshot snapshot =
          await firestore
              .collection('growth_charts')
              .doc('IAP_Height_Weight')
              .get();

      if (snapshot.exists) {
        Map<String, dynamic> fullData = snapshot.data() as Map<String, dynamic>;
        String genderKey = gender.toLowerCase() == 'female' ? 'girls' : 'boys';
        Map<String, dynamic> genderData =
            fullData[genderKey]["head circumference"] ?? {};
        List<FlSpot> temp3rd = [];
        List<FlSpot> temp15th = [];
        List<FlSpot> temp50th = [];
        List<FlSpot> temp85th = [];
        List<FlSpot> temp97th = [];

        genderData.forEach((ageKey, value) {
          double age = double.tryParse(ageKey) ?? 0.0;

          temp3rd.add(FlSpot(age, (value["3rd"] as num).toDouble()));
          temp15th.add(FlSpot(age, (value["15th"] as num).toDouble()));
          temp50th.add(FlSpot(age, (value["50th"] as num).toDouble()));
          temp85th.add(FlSpot(age, (value["85th"] as num).toDouble()));
          temp97th.add(FlSpot(age, (value["97th"] as num).toDouble()));
        });

        temp3rd.sort((a, b) => a.x.compareTo(b.x));
        temp15th.sort((a, b) => a.x.compareTo(b.x));
        temp50th.sort((a, b) => a.x.compareTo(b.x));
        temp85th.sort((a, b) => a.x.compareTo(b.x));
        temp97th.sort((a, b) => a.x.compareTo(b.x));

        setState(() {
          headcircumference3rdPercentile = temp3rd;
          headcircumference15thPercentile = temp15th;
          headcircumference50thPercentile = temp50th;
          headcircumference85thPercentile = temp85th;
          headcircumference97thPercentile = temp97th;
          isLoadingChartData = false;
        });
      }
    } catch (e) {
      print("Error fetching growth chart data: $e");

      setState(() {
        isLoadingChartData = false;
      });
    }
  }

  void refreshData() async {
    await _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    refreshData();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Growth Monitoring"),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.info, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Infopage2()),
              );
            },
          ),
        ],
      ),

      body:
          headcircumference50thPercentile.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    height: screenHeight * 0.66,
                    padding: const EdgeInsets.all(16.0),
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 2,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}',
                                  style: TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(color: Colors.black, width: 0.5),
                            bottom: BorderSide(color: Colors.black, width: 1),
                          ),
                        ),
                        gridData: FlGridData(show: true),

                        minY: 32,
                        maxY: 55,
                        minX: 0,
                        maxX: 5,
                        lineBarsData: [
                          lineChartData(
                            headcircumference3rdPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            headcircumference15thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            headcircumference50thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            headcircumference85thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            headcircumference97thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          LineChartBarData(
                            spots: userHeadCircumferenceData,
                            isCurved: true,
                            color: const Color.fromARGB(255, 7, 16, 75),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: Colors.black,
                                  strokeWidth: 1,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  measurementContainer(),
                ],
              ),
    );
  }

  LineChartBarData lineChartData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      belowBarData: BarAreaData(show: false),
      dotData: FlDotData(show: false),
      gradient: LinearGradient(
        colors: [
          Colors.deepPurple.withAlpha(95),
          Colors.purple.withAlpha(95),
          Colors.lightBlueAccent.withAlpha(95),
        ],
      ),
    );
  }
}
