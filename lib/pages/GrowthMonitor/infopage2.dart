import 'package:flutter/material.dart';

class Infopage2 extends StatelessWidget {
  const Infopage2({super.key});

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
                  // Title
                  const Text(
                    'Understanding Your Child\'s Head Circumference Growth Using the WHO Chart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The WHO Head Circumference Growth Chart is used to monitor head growth for children aged 0-5 years. It helps assess brain development and detect any early neurological or developmental concerns.',
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
                    'What are Head Circumference Percentiles?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Head circumference percentiles compare your child’s head size to a standard population of children of the same age and gender.\n\n • 50th percentile: Your child’s head circumference is exactly average.\n\n • 85th percentile: Your child has a larger head circumference than 85% of children their age.\n\n • 15th percentile: Your child has a smaller head circumference than 85% of children their age.\n\n • 3rd percentile: Indicates a very small head size, which may require medical evaluation.\n\n • 97th percentile: Indicates a very large head size, which may require medical evaluation.',
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
                    'How to Interpret the Head Circumference Chart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The WHO chart includes smooth percentile curves (3rd, 15th, 50th, 85th, and 97th). Your child’s head circumference is plotted on this chart at each check-up to track growth over time. If head growth follows a steady percentile, it is typically normal. However, a sudden increase or decrease in percentile ranking may indicate a medical concern and should be discussed with a pediatrician.',
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
