import 'dart:developer' as lg;
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const MaterialApp(
      home: ShapeTracingGame(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class ShapeTracingGame extends StatefulWidget {
  const ShapeTracingGame({super.key});

  @override
  _ShapeTracingGameState createState() => _ShapeTracingGameState();
}

class _ShapeTracingGameState extends State<ShapeTracingGame>
    with SingleTickerProviderStateMixin {
  List<Offset> userPath = [];
  List<List<Offset>> userStrokes = [];
  List<Offset> expectedPath = [];
  String selectedShape = "Pentagon";
  int score = 0;
  double progress = 0.0;
  bool shapeCompleted = false;
  bool isDrawing = false;
  final List<String> shapes = [
    "Circle",
    "Square",
    "Triangle",
    "Hexagon",
    "Pentagon",
    "Star",
  ];
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final loggedInUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  late AnimationController _animationController;
  late Animation<double> _animation;
  final Color backgroundColor = const Color.fromARGB(255, 177, 26, 203);
  final Color primaryColor = Colors.white;
  final Color accentColor = const Color(0xFFFFD700);
  Map<String, bool> segmentsTraced = {};
  List<Rect> segmentBounds = [];
  Map<int, String> vertexDecorations = {};
  List<Color> segmentColors = [];
  List<PatternType> segmentPatterns = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      generateExpectedPath();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _assignDecorations() {
    vertexDecorations.clear();
    segmentColors.clear();
    segmentPatterns.clear();

    final random = Random();
    int vertexCount = selectedShape == "Circle" ? 8 : segmentBounds.length;
    if (selectedShape == "Pentagon") {
      vertexDecorations[1] = "star";
    } else {
      vertexDecorations[random.nextInt(vertexCount)] = "star";
    }
    if (selectedShape == "Circle") {
      for (int i = 0; i < 130; i++) {
        segmentColors.add(Colors.amber);
        segmentPatterns.add(PatternType.none);
      }
    } else {
      for (int i = 0; i < segmentBounds.length; i++) {
        segmentColors.add(Colors.amber);
        segmentPatterns.add(PatternType.none);
      }
    }
  }

  Future<void> _saveScore() async {
    try {
      await firestore
          .collection('users')
          .doc(loggedInUserId)
          .collection('game_history')
          .add({
            'game_type': 'tracing',
            'score': score,
            'shape': selectedShape,
            'timestamp': FieldValue.serverTimestamp(),
          });
      await firestore.collection('scores').doc(loggedInUserId).set({
        'tracing': score,
      }, SetOptions(merge: true));

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

  void generateExpectedPath() {
    expectedPath.clear();
    segmentBounds.clear();
    segmentsTraced.clear();
    progress = 0.0;
    shapeCompleted = false;

    switch (selectedShape) {
      case "Circle":
        double radius = 120;
        Offset center = Offset(MediaQuery.of(context).size.width / 2, 200);
        for (double i = 0; i < 2 * pi; i += 0.05) {
          expectedPath.add(
            Offset(center.dx + radius * cos(i), center.dy + radius * sin(i)),
          );
        }
        for (int i = 0; i < 8; i++) {
          String segmentKey = 'circle_segment_$i';
          segmentsTraced[segmentKey] = false;
          double startAngle = i * pi / 4;
          double endAngle = (i + 1) * pi / 4;
          Offset startPoint = Offset(
            center.dx + radius * cos(startAngle),
            center.dy + radius * sin(startAngle),
          );
          Offset endPoint = Offset(
            center.dx + radius * cos(endAngle),
            center.dy + radius * sin(endAngle),
          );
          double padding = 30;
          Rect boundingRect = Rect.fromLTRB(
            min(startPoint.dx, endPoint.dx) - padding,
            min(startPoint.dy, endPoint.dy) - padding,
            max(startPoint.dx, endPoint.dx) + padding,
            max(startPoint.dy, endPoint.dy) + padding,
          );

          segmentBounds.add(boundingRect);
        }
        break;

      case "Square":
        double size = 220;
        double left = (MediaQuery.of(context).size.width - size) / 2;
        double top = 100;

        expectedPath = [
          Offset(left, top),
          Offset(left + size, top),
          Offset(left + size, top + size),
          Offset(left, top + size),
          Offset(left, top),
        ];
        for (int i = 0; i < 4; i++) {
          String segmentKey = 'square_side_$i';
          segmentsTraced[segmentKey] = false;

          Offset start = expectedPath[i];
          Offset end = expectedPath[i + 1];
          double padding = 20;
          Rect boundingRect = Rect.fromLTRB(
            min(start.dx, end.dx) - padding,
            min(start.dy, end.dy) - padding,
            max(start.dx, end.dx) + padding,
            max(start.dy, end.dy) + padding,
          );

          segmentBounds.add(boundingRect);
        }
        break;

      case "Triangle":
        double size = 200;
        double height = size * sin(pi / 3);
        double centerX = MediaQuery.of(context).size.width / 2;

        expectedPath = [
          Offset(centerX, 80),
          Offset(centerX + size / 2, 80 + height),
          Offset(centerX - size / 2, 80 + height),
          Offset(centerX, 80),
        ];
        for (int i = 0; i < 3; i++) {
          String segmentKey = 'triangle_side_$i';
          segmentsTraced[segmentKey] = false;

          Offset start = expectedPath[i];
          Offset end = expectedPath[i + 1];

          double padding = 20;
          Rect boundingRect = Rect.fromLTRB(
            min(start.dx, end.dx) - padding,
            min(start.dy, end.dy) - padding,
            max(start.dx, end.dx) + padding,
            max(start.dy, end.dy) + padding,
          );

          segmentBounds.add(boundingRect);
        }
        break;

      case "Hexagon":
        double radius = 120;
        Offset center = Offset(MediaQuery.of(context).size.width / 2, 200);

        for (int i = 0; i <= 6; i++) {
          double angle = i * pi / 3 - pi / 6;
          expectedPath.add(
            Offset(
              center.dx + radius * cos(angle),
              center.dy + radius * sin(angle),
            ),
          );
        }

        for (int i = 0; i < 6; i++) {
          String segmentKey = 'hexagon_side_$i';
          segmentsTraced[segmentKey] = false;

          Offset start = expectedPath[i];
          Offset end = expectedPath[i + 1];
          double padding = 20;
          Rect boundingRect = Rect.fromLTRB(
            min(start.dx, end.dx) - padding,
            min(start.dy, end.dy) - padding,
            max(start.dx, end.dx) + padding,
            max(start.dy, end.dy) + padding,
          );

          segmentBounds.add(boundingRect);
        }
        break;

      case "Pentagon":
        double radius = 120;
        Offset center = Offset(MediaQuery.of(context).size.width / 2, 200);
        for (int i = 0; i <= 5; i++) {
          double angle = i * 2 * pi / 5 - pi / 2;
          expectedPath.add(
            Offset(
              center.dx + radius * cos(angle),
              center.dy + radius * sin(angle),
            ),
          );
        }

        for (int i = 0; i < 5; i++) {
          String segmentKey = 'pentagon_side_$i';
          segmentsTraced[segmentKey] = false;

          Offset start = expectedPath[i];
          Offset end = expectedPath[i + 1];
          double padding = 20;
          Rect boundingRect = Rect.fromLTRB(
            min(start.dx, end.dx) - padding,
            min(start.dy, end.dy) - padding,
            max(start.dx, end.dx) + padding,
            max(start.dy, end.dy) + padding,
          );

          segmentBounds.add(boundingRect);
        }
        break;

      case "Star":
        double outerRadius = 120;
        double innerRadius = 46;
        Offset center = Offset(MediaQuery.of(context).size.width / 2, 200);

        for (int i = 0; i < 5; i++) {
          double outerAngle = i * 2 * pi / 5 - pi / 2;
          double innerAngle = outerAngle + pi / 5;

          expectedPath.add(
            Offset(
              center.dx + outerRadius * cos(outerAngle),
              center.dy + outerRadius * sin(outerAngle),
            ),
          );

          expectedPath.add(
            Offset(
              center.dx + innerRadius * cos(innerAngle),
              center.dy + innerRadius * sin(innerAngle),
            ),
          );
        }

        expectedPath.add(expectedPath.first);
        for (int i = 0; i < 10; i++) {
          String segmentKey = 'star_segment_$i';
          segmentsTraced[segmentKey] = false;
          Offset start = expectedPath[i];
          Offset end = expectedPath[(i + 1) % expectedPath.length];
          double padding = 20;
          Rect boundingRect = Rect.fromLTRB(
            min(start.dx, end.dx) - padding,
            min(start.dy, end.dy) - padding,
            max(start.dx, end.dx) + padding,
            max(start.dy, end.dy) + padding,
          );

          segmentBounds.add(boundingRect);
        }
        break;
    }

    for (int i = 0; i < segmentBounds.length; i++) {
      String segmentKey = _getSegmentKey(i);
      segmentsTraced[segmentKey] = false;
    }
    _assignDecorations();
  }

  void _nextShape() {
    int currentIndex = shapes.indexOf(selectedShape);
    int nextIndex = (currentIndex + 1) % shapes.length;

    setState(() {
      selectedShape = shapes[nextIndex];
      _resetGame();
    });
  }

  void _resetGame() {
    userPath.clear();
    userStrokes.clear();
    generateExpectedPath();
  }

  void _startDrawing(Offset position) {
    setState(() {
      isDrawing = true;
      userPath = [position];
    });
  }

  void _continueDrawing(Offset position) {
    if (!isDrawing) return;

    setState(() {
      userPath.add(position);
      _checkSegmentsCovered(position);
      _updateProgress();
    });
  }

  void _endDrawing() {
    if (!isDrawing) return;

    setState(() {
      isDrawing = false;
      if (userPath.isNotEmpty) {
        userStrokes.add(List.from(userPath));
      }
    });
  }

  void _checkSegmentsCovered(Offset point) {
    if (shapeCompleted) return;

    for (int i = 0; i < segmentBounds.length; i++) {
      String key = _getSegmentKey(i);
      if (segmentsTraced[key] == true) continue;
      if (segmentBounds[i].contains(point)) {
        if (selectedShape == "Circle") {
          if (_isPointNearCircleSegment(point, i)) {
            segmentsTraced[key] = true;
          }
        } else {
          if (_isPointNearSegment(point, i)) {
            segmentsTraced[key] = true;
          }
        }
      }
    }
  }

  bool _isPointNearSegment(Offset point, int segmentIndex) {
    if (segmentIndex >= expectedPath.length - 1) return false;

    Offset start = expectedPath[segmentIndex];
    Offset end = expectedPath[segmentIndex + 1];

    return _isPointNearLineSegment(point, start, end, 5);
  }

  bool _isPointNearCircleSegment(Offset point, int octantIndex) {
    Offset center = Offset(MediaQuery.of(context).size.width / 2, 200);
    double radius = 120;
    double angle = atan2(point.dy - center.dy, point.dx - center.dx);
    if (angle < 0) angle += 2 * pi;
    double distance = (point - center).distance;
    bool isNearRadius = (distance > radius - 25) && (distance < radius + 25);
    double octantStartAngle = octantIndex * pi / 4;
    double octantEndAngle = (octantIndex + 1) * pi / 4;
    if (octantIndex == 7) {
      return isNearRadius &&
          ((angle >= octantStartAngle) || (angle <= octantEndAngle - 2 * pi));
    }

    bool isInOctant = (angle >= octantStartAngle) && (angle <= octantEndAngle);

    return isNearRadius && isInOctant;
  }

  bool _isPointNearLineSegment(
    Offset point,
    Offset lineStart,
    Offset lineEnd,
    double threshold,
  ) {
    double lineLength = (lineEnd - lineStart).distance;
    if (lineLength == 0) return (point - lineStart).distance < threshold;
    double t =
        ((point.dx - lineStart.dx) * (lineEnd.dx - lineStart.dx) +
            (point.dy - lineStart.dy) * (lineEnd.dy - lineStart.dy)) /
        (lineLength * lineLength);

    t = max(0, min(1, t));
    Offset projection = Offset(
      lineStart.dx + t * (lineEnd.dx - lineStart.dx),
      lineStart.dy + t * (lineEnd.dy - lineStart.dy),
    );

    return (point - projection).distance < threshold;
  }

  String _getSegmentKey(int index) {
    switch (selectedShape) {
      case "Circle":
        return 'circle_segment_$index';
      case "Square":
        return 'square_side_$index';
      case "Triangle":
        return 'triangle_side_$index';
      case "Hexagon":
        return 'hexagon_side_$index';
      case "Pentagon":
        return 'pentagon_side_$index';
      case "Star":
        return 'star_segment_$index';
      default:
        return 'segment_$index';
    }
  }

  void _updateProgress() {
    int tracedCount = 0;
    int totalSegments = 0;
    for (int i = 0; i < segmentBounds.length; i++) {
      String key = _getSegmentKey(i);
      if (segmentsTraced.containsKey(key)) {
        totalSegments++;
        if (segmentsTraced[key] == true) {
          tracedCount++;
        }
      }
    }

    if (totalSegments == 0) return;

    double newProgress = tracedCount / totalSegments;

    setState(() {
      progress = newProgress;
      if (tracedCount == totalSegments &&
          totalSegments > 0 &&
          !shapeCompleted) {
        shapeCompleted = true;
        score += 10;
        _confettiController.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Shape Tracing Game",
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
      ),
      body: Stack(
        children: [
          CustomPaint(
            painter: BackgroundPatternPainter(Colors.blue),
            size: Size.infinite,
          ),

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),

                      child: DropdownButton<String>(
                        value: selectedShape,
                        dropdownColor: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                        icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                        style: TextStyle(color: Colors.black, fontSize: 16),
                        underline: Container(),

                        items:
                            shapes.map((String shape) {
                              return DropdownMenuItem<String>(
                                value: shape,
                                child: Text(shape),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedShape = value;
                              _resetGame();
                            });
                          }
                        },
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _nextShape,
                          icon: Icon(Icons.skip_next, color: primaryColor),
                          label: Text(
                            "Next",
                            style: TextStyle(color: primaryColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              userPath.clear();
                              userStrokes.clear();
                              _resetGame();
                            });
                          },
                          icon: Icon(Icons.refresh, color: Colors.white),
                          label: Text(
                            "Clear",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: GestureDetector(
                  onPanStart: (details) {
                    _startDrawing(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    _continueDrawing(details.localPosition);
                  },
                  onPanEnd: (_) {
                    _endDrawing();
                  },
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: EnhancedShapePainter(
                          userPath: userPath,
                          userStrokes: userStrokes,
                          expectedPath: expectedPath,
                          segmentBounds: segmentBounds,
                          segmentsTraced: segmentsTraced,
                          selectedShape: selectedShape,
                          vertexDecorations: vertexDecorations,
                          segmentColors: segmentColors,
                          segmentPatterns: segmentPatterns,
                          animationValue: _animation.value,
                        ),
                        size: Size.infinite,
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirectionality: BlastDirectionality.explosive,
                            numberOfParticles: 30,
                            colors: const [
                              Colors.red,
                              Colors.green,
                              Colors.blue,
                              Colors.yellow,
                              Colors.pink,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Score: $score",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _saveScore,
                          icon: const Icon(Icons.save),
                          label: const Text("Save Score"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(
                                Colors.orangeAccent,
                                Colors.greenAccent,
                                progress,
                              ) ??
                              Colors.greenAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shapeCompleted
                          ? "Shape completed! +10 points"
                          : "Trace the entire shape (${(progress * 100).toInt()}%)",
                      style: TextStyle(
                        color:
                            shapeCompleted
                                ? Colors.greenAccent
                                : primaryColor.withOpacity(0.8),
                        fontWeight:
                            shapeCompleted
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum PatternType { none, dots, stripes, hearts, stars, zigzag }

class BackgroundPatternPainter extends CustomPainter {
  final Color backgroundColor;

  BackgroundPatternPainter(this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    Paint bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    Paint patternPaint =
        Paint()
          ..color = Colors.purpleAccent.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    double radius = size.width / 8;

    for (double x = -radius; x <= size.width + radius; x += radius * 2) {
      for (double y = -radius; y <= size.height + radius; y += radius * 2) {
        canvas.drawCircle(Offset(x, y), radius, patternPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class EnhancedShapePainter extends CustomPainter {
  final List<Offset> userPath;
  final List<List<Offset>> userStrokes;
  final List<Offset> expectedPath;
  final List<Rect> segmentBounds;
  final Map<String, bool> segmentsTraced;
  final String selectedShape;
  final Map<int, String> vertexDecorations;
  final List<Color> segmentColors;
  final List<PatternType> segmentPatterns;
  final double animationValue;

  EnhancedShapePainter({
    required this.userPath,
    required this.userStrokes,
    required this.expectedPath,
    required this.segmentBounds,
    required this.segmentsTraced,
    required this.selectedShape,
    required this.vertexDecorations,
    required this.segmentColors,
    required this.segmentPatterns,
    required this.animationValue,
  });

  @override
  @override
  void paint(Canvas canvas, Size size) {
    final Paint expectedPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    if (expectedPath.length > 1) {
      for (int i = 0; i < expectedPath.length - 1; i++) {
        int segmentIndex = i;
        if (selectedShape == "Star" && i >= segmentColors.length) {
          segmentIndex = i % segmentColors.length;
        }
        Color segmentColor =
            (segmentIndex < segmentColors.length)
                ? segmentColors[segmentIndex]
                : Colors.grey.withOpacity(0.6);
        PatternType pattern =
            (segmentIndex < segmentPatterns.length)
                ? segmentPatterns[segmentIndex]
                : PatternType.none;
        final Path segmentPath =
            Path()
              ..moveTo(expectedPath[i].dx, expectedPath[i].dy)
              ..lineTo(expectedPath[i + 1].dx, expectedPath[i + 1].dy);

        expectedPaint.color = segmentColor;
        canvas.drawPath(segmentPath, expectedPaint);
        _drawPatternOnSegment(
          canvas,
          expectedPath[i],
          expectedPath[i + 1],
          pattern,
          segmentColor,
        );
        String key = _getSegmentKey(segmentIndex);
        bool isTraced = segmentsTraced[key] == true;
        if (isTraced) {
          final Rect bounds = Rect.fromPoints(
            expectedPath[i],
            expectedPath[i + 1],
          );
          final gradient = LinearGradient(
            colors: [
              Colors.transparent,
              Colors.yellowAccent.withOpacity(0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          );

          Paint glowPaint =
              Paint()
                ..shader = gradient.createShader(bounds)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 15.0
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
                ..strokeCap = StrokeCap.round;

          canvas.drawLine(expectedPath[i], expectedPath[i + 1], glowPaint);
        }
      }
    }
    vertexDecorations.forEach((vertexIndex, decoration) {
      if (vertexIndex < expectedPath.length) {
        Offset vertexPosition = expectedPath[vertexIndex];
        _drawVertexDecoration(canvas, vertexPosition, decoration);
      }
    });
    final Paint userPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    for (final List<Offset> stroke in userStrokes) {
      if (stroke.length > 1) {
        final Path path = Path();
        path.moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, userPaint);
      }
    }
    if (userPath.length > 1) {
      final Path currentPath = Path();
      currentPath.moveTo(userPath[0].dx, userPath[0].dy);
      for (int i = 1; i < userPath.length; i++) {
        currentPath.lineTo(userPath[i].dx, userPath[i].dy);
      }
      final Rect pathBounds = currentPath.getBounds();
      final double gradientPos = animationValue;

      final LinearGradient strokeGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(255, 2, 55, 99),
          const Color.fromARGB(255, 31, 98, 158),
          const Color.fromARGB(255, 124, 21, 55),
          const Color.fromARGB(255, 107, 17, 122),
          const Color.fromARGB(255, 15, 74, 123),
        ],
        stops: [
          (gradientPos - 0.3).clamp(0.0, 1.0),
          (gradientPos - 0.1).clamp(0.0, 1.0),
          gradientPos,
          (gradientPos + 0.1).clamp(0.0, 1.0),
          (gradientPos + 0.3).clamp(0.0, 1.0),
        ],
      );
      userPaint
        ..shader = strokeGradient.createShader(pathBounds)
        ..strokeWidth = 8.0;
      canvas.drawPath(currentPath, userPaint);
      final Paint glowPaint =
          Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 15.0
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

      canvas.drawPath(currentPath, glowPaint);
    }
  }

  void _drawPatternOnSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    PatternType pattern,
    Color color,
  ) {
    if (pattern == PatternType.none) return;

    final Paint patternPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double length = sqrt(dx * dx + dy * dy);
    if (length < 10) return;
    dx /= length;
    dy /= length;
    double perpX = -dy;
    double perpY = dx;
    double spacing = 0;
    switch (pattern) {
      case PatternType.dots:
        spacing = 20.0;
        break;
      case PatternType.stripes:
        spacing = 10.0;
        break;
      case PatternType.hearts:
      case PatternType.stars:
        spacing = 30.0;
        break;
      case PatternType.zigzag:
        spacing = 15.0;
        break;
      default:
        return;
    }
    int count = (length / spacing).floor();
    if (count <= 0) count = 1;
    for (int i = 0; i <= count; i++) {
      double t = i / count;
      double x = start.dx + dx * length * t;
      double y = start.dy + dy * length * t;

      switch (pattern) {
        case PatternType.dots:
          canvas.drawCircle(Offset(x, y), 3.0, patternPaint);
          break;
        case PatternType.stripes:
          canvas.drawLine(
            Offset(x - perpX * 5, y - perpY * 5),
            Offset(x + perpX * 5, y + perpY * 5),
            patternPaint
              ..strokeWidth = 2.0
              ..style = PaintingStyle.stroke,
          );
          break;
        case PatternType.stars:
          _drawStarShape(canvas, Offset(x, y), 6.0, patternPaint);
          break;
        case PatternType.zigzag:
          if (i > 0 && i < count) {
            double zigzagWidth = 5.0;
            double zigzagHeight = (i % 2 == 0) ? zigzagWidth : -zigzagWidth;
            canvas.drawCircle(
              Offset(x + perpX * zigzagHeight, y + perpY * zigzagHeight),
              2.0,
              patternPaint,
            );
          }
          break;
        default:
          break;
      }
    }
  }

  void _drawStarShape(Canvas canvas, Offset center, double size, Paint paint) {
    Path starPath = Path();

    final double outerRadius = size;
    final double innerRadius = size * 0.4;

    for (int i = 0; i < 5; i++) {
      double outerAngle = i * 2 * pi / 5 - pi / 2;
      double innerAngle = outerAngle + pi / 5;

      double outerX = center.dx + cos(outerAngle) * outerRadius;
      double outerY = center.dy + sin(outerAngle) * outerRadius;

      double innerX = center.dx + cos(innerAngle) * innerRadius;
      double innerY = center.dy + sin(innerAngle) * innerRadius;

      if (i == 0) {
        starPath.moveTo(outerX, outerY);
      } else {
        starPath.lineTo(outerX, outerY);
      }

      starPath.lineTo(innerX, innerY);
    }

    starPath.close();
    canvas.drawPath(starPath, paint);
  }

  void _drawVertexDecoration(
    Canvas canvas,
    Offset position,
    String decorationType,
  ) {
    switch (decorationType) {
      case "star":
        final Paint starPaint =
            Paint()
              ..color = Colors.yellow
              ..style = PaintingStyle.fill;
        _drawStarShape(canvas, position, 20.0, starPaint);
        break;
    }
  }

  String _getSegmentKey(int index) {
    switch (selectedShape) {
      case "Circle":
        return 'circle_segment_$index';
      case "Square":
        return 'square_side_$index';
      case "Triangle":
        return 'triangle_side_$index';
      case "Hexagon":
        return 'hexagon_side_$index';
      case "Pentagon":
        return 'pentagon_side_$index';
      case "Star":
        return 'star_segment_$index';
      default:
        return 'segment_$index';
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
