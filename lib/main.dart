import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'country_service.dart'; // Import the CountryService
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  String country = 'Unknown'; // Initialize country variable
  TextEditingController _nameController = TextEditingController(); // Controller for name input

  @override
  void initState() {
    super.initState();
    _startGame();
    _fetchCountry(); // Fetch country at the start of the game
  }

  // Fetch the user's country using CountryService
  void _fetchCountry() async {
    String fetchedCountry = await CountryService.fetchCountry();
    setState(() {
      country = fetchedCountry;
    });
  }

  // Start the game
  void _startGame() {
    // Timer to spawn balloons
    _balloonTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_gameLogic.gameOver) {
        setState(() {
          _gameLogic.spawnBalloon(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          );
        });
      }
    });

    // Timer to update balloon positions and merge them
    _movementTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      setState(() {
        _gameLogic.updateBalloonPositions(MediaQuery.of(context).size.height);
        _gameLogic.mergeBalloons();
      });
    });
  }

  // Save the score and user details to Firebase
  void _saveToFirebase() async {
    String playerName = _nameController.text.trim();
    int score = _gameLogic.score;

    // Check if the player entered a name
    if (playerName.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('players').add({
          'playerName': playerName,
          'score': score,
          'country': country,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Data saved successfully!'),
        ));
      } catch (e) {
        print('Error saving to Firestore: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving data!'),
        ));
      }
    }
  }

  @override
  void dispose() {
    _balloonTimer.cancel();
    _movementTimer.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blueAccent, Colors.deepPurpleAccent],
              ),
            ),
          ),
          // Score Display
          Positioned(
            top: 40,
            left: MediaQuery.of(context).size.width / 2 - 60,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Score: ${_gameLogic.score}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
          // Balloons
          for (var balloon in _gameLogic.balloons)
            Positioned(
              left: balloon.x,
              bottom: screenHeight - balloon.y - 80,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    balloon.x = (balloon.x + details.delta.dx)
                        .clamp(0.0, MediaQuery.of(context).size.width - _gameLogic.balloonSize);
                    balloon.y = (balloon.y + details.delta.dy)
                        .clamp(_gameLogic.reservedScoreHeight + _gameLogic.balloonSize,
                        MediaQuery.of(context).size.height - _gameLogic.balloonSize);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _gameLogic.mergeBalloons();
                  });
                },
                child: Container(
                  width: _gameLogic.balloonSize,
                  height: _gameLogic.balloonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [balloon.color.withOpacity(0.6), balloon.color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: balloon.color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      balloon.value.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          // Dynamic "Limit" Text
          Positioned(
            top: 120, // Positioned between the score and the line (Score top = 40, so 120 is a good position)
            left: MediaQuery.of(context).size.width / 2 - 60,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Limit: ${_gameLogic.limit}", // Display the dynamic limit
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
          // Stopping point line (positioned below the "Limit" text)
          Positioned(
            top: 193, // Positioned just below "Limit"
            left: 0,
            right: 0,
            child: Container(
              height: 5, // Thickness of the line
              color: Colors.red.withOpacity(0.8),
            ),
          ),
          // Game Over
          if (_gameLogic.gameOver)
            Center(
              child: AlertDialog(
                title: Text('Game Over'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Your score: ${_gameLogic.score}'),
                    SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Save the score, name, and country to Firebase
                      _saveToFirebase();
                      setState(() {
                        _gameLogic.resetGame();
                        _nameController.clear(); // Clear name input after submission
                      });
                    },
                    child: Text('Submit'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _gameLogic.resetGame();
                      });
                    },
                    child: Text('Restart'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
