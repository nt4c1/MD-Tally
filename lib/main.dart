import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_logic.dart';
import 'firebase_options.dart';
import 'country_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(Game2048App());
}

class Game2048App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048 Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: Game2048Screen(),
    );
  }
}

class Game2048Screen extends StatefulWidget {
  @override
  _Game2048ScreenState createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  late Game2048 game;
  String country = 'Fetching...';
  bool isRestricted = false;
  bool gameOver = false;
  bool nameInputVisible = false;
  TextEditingController nameController = TextEditingController();
  final List<String> restrictedCountries = ['my', 'sg', 'au', 'id'];

  @override
  void initState() {
    super.initState();
    game = Game2048(gridSize: 4);
    fetchCountryAndHandleRestriction();
  }

  Future<void> fetchCountryAndHandleRestriction() async {
    try {
      country = await CountryService.fetchCountry();
      setState(() {
        isRestricted = restrictedCountries.contains(country.toLowerCase());
      });
    } catch (e) {
      setState(() {
        country = 'Unknown';
        isRestricted = false;
      });
    }
  }

  Future<void> savePlayerDataToFirebase(String name, int score, String country) async {
    try {
      final playersRef = FirebaseFirestore.instance.collection('players');
      await playersRef.add({
        'name': name,
        'score': score,
        'country': country,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Player data saved to Firestore');
    } catch (e) {
      print('Error saving player data to Firestore: $e');
    }
  }

  void onSwipe(Direction direction) {
    setState(() {
      if (!game.isGameOver()) {
        switch (direction) {
          case Direction.left:
            game.moveLeft();
            break;
          case Direction.right:
            game.moveRight();
            break;
          case Direction.up:
            game.moveUp();
            break;
          case Direction.down:
            game.moveDown();
            break;
        }
      }
      gameOver = game.isGameOver();
      if (gameOver) {
        nameInputVisible = true;  // Show name input after game over
      }
    });
  }

  void resetGame() {
    setState(() {
      game.resetGame();
      gameOver = false;
      nameInputVisible = false; // Hide name input when resetting
      nameController.clear();
    });
  }

  void savePlayerData(String name) {
    // Save data to Firebase after entering the name
    savePlayerDataToFirebase(name, game.score, country);
    setState(() {
      nameInputVisible = false; // Hide name input after saving
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('2048 - Country: $country'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetGame,
          )
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            onSwipe(Direction.right);
          } else if (details.primaryVelocity! < 0) {
            onSwipe(Direction.left);
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            onSwipe(Direction.down);
          } else if (details.primaryVelocity! < 0) {
            onSwipe(Direction.up);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (gameOver && !nameInputVisible) ...[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Game Over',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Final Score: ${game.score}',
                      style: TextStyle(fontSize: 24, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: resetGame,
                      child: Text('Play Again'),
                    ),
                  ],
                ),
              ),
            ] else if (nameInputVisible) ...[
              // Name Input Section
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter your name',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      String name = nameController.text;
                      if (name.isNotEmpty) {
                        savePlayerData(name); // Save the data to Firebase
                      }
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Score: ${game.score}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: game.grid.map((row) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: row.map((value) => buildTile(value)).toList(),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildTile(int value) {
    return Container(
      width: 80,
      height: 80,
      margin: EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: getTileColor(value),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value == 0 ? '' : '$value',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: value > 4 ? Colors.white : Colors.black),
      ),
    );
  }

  Color getTileColor(int value) {
    switch (value) {
      case 2: return Colors.orange[100]!;
      case 4: return Colors.orange[200]!;
      case 8: return Colors.orange[300]!;
      case 16: return Colors.orange[400]!;
      case 32: return Colors.orange[500]!;
      case 64: return Colors.orange[600]!;
      case 128: return Colors.green[200]!;
      case 256: return Colors.green[300]!;
      case 512: return Colors.green[400]!;
      case 1024: return Colors.green[500]!;
      case 2048: return Colors.green[600]!;
      default: return Colors.grey[300]!;
    }
  }
}

enum Direction { up, down, left, right }
