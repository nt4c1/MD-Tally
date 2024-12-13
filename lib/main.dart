import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'game_logic.dart'; // Import game logic

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameLogic _gameLogic = GameLogic();
  late Timer _balloonTimer;
  late Timer _movementTimer;
  String? _playerName;
  String? _country;

  @override
  void initState() {
    super.initState();
    _fetchCountry(); // Fetch the player's country
    _startGame();
  }

  void _fetchCountry() async {
    try {
      final response = await http.get(Uri.parse('https://api.country.is'));
      if (response.statusCode == 200) {
        setState(() {
          _country = json.decode(response.body)['country'];
        });
      } else {
        print("Failed to fetch country");
      }
    } catch (e) {
      print("Error fetching country: $e");
    }
  }

  void _startGame() {
    _balloonTimer = Timer.periodic(Duration(milliseconds: _getSpawnRate()), (timer) {
      if (!_gameLogic.gameOver) {
        setState(() {
          _gameLogic.spawnBalloon(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
        });
      }
    });

    _movementTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      setState(() {
        double screenHeight = MediaQuery.of(context).size.height;
        _gameLogic.updateBalloonPositions(screenHeight);
        _gameLogic.mergeBalloons();
      });
    });
  }

  int _getSpawnRate() {
    int baseSpawnRate = 500; // Initial rate (faster spawn)
    int maxSpawnDelay = 1500; // Maximum delay (slower spawn)

    // Calculate spawn rate based on score, but reduce its effect
    int spawnRate = baseSpawnRate + (_gameLogic.score / 8).toInt(); // Slower spawn over time

    // Clamp to ensure the spawn rate doesn't get too slow or too fast
    return spawnRate.clamp(baseSpawnRate, maxSpawnDelay);
  }



  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Spirit Tube', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blueAccent, Colors.deepPurpleAccent],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Text(
              'Score: ${_gameLogic.score}',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          for (var balloon in _gameLogic.balloons)
            Positioned(
              left: balloon.x - 40,
              bottom: balloon.y - 40,
              child: Draggable(
                key: Key(balloon.value.toString()),
                feedback: _buildBalloon(balloon),
                childWhenDragging: Container(),
                onDragEnd: (details) {
                  setState(() {
                    balloon.x = details.offset.dx;
                    balloon.y = screenHeight - details.offset.dy - 80.0;
                    _gameLogic.handleDrag(balloon, balloon.x, balloon.y, screenHeight); // Call handleDrag
                    _gameLogic.mergeBalloons();
                  });
                },
                child: _buildBalloon(balloon),
              ),
            ),
          if (_gameLogic.gameOver) _gameOverOverlay(context),
        ],
      ),
    );
  }

  Widget _buildBalloon(Balloon balloon) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [balloon.color.withOpacity(0.7), balloon.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 5,
            offset: Offset(5, 5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: BalloonPainter(balloon: balloon),
      ),
    );
  }

  Widget _gameOverOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game Over!',
              style: TextStyle(fontSize: 40, color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'Score: ${_gameLogic.score}',
              style: TextStyle(fontSize: 30, color: Colors.white),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter your name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _playerName = value;
                });
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (_playerName != null && _playerName!.isNotEmpty) {
                  _saveScore();
                  setState(() {
                    _gameLogic.score = 0;
                    _gameLogic.balloons.clear();
                    _gameLogic.gameOver = false;
                    _startGame();
                  });
                }
              },
              child: Text('Restart'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveScore() async {
    // Save the score to Firestore
    FirebaseFirestore.instance.collection('scores').add({
      'name': _playerName,
      'score': _gameLogic.score,
      'country': _country,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class BalloonPainter extends CustomPainter {
  final Balloon balloon;

  BalloonPainter({required this.balloon});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = balloon.color;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40.0, paint);

    // Draw value text
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '${balloon.value}',
        style: TextStyle(fontSize: 30, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
