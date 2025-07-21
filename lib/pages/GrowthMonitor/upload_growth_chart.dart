import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadGrowthChartData() async {
  try {
    String jsonString = await rootBundle.loadString(
      'assets/iap_growth_chart.json',
    );
    Map<String, dynamic> growthChartData = json.decode(jsonString);

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference chartsCollection = firestore.collection(
      'growth_charts',
    );

    await chartsCollection.doc("IAP_Height_Weight").set(growthChartData);

    print("Growth chart data uploaded successfully!");
  } catch (e) {
    print("Error uploading growth chart: $e");
  }
}
