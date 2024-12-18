import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Balloon {
  double x; // Horizontal position
  double y; // Vertical position
  double speed; // Balloon speed
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
enum PowerUpEffect {
  doubleScore,   // Doubles the player's score
  increaseSpeed, // Increases the speed of all balloons
  freeze,        // Freezes balloon movement temporarily
  bomb,          // Clears nearby balloons
  magnet,        // Attracts nearby balloons to merge
}


class PowerUpBalloon extends Balloon {
  final PowerUpEffect effect;

  PowerUpBalloon({
    required double x,
    required double y,
    required double speed,
    required int value,
    required Color color,
    required this.effect,
  }) : super(
    x: x,
    y: y,
    speed: speed,
    value: value,
    color: color,
  );
}


class GameLogic {
  List<Balloon> balloons = [];
  bool gameOver = false;
  int score = 0;
  bool isFrozen = false;

  final double balloonSize = 80.0; // Diameter of the balloons
  final double reservedScoreHeight = 120.0; // Height reserved for the score display
  int limit = 11; // Initial limit value
  int previousTouchCount = 0; // Track previous number of balloons touching the top

  /// Spawns a balloon at the bottom of the screen
  void spawnBalloon(double screenWidth, double screenHeight) {
    final random = Random();

    if (gameOver || isFrozen){
      return;
    }
    if (!gameOver || !isFrozen) {
      final balloonX = random.nextDouble() *
          (screenWidth - balloonSize); // Random horizontal position
      final balloonY = screenHeight - balloonSize; // Spawn near the bottom

      //Randomly decide if the balloon should be a regular or power-up balloon
      bool isPowerUp = random.nextDouble() <
          0.2; // 20% chance for power-up balloon

    if (isPowerUp) {
    // Power-Up Balloon
    PowerUpEffect effect = PowerUpEffect.values[random.nextInt(PowerUpEffect.values.length)];
    balloons.add(PowerUpBalloon(
      x: balloonX,
      y: balloonY,
      speed: random.nextDouble() * 1.5 + 1, // Speed between 1 and 2.5
      color: Color.fromARGB(
        255,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      ),
      value: 0,
      effect: effect,
    ));
    } else {
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
}
  /// Updates the position of balloons, making them move upwards
  void updateBalloonPositions(double screenHeight) {
    int touchedTopCount = 0;

    if (isFrozen) {
      return;  // Do nothing if frozen
    }


    // Iterate backwards to avoid index issues when removing items from the list
    for (int i = balloons.length - 1; i >= 0; i--) {
      var balloon = balloons[i];
      if (balloon.y > reservedScoreHeight + balloonSize) {
        balloon.y -= balloon.speed; // Move upwards
      } else if (balloon.y <= reservedScoreHeight + balloonSize) {
        touchedTopCount++;

        // If it's a power-up balloon, trigger the effect and mark for removal
        if (balloon is PowerUpBalloon) {
          triggerPowerUpEffect(balloon);
          balloons.removeAt(i);
        }
      }
    }

    // Update the limit based on touched balloons
    if (touchedTopCount != previousTouchCount) {
      int diff = touchedTopCount - previousTouchCount;
      limit -= diff;
      limit = limit.clamp(0, 11);
      previousTouchCount = touchedTopCount;
    }

    // Trigger game over if limit reaches zero
    if (limit == 0) {
      gameOver = true;
    }
  }
  void triggerPowerUpEffect(PowerUpBalloon powerUpBalloon) {
    switch (powerUpBalloon.effect) {
      case PowerUpEffect.doubleScore:
        score *= 2;

        break;
      case PowerUpEffect.increaseSpeed:
      // Apply speed increase to all balloons immediately
        for (var balloon in balloons) {
          balloon.speed *= 1.2; // Increase speed by 20%
        }
        break;
      case PowerUpEffect.freeze:
      // Immediately freeze all balloon movement
        for (var balloon in balloons) {
          balloon.speed = 0; // Set speed to 0 to stop movement
        }
        // Unfreeze balloons after a delay (3 seconds)
        Future.delayed(Duration(seconds: 3), () {
          for (var balloon in balloons) {
            balloon.speed = max(1, balloon.speed); // Restore normal speed
          }
        });
        break;
      case PowerUpEffect.bomb:
      // Define the blast radius
        double radius = 100.0; // Define the radius for the bomb's blast effect

        // Store indices of balloons to remove
        List<int> balloonsToRemove = [];

        // Iterate over all balloons to check if they are within the blast radius
        for (int i = 0; i < balloons.length; i++) {
          var balloon = balloons[i];

          // Check if the balloon is within the blast radius of the power-up balloon
          if ((balloon.x - powerUpBalloon.x).abs() < radius &&
              (balloon.y - powerUpBalloon.y).abs() < radius) {
            balloonsToRemove.add(i); // Add index of balloon to remove
            print('Balloon at index $i will be removed'); // Debugging line
          }
        }

        // Remove balloons in reverse order to avoid index shifting issues
        for (int i in balloonsToRemove.reversed) {
          if (i >= 0 && i < balloons.length) {
            balloons.removeAt(i); // Remove the balloon at index i
            print('Balloon at index $i removed'); // Debugging line
          }
        }
        break;

      case PowerUpEffect.magnet:
      // Attract nearby balloons to the magnet balloon
        for (var balloon in balloons) {
          if ((balloon.x - powerUpBalloon.x).abs() < 150 &&
              (balloon.y - powerUpBalloon.y).abs() < 150) {
            balloon.x = powerUpBalloon.x;
            balloon.y = powerUpBalloon.y;
          }
        }
        break;
    }
    balloons.remove(powerUpBalloon);
    print('PowerUpBalloon removed'); // Debugging line
  }


  IconData getPowerUpIcon(PowerUpEffect effect) {
    switch (effect) {
      case PowerUpEffect.doubleScore:
        return Icons.star; // ⭐ Represents doubling score
      case PowerUpEffect.increaseSpeed:
        return Icons.access_time; // ⏱️ Represents increased speed
      case PowerUpEffect.freeze:
        return Icons.ac_unit; // ❄️ Represents freezing
      case PowerUpEffect.bomb:
        return FontAwesomeIcons.bomb; // 💣 Represents a bomb
      case PowerUpEffect.magnet:
        return FontAwesomeIcons.magnet; // 🧲 Represents a magnet
      default:
        return Icons.help; // Fallback icon
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
      limit = 11; // Reset limit to 11 when restarting
      previousTouchCount = 0;
      isFrozen = false;
      // Reset the count of balloons touching the top
    }

}