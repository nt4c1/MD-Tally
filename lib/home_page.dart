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
      body: Stack(
        children: [
          // Animated Background
          Positioned.fill(
            child: AnimatedBackground(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Title
                AnimatedText(
                  text: 'Spirit Tube',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 50),
                // Play Button
                CustomButton(
                  label: 'Play',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GameScreen()),
                    );
                  },
                ),
                SizedBox(height: 20),
                // How to Play Button
                CustomButton(
                  label: 'How to Play',
                  onPressed: () {
                    _showHowToPlayDialog(context);
                  },
                ),
                SizedBox(height: 20),
                // Leaderboards Button
                CustomButton(
                  label: 'Leaderboards',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Leaderboard()),
                    );
                  },
                ),
                SizedBox(height: 20),
                // Exit Button (Only visible on Android)
                if (Platform.isAndroid)
                  CustomButton(
                    label: 'Exit',
                    onPressed: _exitApp,
                  ),
              ],
            ),
          ),
        ],
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
                      "4. The more you merge bubbles, the more points you earn and more difficult the game becomes.\n"
                      "5. Ensure bubbles don’t pile up and touch the top of the screen. If too many bubbles hit the top, your limit decreases, and when it reaches zero, the game ends.\n"
                      "6. Special bubbles (Star, Speed, Freeze, Bomb, Magnet) have unique abilities. Double-tap to activate them.",
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

// Custom Button Widget
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const CustomButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.purpleAccent,
        foregroundColor: Colors.white,
        elevation: 10,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Animated Background Widget
class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                0.5 + 0.5 * _controller.value,
                1.0 - 0.5 * _controller.value
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Animated Text Widget
class AnimatedText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const AnimatedText({
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [Colors.yellow, Colors.orange, Colors.red],
          tileMode: TileMode.mirror,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}
