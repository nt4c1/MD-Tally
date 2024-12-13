import 'dart:async';
import 'package:flutter/material.dart';
import 'game_logic.dart';

void main() {
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

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
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

    _movementTimer = Timer.periodic(Duration(milliseconds: 30), (timer) {
      setState(() {
        _gameLogic.updateBalloonPositions(MediaQuery.of(context).size.height);
        _gameLogic.mergeBalloons();
      });
    });
  }

  @override
  void dispose() {
    _balloonTimer.cancel();
    _movementTimer.cancel();
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
          // Game Over
          if (_gameLogic.gameOver)
            Center(
              child: AlertDialog(
                title: Text('Game Over'),
                content: Text('Your score: ${_gameLogic.score}'),
                actions: [
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