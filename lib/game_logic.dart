import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:audioplayers/audioplayers.dart';


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
  bool isPaused = false;

  final double balloonSize = 80.0; // Diameter of the balloons
  final double reservedScoreHeight = 120.0; // Height reserved for the score display
  int limit = 11; // Initial limit value
  int previousTouchCount = 0; // Track previous number of balloons touching the top


  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playSound(String soundFile) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }


  /// Spawns a balloon at the bottom of the screen
  void spawnBalloon(double screenWidth, double screenHeight) {
    final random = Random();

    if (gameOver || isFrozen || isPaused) return;  // Early return if game is over, frozen, or paused

    final balloonX = random.nextDouble() * (screenWidth - balloonSize);
    final balloonY = screenHeight - balloonSize;

    bool isPowerUp = random.nextDouble() < 0.2;  // 20% chance for power-up balloon

    if (isPowerUp) {
      PowerUpEffect effect = PowerUpEffect.values[random.nextInt(PowerUpEffect.values.length)];
      balloons.add(PowerUpBalloon(
        x: balloonX,
        y: balloonY,
        speed: random.nextDouble() * 1.5 + 1,  // Speed between 1 and 2.5
        color: Color.fromARGB(255, random.nextInt(256), random.nextInt(256), random.nextInt(256)),
        value: 0,
        effect: effect,
      ));
    } else {
      balloons.add(Balloon(
        x: balloonX,
        y: balloonY,
        speed: random.nextDouble() * 1.5 + 1,  // Speed between 1 and 2.5
        color: Color.fromARGB(255, random.nextInt(256), random.nextInt(256), random.nextInt(256)),
        value: random.nextInt(10) + 1,
      ));
    }
  }


  void checkAssets() {
    final List<String> assetPaths = [
      'assets/sounds/bomb.mp3',
      'assets/sounds/double_score.mp3',
      'assets/sounds/freeze.mp3',
      'assets/sounds/magnet.mp3',
      'assets/sounds/speed_up.mp3'
      // Add other asset paths here for testing
    ];

    for (var path in assetPaths) {
      print('Checking asset: $path');
      try {
        // You can try loading the assets here or use them
      } catch (e) {
        print('Asset not found: $path');
      }
    }
  }

  /// Updates the position of balloons, making them move upwards
  void updateBalloonPositions(double screenHeight) {
    int touchedTopCount = 0;

    if (isFrozen || isPaused) {
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
    if (isPaused)return;
    switch (powerUpBalloon.effect) {
      case PowerUpEffect.doubleScore:
        score *= 2;
        checkAssets();
        playSound('double_score.mp3');

        break;
      case PowerUpEffect.increaseSpeed:
      // Apply speed increase to all balloons immediately
        for (var balloon in balloons) {
          balloon.speed *= 1.2; // Increase speed by 20%
        }
        checkAssets();
        playSound('speed_up.mp3');
        break;
      case PowerUpEffect.freeze:
      // Immediately freeze all balloon movement
        for (var balloon in balloons) {
          balloon.speed = 0; // Set speed to 0 to stop movement
        }
        checkAssets();
        playSound('freeze.mp3');
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
        checkAssets();
        playSound('bomb.mp3');
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
        checkAssets();
        playSound('magnet.mp3');
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
    if (isPaused)
    {
      return;
    }
    for (int i = 0; i < balloons.length; i++) {
      for (int j = i + 1; j < balloons.length; j++) {
        // Skip merging if either balloon is a PowerUpBalloon
        if (balloons[i] is PowerUpBalloon || balloons[j] is PowerUpBalloon) {
          continue;
        }

        // Check if balloons are close enough and have the same value
        if ((balloons[i].x - balloons[j].x).abs() < balloonSize &&
            (balloons[i].y - balloons[j].y).abs() < balloonSize &&
            balloons[i].value == balloons[j].value) {
          balloons[i].value += balloons[j].value; // Merge values
          balloons.removeAt(j); // Remove the second balloon
          score += balloons[i].value; // Update score
          break; // Break to avoid skipping balloons due to shifting indices
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
    isPaused = false;
    // Reset the count of balloons touching the top
  }

}