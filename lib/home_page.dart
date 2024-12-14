import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'leaderboard_page.dart';
import 'main.dart'; // Import the main.dart to launch the game
import 'package:cloud_firestore/cloud_firestore.dart'; // For leaderboard data

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
                'Balloon Pop Game',
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
                    MaterialPageRoute(builder: (context) => MyApp()), // Launches the game
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
                    MaterialPageRoute(builder: (context) => LeaderboardPage()), // Launches the leaderboard page
                  );
                },
                child: Text('Leaderboards'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(height: 20),
              // Exit Button
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
            '1. Balloons will spawn at the bottom of the screen.\n'
                '2. Drag balloons to combine those with the same value.\n'
                '3. Prevent balloons from touching the top by merging them.\n'
                '4. Game ends when too many balloons reach the top.',
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
    Future.delayed(Duration(milliseconds: 100), () {
      // Exits the app (works for Android and iOS)
      Future.delayed(Duration.zero, () => SystemNavigator.pop());
    });
  }
}
