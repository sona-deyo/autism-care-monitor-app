import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ColorMatchingGame extends StatefulWidget {
  const ColorMatchingGame({super.key});

  @override
  State<ColorMatchingGame> createState() => _ColorMatchingGameState();
}

class _ColorMatchingGameState extends State<ColorMatchingGame> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final loggedInUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Map<Color, String> _colorNames = {
    Colors.red: 'RED',
    Colors.blue: 'BLUE',
    Colors.green: 'GREEN',
    Colors.yellow: 'YELLOW',
    Colors.orange: 'ORANGE',
    Colors.purple: 'PURPLE',
    Colors.pink: 'PINK',
    Colors.brown: 'BROWN',
  };

  late Color _targetColor;
  late List<Color> _options;
  String _feedback = '';
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _generateNewGame();
  }

  void _generateNewGame() {
    _targetColor = _colorNames.keys.elementAt(
      Random().nextInt(_colorNames.length),
    );

    List<Color> shuffledColors = List.of(_colorNames.keys)..shuffle();
    _options =
        shuffledColors.where((color) => color != _targetColor).take(3).toList();
    _options.add(_targetColor);
    _options.shuffle();

    _feedback = '';
    setState(() {});
  }

  Future<void> _saveScore() async {
    try {
      await _firestore
          .collection('users')
          .doc(loggedInUserId)
          .collection('game_history')
          .add({
            'game_type': 'colors',
            'score': _score,
            'timestamp': FieldValue.serverTimestamp(),
          });

      await _firestore.collection('scores').doc(loggedInUserId).set({
        'colors': _score,
      }, SetOptions(merge: true));
      if (mounted && context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void _checkAnswer(Color selectedColor) {
    setState(() {
      if (selectedColor == _targetColor) {
        _feedback = '✅ Correct!';
        _score += 10;

        if (_score >= 100) {
          Future.delayed(const Duration(seconds: 1), () {
            _saveScore();
          });
        } else {
          Future.delayed(const Duration(seconds: 1), _generateNewGame);
        }
      } else {
        _feedback = '❌ Try Again!';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text("Color Matching Game"),
        backgroundColor: Colors.blue[900],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Match the Color!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: _targetColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black, width: 3),
                ),
              ),
              const SizedBox(height: 30),

              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _score / 100,
                      minHeight: 15,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Score: $_score / 100",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              Wrap(
                spacing: 20,
                runSpacing: 20,
                children:
                    _options.map((color) {
                      return GestureDetector(
                        onTap: () => _checkAnswer(color),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          elevation: 5,
                          child: Container(
                            width: 120,
                            height: 120,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _colorNames[color]!,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 15),

              Text(
                _feedback,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color:
                      _feedback.contains('Correct') ? Colors.green : Colors.red,
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
                  backgroundColor: Colors.white,
                ),
                child: const Text("Save Score"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
