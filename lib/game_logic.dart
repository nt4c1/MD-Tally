import 'dart:math';
import 'package:flutter/material.dart';

class Balloon {
  double x;
  double y;
  int value;
  final Color color;
  bool isStopped = false;
  double tailLength = 15.0;

  Balloon({
    required this.x,
    required this.y,
    required this.value,
    required this.color,
  });
}

class GameLogic {
  List<Balloon> balloons = [];
  bool gameOver = false;
  int score = 0;
  final int maxBalloons = 30;

  // Spawn balloons with a slight offset to the right
  void spawnBalloon(double screenWidth, double screenHeight) {
    if (balloons.length >= maxBalloons) {
      gameOver = true; // Game over condition
      return;
    }

    double balloonSize = 80.0;
    double spacing = 10.0;
    int maxBalloonsInRow = (screenWidth / (balloonSize + spacing)).floor();

    // Adjust this offset to spawn the balloons a little to the right
    double xPosition = (Random().nextInt(maxBalloonsInRow) * (balloonSize + spacing)).toDouble();
    double offsetRight = 50.0; // Control the offset to the right
    xPosition += offsetRight;

    // Ensure the yPosition starts just above the screen and moves downward
    double yPosition = -balloonSize - Random().nextInt(200).toDouble(); // Start just outside the screen

    // Ensure no collision occurs when spawning the new balloon
    bool hasCollision = false;
    for (var balloon in balloons) {
      if ((xPosition - balloon.x).abs() < balloonSize && (yPosition - balloon.y).abs() < balloonSize) {
        // Collision detected, reposition the new balloon
        hasCollision = true;
        break;
      }
    }

    // If there is a collision, attempt to reposition the new balloon
    if (hasCollision) {
      spawnBalloon(screenWidth, screenHeight); // Recursively try to spawn at a different position
      return;
    }

    // Add the balloon to the list
    int randomValue = Random().nextInt(10) + 1; // Random value for the balloon
    balloons.add(Balloon(
      x: xPosition,
      y: yPosition,
      value: randomValue,
      color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
    ));
  }

  // Update positions of balloons and prevent collisions
  void updateBalloonPositions(double screenHeight) {
    double scoreHeight = 80.0;
    for (var balloon in balloons) {
      if (!balloon.isStopped) {
        // Prevent balloons from overlapping when moving upwards
        if (balloon.y < screenHeight - scoreHeight - 100) {
          balloon.y += 2; // Move upwards
        } else {
          balloon.isStopped = true;
        }
      }

      // Collision check while moving
      for (var otherBalloon in balloons) {
        if (balloon != otherBalloon) {
          // Check for collision between two balloons
          if ((balloon.x - otherBalloon.x).abs() < 80.0 && (balloon.y - otherBalloon.y).abs() < 80.0) {
            // Resolve collision by moving the balloon upwards
            if (balloon.y < otherBalloon.y) {
              balloon.y -= 2;
            } else {
              balloon.y += 2;
            }
          }
        }
      }
    }
  }

  // Merge balloons if they collide
  void mergeBalloons() {
    for (int i = 0; i < balloons.length; i++) {
      for (int j = i + 1; j < balloons.length; j++) {
        if (balloons[i].value == balloons[j].value &&
            (balloons[i].x - balloons[j].x).abs() < 80.0 &&
            (balloons[i].y - balloons[j].y).abs() < 80.0) {
          balloons[i].value += balloons[j].value;
          balloons.removeAt(j);
          score += balloons[i].value;
          break;
        }
      }
    }
  }

  // Handle balloon dragging with collision prevention
  void handleDrag(Balloon balloon, double newX, double newY, double screenHeight) {
    double balloonSize = 80.0;
    // Ensure dragged balloon does not collide with others
    for (var otherBalloon in balloons) {
      if (balloon != otherBalloon) {
        // Check for overlap
        if ((newX - otherBalloon.x).abs() < balloonSize && (newY - otherBalloon.y).abs() < balloonSize) {
          return; // Don't move if there's a collision
        }
      }
    }

    // If no collision, update balloon position
    balloon.x = newX;
    balloon.y = screenHeight - newY - 80.0;
  }
}
