import 'dart:math';
import 'dart:developer' as lg;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpeechTherapy extends StatefulWidget {
  const SpeechTherapy({super.key});

  @override
  State<SpeechTherapy> createState() => _SpeechTherapyState();
}

class _SpeechTherapyState extends State<SpeechTherapy> {
  SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  bool isListening = false;
  String recognizedWord = '';
  int score = 0;
  int currentWordIndex = 0;
  final Random _random = Random();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? loggedInUserId;

  List<String> wordList = [
    'Water',
    'Apple',
    'Happy',
    'Elephant',
    'Friend',
    'Sunshine',
    'Guitar',
    'Laptop',
    'Dinosaur',
    'Rainbow',
    'Butterfly',
    'Chocolate',
    'Galaxy',
    'Pencil',
    'Mountain',
    'Football',
    'Telescope',
    'Kangaroo',
    'Strawberry',
    'Library',
    'Helicopter',
    'Adventure',
    'Candle',
    'Bicycle',
    'Telephone',
    'Puzzle',
    'Treasure',
    'Parrot',
    'Rocket',
    'Painting',
    'Cupcake',
    'Pineapple',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _shuffleWords();
    _fetchUserId();
  }

  Future<void> _fetchUserId() async {
    this.loggedInUserId = FirebaseAuth.instance.currentUser?.uid;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _shuffleWords() {
    wordList.shuffle(_random);
  }

  void _initSpeech() async {
    speechEnabled = await speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    setState(() {
      recognizedWord = '';
      isListening = true;
    });

    await speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 3),
    );

    Future.delayed(const Duration(seconds: 3), () {
      _stopListening();
    });
  }

  Future<void> _saveScore() async {
    if (loggedInUserId == null) {
      lg.log("User ID is null. Cannot save score.");
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Unable to save score. Please login again.'),
          ),
        );
      }
      return;
    }

    try {
      await firestore
          .collection('users')
          .doc(loggedInUserId)
          .collection('game_history')
          .add({
            'game_type': 'speech',
            'score': score,
            'timestamp': FieldValue.serverTimestamp(),
          });

      await firestore.collection('scores').doc(loggedInUserId).set({
        'speech': score,
      }, SetOptions(merge: true));

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Score saved successfully!')),
        );
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.of(context).pop(score);
      }
    } catch (e) {
      lg.log("Error saving score: ${e.toString()}");
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving score: ${e.toString()}')),
        );
      }
    }
  }

  void _stopListening() async {
    await speechToText.stop();
    _compareWords();
    setState(() {
      isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      recognizedWord = result.recognizedWords;
    });
  }

  void _compareWords() async {
    String targetWord = wordList[currentWordIndex];

    if (recognizedWord.toLowerCase().trim() ==
        targetWord.toLowerCase().trim()) {
      setState(() {
        score += 10;
        currentWordIndex = (currentWordIndex + 1) % wordList.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String targetWord = wordList[currentWordIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Speech Therapy"),
        backgroundColor: Colors.blue[900],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Score",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$score",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Say this word:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      targetWord,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isListening ? null : _startListening,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child:
                  isListening
                      ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("Listening...", style: TextStyle(fontSize: 18)),
                        ],
                      )
                      : const Text(
                        "Start Listening",
                        style: TextStyle(fontSize: 18),
                      ),
            ),

            const SizedBox(height: 30),

            Text(
              "You said: $recognizedWord",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color:
                    recognizedWord.isNotEmpty
                        ? Colors.blueAccent
                        : Colors.black,
              ),
            ),
            const SizedBox(height: 40),
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
                  color: Colors.white,
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
