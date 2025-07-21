import 'dart:math';
import 'dart:developer' as lg;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShapeMatchingGame extends StatefulWidget {
  const ShapeMatchingGame({super.key});

  @override
  State<ShapeMatchingGame> createState() => _ShapeMatchingGameState();
}

class _ShapeMatchingGameState extends State<ShapeMatchingGame>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _shapeData = [
    {'shape': 'Circle', 'icon': Icons.circle, 'color': Colors.blue},
    {'shape': 'Square', 'icon': Icons.square, 'color': Colors.red},
    {'shape': 'Triangle', 'icon': Icons.change_history, 'color': Colors.green},
    {'shape': 'Star', 'icon': Icons.star, 'color': Colors.yellow},
    {'shape': 'Heart', 'icon': Icons.favorite, 'color': Colors.pink},
    {'shape': 'Diamond', 'icon': Icons.diamond, 'color': Colors.orange},
  ];

  late Map<String, dynamic> _targetShape;
  late List<Map<String, dynamic>> _options;
  String _feedback = '';
  int _score = 0;
  late AnimationController _controller;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _generateNewGame();
  }

  void _generateNewGame() {
    _targetShape = _shapeData[Random().nextInt(_shapeData.length)];
    List<Map<String, dynamic>> shuffledShapes = List.of(_shapeData)..shuffle();
    _options =
        shuffledShapes
            .where((s) => s['shape'] != _targetShape['shape'])
            .take(3)
            .toList();
    _options.add(_targetShape);
    _options.shuffle();

    _feedback = '';
    setState(() {});
  }

  void _checkAnswer(Map<String, dynamic> selectedShape) {
    if (selectedShape['shape'] == _targetShape['shape']) {
      setState(() {
        _feedback = '✅ Correct!';
        _score = (_score + 10).clamp(0, 100);
      });

      _controller.forward(from: 0);

      if (_score >= 100) {
        Future.delayed(const Duration(seconds: 1), () {
          _saveScore();
        });
      } else {
        Future.delayed(const Duration(seconds: 1), _generateNewGame);
      }
    } else {
      setState(() {
        _feedback = '❌ Try Again!';
      });
      _controller.forward(from: 0);
    }
  }

  Future<void> _saveScore() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('game_history')
          .add({
            'game_type': 'shape',
            'score': _score,
            'timestamp': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('scores').doc(user.uid).set({
        'shape': _score,
      }, SetOptions(merge: true));

      lg.log("success");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score saved successfully!')),
      );
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      lg.log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shape Matching Game"),
        backgroundColor: Colors.blue[900],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent.shade100, Colors.blue.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Match the Shape!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _score / 100,
                    backgroundColor: Colors.white70,
                    color: Colors.greenAccent,
                    minHeight: 12,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Score: $_score / 100",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Icon(
                _targetShape['icon'],
                size: 80,
                color: _targetShape['color'],
              ),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 20,
              runSpacing: 20,
              children:
                  _options.map((shapeData) {
                    return GestureDetector(
                      onTap: () => _checkAnswer(shapeData),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              shapeData['icon'],
                              size: 60,
                              color: shapeData['color'],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              shapeData['shape'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 30),

            FadeTransition(
              opacity: _controller,
              child: Text(
                _feedback,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:
                      _feedback.contains('Correct')
                          ? Colors.greenAccent
                          : Colors.redAccent,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _saveScore,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.blue[900],
              ),
              child: const Text(
                "Save Score",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
