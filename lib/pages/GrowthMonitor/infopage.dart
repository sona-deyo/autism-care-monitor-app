import 'package:flutter/material.dart';

class Infopage1 extends StatelessWidget {
  const Infopage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Info Page',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Understanding Your Child\'s Growth Using the IAP-WHO Growth Chart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The IAP-WHO Growth Chart is a standardized tool that helps track a child\'s height and weight from birth to 10 years. It combines data from the Indian Academy of Pediatrics (IAP) and the World Health Organization (WHO) to provide accurate percentiles for children based on their age, gender, height, and weight.',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'What are Growth Percentiles?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Growth percentiles indicate how your child’s measurements compare to a standard population of children of the same age and gender.\n\n • 50th percentile: Your child is exactly average, meaning half of the children their age are taller or heavier, and half are shorter or lighter.\n\n • 75th percentile: Your child is taller or heavier than 75% of children their age.\n\n • 25th percentile: Your child is shorter or lighter than 75% of children their age.\n\n •10th percentile: Your child is smaller or lighter than 90% of children their age.\n\n •90th percentile: Your child is taller or heavier than 90% of children their age.\n\n • 3rd percentile: Represents the lowest healthy range, meaning 97% of children are taller or heavier.\n\n • 97th percentile: Indicates only 3% of children are taller or heavier, suggesting they are significantly above average.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.clip,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How to Interpret the Growth Chart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The chart contains smooth percentile curves (3rd, 15th, 50th, 85th, and 97th) representing expected growth patterns. Your child\'s height and weight measurements are plotted on this chart to track their progress. If your child consistently follows a certain percentile, it indicates steady growth. A drastic drop or increase may require medical attention. Not all children follow the 50th percentile; normal growth ranges from the 3rd to 97th percentile, and healthy children can grow at different rates.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.clip,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
