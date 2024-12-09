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
      title: 'MD Tally',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.brown[300],
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
  int woodBurned = 0;
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

  Future<void> savePlayerDataToFirebase(String name, int woodBurned, String country) async {
    try {
      final playersRef = FirebaseFirestore.instance.collection('players');
      await playersRef.add({
        'name': name,
        'woodBurned': woodBurned,
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
        woodBurned += calculateWoodBurned();
      }
      gameOver = game.isGameOver();
      if (gameOver) {
        nameInputVisible = true;
      }
    });
  }

  int calculateWoodBurned() {
    return game.grid.expand((row) => row).reduce((sum, value) => sum + value);
  }

  void resetGame() {
    setState(() {
      game.resetGame();
      gameOver = false;
      nameInputVisible = false;
      woodBurned = 0;
      nameController.clear();
    });
  }

  void savePlayerData(String name) {
    savePlayerDataToFirebase(name, woodBurned, country);
    setState(() {
      nameInputVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MD Tally'),
        backgroundColor: Colors.grey,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetGame,
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: GestureDetector(
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
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Wood Burned: $woodBurned kg',
                        style: TextStyle(fontSize: 24, color: Colors.grey),
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
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Enter your name',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        String name = nameController.text;
                        if (name.isNotEmpty) {
                          savePlayerData(name);
                        }
                      },
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Wood Burned: $woodBurned kg',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
        image: value > 0
            ? DecorationImage(
          image: AssetImage('assets/images/tile.jpg'),
          fit: BoxFit.cover,
        )
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value == 0 ? '' : '$value kg', // Added "kg" to tile numbers
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color getTileColor(int value) {
    // Optional, if you want to add colors to the tile based on value
    switch (value) {
      case 2: return Colors.orange[100]!;
      case 4: return Colors.orange[200]!;
      case 8: return Colors.orange[300]!;
      case 16: return Colors.orange[400]!;
      case 32: return Colors.red[300]!;
      case 64: return Colors.red[400]!;
      case 128: return Colors.red[500]!;
      case 256: return Colors.yellow[300]!;
      case 512: return Colors.yellow[400]!;
      case 1024: return Colors.yellow[500]!;
      case 2048: return Colors.brown[400]!;
      default: return Colors.grey[300]!;
    }
  }
}

enum Direction { up, down, left, right }
