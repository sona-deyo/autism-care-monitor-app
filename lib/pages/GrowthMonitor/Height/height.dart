import 'package:carebridge/pages/GrowthMonitor/Height/edit_height.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carebridge/pages/GrowthMonitor/infopage.dart';

class Height extends StatefulWidget {
  @override
  _HeightState createState() => _HeightState();
}

class _HeightState extends State<Height> {
  double latestHeight = 0;
  double latestAge = 0;
  String latestPercentile = "-";
  List<FlSpot> height3rdPercentile = [];
  List<FlSpot> height10thPercentile = [];
  List<FlSpot> height25thPercentile = [];
  List<FlSpot> height50thPercentile = [];
  List<FlSpot> height75thPercentile = [];
  List<FlSpot> height90thPercentile = [];
  List<FlSpot> height97thPercentile = [];
  List<FlSpot> userHeightData = [];
  bool isLoadingChartData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await fetchGrowthChartData();
    await fetchUserHeightData();
  }

  Future<void> fetchUserHeightData() async {
    userHeightData.clear();

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = user.uid;

      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> heightData = userData['height_data'] ?? {};
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
      Map<String, double> dateToHeightMap = {};

      heightData.forEach((dateStr, height) {
        DateTime measurementDate = DateTime.parse(dateStr);
        double ageAtMeasurement =
            measurementDate.difference(dob).inDays / 365.25;
        double heightValue = (height as num).toDouble();

        tempUserData.add(FlSpot(ageAtMeasurement, heightValue));
        dateToHeightMap[dateStr] = heightValue;
      });

      tempUserData.sort((a, b) => a.x.compareTo(b.x));

      if (tempUserData.isNotEmpty) {
        FlSpot latestMeasurement = tempUserData.last;

        String percentile = "-";
        if (!isLoadingChartData && height50thPercentile.isNotEmpty) {
          percentile = calculatePercentile(
            latestMeasurement.x,
            latestMeasurement.y,
          );
        }

        setState(() {
          userHeightData = tempUserData;
          latestAge = latestMeasurement.x;
          latestHeight = latestMeasurement.y;
          latestPercentile = percentile;
        });
      } else {
        setState(() {
          userHeightData = [];
          latestAge = 0;
          latestHeight = 0;
          latestPercentile = "-";
        });
      }
    } catch (e) {
      print("Error fetching user height data: $e");
    }
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
        Map<String, dynamic> genderData = fullData[genderKey]["height"] ?? {};

        List<FlSpot> temp3rd = [];
        List<FlSpot> temp10th = [];
        List<FlSpot> temp25th = [];
        List<FlSpot> temp50th = [];
        List<FlSpot> temp75th = [];
        List<FlSpot> temp90th = [];
        List<FlSpot> temp97th = [];

        genderData.forEach((ageKey, value) {
          double age = double.tryParse(ageKey) ?? 0.0;

          temp3rd.add(FlSpot(age, (value["3rd"] as num).toDouble()));
          temp10th.add(FlSpot(age, (value["10th"] as num).toDouble()));
          temp25th.add(FlSpot(age, (value["25th"] as num).toDouble()));
          temp50th.add(FlSpot(age, (value["50th"] as num).toDouble()));
          temp75th.add(FlSpot(age, (value["75th"] as num).toDouble()));
          temp90th.add(FlSpot(age, (value["90th"] as num).toDouble()));
          temp97th.add(FlSpot(age, (value["97th"] as num).toDouble()));
        });

        temp3rd.sort((a, b) => a.x.compareTo(b.x));
        temp10th.sort((a, b) => a.x.compareTo(b.x));
        temp25th.sort((a, b) => a.x.compareTo(b.x));
        temp50th.sort((a, b) => a.x.compareTo(b.x));
        temp75th.sort((a, b) => a.x.compareTo(b.x));
        temp90th.sort((a, b) => a.x.compareTo(b.x));
        temp97th.sort((a, b) => a.x.compareTo(b.x));

        setState(() {
          height3rdPercentile = temp3rd;
          height10thPercentile = temp10th;
          height25thPercentile = temp25th;
          height50thPercentile = temp50th;
          height75thPercentile = temp75th;
          height90thPercentile = temp90th;
          height97thPercentile = temp97th;
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

  String calculatePercentile(double age, double height) {
    List<MapEntry<String, double>> percentileHeights = [];

    double closestAge = 0;
    double minAgeDiff = double.infinity;

    for (var spot in height50thPercentile) {
      double diff = (spot.x - age).abs();
      if (diff < minAgeDiff) {
        minAgeDiff = diff;
        closestAge = spot.x;
      }
    }
    for (var spot in height3rdPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeights.add(MapEntry('3rd', spot.y));
      }
    }

    for (var spot in height10thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeights.add(MapEntry('10th', spot.y));
      }
    }

    for (var spot in height25thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeights.add(MapEntry('25th', spot.y));
      }
    }

    for (var spot in height50thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeights.add(MapEntry('50th', spot.y));
      }
    }

    for (var spot in height75thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeights.add(MapEntry('75th', spot.y));
      }
    }

    for (var spot in height90thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeights.add(MapEntry('90th', spot.y));
      }
    }

    for (var spot in height97thPercentile) {
      if ((spot.x - closestAge).abs() < 0.01) {
        percentileHeights.add(MapEntry('97th', spot.y));
      }
    }

    percentileHeights.sort((a, b) => a.value.compareTo(b.value));

    if (percentileHeights.length < 2) return "-";
    if (height < percentileHeights.first.value) return "<3rd";
    if (height >= percentileHeights.last.value) return ">97th";

    for (int i = 0; i < percentileHeights.length - 1; i++) {
      if (height >= percentileHeights[i].value &&
          height < percentileHeights[i + 1].value) {
        return "${percentileHeights[i].key}-${percentileHeights[i + 1].key}";
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
                "Height: ${latestHeight.toStringAsFixed(1)} cm",
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
                  MaterialPageRoute(builder: (context) => EditHeightPage()),
                );

                if (result == true) {
                  fetchUserHeightData();
                }
              },
            ),
          ),
        ],
      ),
    );
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
                MaterialPageRoute(builder: (context) => Infopage1()),
              );
            },
          ),
        ],
      ),

      body:
          height50thPercentile.isEmpty
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
                              interval: 20,
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
                              interval: 2,
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

                        minY: 40,
                        maxY: 160,
                        minX: 0,
                        maxX: 10,
                        lineBarsData: [
                          lineChartData(
                            height3rdPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            height10thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            height25thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            height50thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            height75thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            height90thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          lineChartData(
                            height97thPercentile,
                            const Color.fromARGB(255, 75, 40, 27),
                          ),
                          LineChartBarData(
                            spots: userHeightData,
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
