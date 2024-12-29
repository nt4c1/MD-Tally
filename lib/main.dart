import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'country_service.dart'; // Import the CountryService
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart'; // Import HomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: HomePage())); // Set HomePage as the initial screen
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameLogic _gameLogic = GameLogic();
  late Timer _balloonTimer;
  late Timer _movementTimer;
  bool _isPaused = false;
  String country = 'Unknown';
  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startGame();
    _fetchCountry();
  }

  void _fetchCountry() async {
    String fetchedCountry = await CountryService.fetchCountry();
    setState(() {
      country = fetchedCountry;
    });
  }

  void _startGame() {
    // Timer to spawn balloons periodically
    _balloonTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_gameLogic.gameOver && !_isPaused) {
        setState(() {
          _gameLogic.spawnBalloon(
            MediaQuery
                .of(context)
                .size
                .width,
            MediaQuery
                .of(context)
                .size
                .height,
          );
        });
      }
    });

    // Timer to update positions and merge balloons
    _movementTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      if (!_isPaused){
      setState(() {
        _gameLogic.updateBalloonPositions(MediaQuery
            .of(context)
            .size
            .height);
        _gameLogic.mergeBalloons();
      });
    }});
  }
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;  // Toggle the paused state
    });
  }
  // Add this method to navigate to the HomePage
  void _goToHomepage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }



  void _saveToFirebase() async {
    String playerName = _nameController.text.trim();
    int score = _gameLogic.score;

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
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBackground(),
          ),
          // Background Gradient
          Positioned(
              top: 50,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: AnimatedText(
                  text: 'Spirit Tube',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
    ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _togglePause,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.lightBlue.shade300, Colors.indigo.shade900],
              ),
            ),
          ),

          // Score Display
          Positioned(
            top: 40,
            left: MediaQuery
                .of(context)
                .size
                .width / 2 - 80,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Score: ${_gameLogic.score}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),

          //Pause Button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _togglePause,
            ),
          ),
          // Limit Display
          Positioned(
            top: 100,
            left: MediaQuery
                .of(context)
                .size
                .width / 2 - 80,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Limit: ${_gameLogic.limit}",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            top: 193, // Positioned just below "Limit"
            left: 0,
            right: 0,
            child: Container(
              height: 5, // Thickness of the line
              color: Colors.red.withOpacity(0.8),
            ),
          ),
          // Balloons
          ..._gameLogic.balloons.map((balloon) {
            return Positioned(
              left: balloon.x,
              bottom: screenHeight - balloon.y - _gameLogic.balloonSize,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    balloon.x = (balloon.x + details.delta.dx)
                        .clamp(0.0, MediaQuery.of(context).size.width - _gameLogic.balloonSize);
                    balloon.y = (balloon.y + details.delta.dy).clamp(_gameLogic.reservedScoreHeight + _gameLogic.balloonSize,
                        MediaQuery.of(context).size.height - _gameLogic.balloonSize);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _gameLogic.mergeBalloons();
                  });
                },
                onDoubleTap: () {
                  if (balloon is PowerUpBalloon) {
                    PowerUpBalloon powerUpBalloon = balloon as PowerUpBalloon;
                    setState(() {
                      _gameLogic.triggerPowerUpEffect(powerUpBalloon); // Call the effect
                    });
                  }
                },
                child: Container(
                  width: _gameLogic.balloonSize,
                  height: _gameLogic.balloonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: balloon is PowerUpBalloon
                        ? LinearGradient(colors: [
                      Colors.yellowAccent,
                      Colors.orangeAccent
                    ])
                        : LinearGradient(
                      colors: [balloon.color.withOpacity(0.7), balloon.color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: balloon is PowerUpBalloon
                        ? Icon(
                      _gameLogic.getPowerUpIcon(balloon.effect),
                      color: Colors.white,
                      size: 28,
                    )
                        : Text(
                      balloon.value.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

          // Game Over Dialog
          if (_gameLogic.gameOver)
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Game Over',
                      style: TextStyle(fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    SizedBox(height: 10),
                    Text('Your score: ${_gameLogic.score}',
                        style: TextStyle(fontSize: 20)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                      ),
                    ),
                    SizedBox(height: 15),
                    CustomButton(label: 'Submit', onPressed: _saveToFirebase),
                    CustomButton(label: 'Restart', onPressed: _gameLogic.resetGame),
                    CustomButton(label: 'Go to Homepage', onPressed: _goToHomepage),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}