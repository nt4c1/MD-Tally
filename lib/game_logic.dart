import 'dart:math';
import 'package:flutter/material.dart';

class Balloon {
  double x; // Horizontal position
  double y; // Vertical position
  final double speed; // Balloon speed
  int value; // Balloon value
  final Color color; // Balloon color

  Balloon({
    required this.x,
    required this.y,
    required this.speed,
    required this.value,
    required this.color,
  });
}

class GameLogic {
  List<Balloon> balloons = [];
  bool gameOver = false;
  int score = 0;

  final double balloonSize = 80.0; // Diameter of the balloons
  final double reservedScoreHeight = 120.0; // Height reserved for the score display

  /// Spawns a balloon at the bottom of the screen
  void spawnBalloon(double screenWidth, double screenHeight) {
    final random = Random();

    if (!gameOver) {
      final balloonX = random.nextDouble() * (screenWidth - balloonSize); // Random horizontal position
      final balloonY = screenHeight - balloonSize; // Spawn near the bottom

      balloons.add(Balloon(
        x: balloonX,
        y: balloonY,
        speed: random.nextDouble() * 1.5 + 1, // Speed between 1 and 2.5
        color: Color.fromARGB(
          255,
          random.nextInt(256),
          random.nextInt(256),
          random.nextInt(256),
        ),
        value: random.nextInt(10) + 1,
      ));
    }
  }

  /// Updates the position of balloons, making them move upwards
  void updateBalloonPositions(double screenHeight) {
    int stoppedBalloons = 0;

    for (var balloon in balloons) {
      if (balloon.y > reservedScoreHeight + balloonSize) {
        balloon.y -= balloon.speed; // Move upwards
      } else {
        stoppedBalloons++; // Count balloons stopped at the stopping point
      }
    }

    // Trigger game-over if more than 10 balloons are at the stopping point
    if (stoppedBalloons > 10) {
      gameOver = true;
    }
  }

  /// Handles the merging of balloons with the same value
  void mergeBalloons() {
    for (int i = 0; i < balloons.length; i++) {
      for (int j = i + 1; j < balloons.length; j++) {
        if ((balloons[i].x - balloons[j].x).abs() < balloonSize &&
            (balloons[i].y - balloons[j].y).abs() < balloonSize &&
            balloons[i].value == balloons[j].value) {
          balloons[i].value += balloons[j].value;
          balloons.removeAt(j);
          score += balloons[i].value;
          break;
        }
      }
    }
  }

  /// Resets the game state
  void resetGame() {
    balloons.clear();
    score = 0;
    gameOver = false;
  }
}
