import 'dart:io'; // Required for Platform check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_logic.dart'; // Add this to import GameScreen
import 'leaderboard_page.dart';
import 'main.dart'; // Add import for GameScreen

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Spirit Tube',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 50),
              // Play Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GameScreen()), // Launches the game screen
                  );
                },
                child: Text('Play'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(height: 20),
              // How to Play Button
              ElevatedButton(
                onPressed: () {
                  _showHowToPlayDialog(context);
                },
                child: Text('How to Play'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(height: 20),
              // Leaderboards Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Leaderboard()), // Launches the leaderboard page
                  );
                },
                child: Text('Leaderboards'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(height: 20),
              // Exit Button (Only visible on Android)
              if (Platform.isAndroid)
                ElevatedButton(
                  onPressed: () {
                    _exitApp();
                  },
                  child: Text('Exit'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: TextStyle(fontSize: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Show "How to Play" Dialog
  void _showHowToPlayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('How to Play'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "1. Bubbles spawn randomly from the bottom of the screen and move upwards.\n"
                      "2. You can tap, drag, or manipulate bubbles to position them for merging.\n"
                      "3. Merge bubbles with the same value by dragging them.\n"
                      "4. The more you merge bubbles, the more points you earn and more difficult the games becomes.\n"
                      "5. Ensure bubbles don’t pile up and touch the top of the screen. If too many bubbles hit the top, your limit will decreases and when it reaches zero, the game ends.\n"
                      "6. There are 5 special bubbles which disappear after reaching the top: \n"
                      "   a: Star ⭐ which doubles the score \n"
                      "   b: Speed ⏱️ which increases the speed \n"
                      "   c: Freeze ❄️ which stops the upwards flow of bubbles for 3 seconds \n"
                      "   d: Bomb 💣 which destroys bubbles in a small radius \n"
                      "   e: Magnet 🧲 which attracts bubbles wihin a certain radius \n"
                      "7. To use these special bubbles, double-tap on them.",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  // Exit App
  void _exitApp() {
    SystemNavigator.pop(); // Exits the app (works on Android only)
  }
}
