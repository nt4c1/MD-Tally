import 'dart:io'; // Required for Platform check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_logic.dart'; // Add this to import GameScreen
import 'leaderboard_page.dart';
import 'game_logic.dart';
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
          content: Text(
            '1. Bubbles will spawn at the bottom of the screen.\n'
                '2. Drag bubbles to combine those with the same value.\n'
                '3. Prevent bubbles from touching the top by merging them.\n'
                '4. Game ends when too many bubbles reach the top.',
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
