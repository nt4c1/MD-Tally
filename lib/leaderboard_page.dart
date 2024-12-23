import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'country_service.dart'; // Import the CountryService class

class Leaderboard extends StatefulWidget {
  @override
  _LeaderboardState createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final CollectionReference playersCollection =
  FirebaseFirestore.instance.collection('players');

  String selectedLocation = 'Global'; // Default to Global
  String userCountry = 'Global'; // Default fallback

  @override
  void initState() {
    super.initState();
    fetchUserCountry();
  }

  // Fetch user's country using CountryService
  Future<void> fetchUserCountry() async {
    final country = await CountryService.fetchCountry();
    setState(() {
      userCountry = country;
    });
    print('User country fetched: $userCountry');
  }

  // Function to get players based on location
  Future<QuerySnapshot> getPlayers() async {
    if (selectedLocation == 'Local') {
      print('Fetching local players for country: $userCountry');
      QuerySnapshot snapshot = await playersCollection
          .where('country', isEqualTo: userCountry)
          .orderBy('score', descending: true)
          .get();

      print('Local players found: ${snapshot.docs.length}');
      return snapshot;
    } else {
      QuerySnapshot snapshot = await playersCollection
          .orderBy('score', descending: true)
          .get();

      print('Global players found: ${snapshot.docs.length}');
      return snapshot;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leaderboard"),
      ),
      body: Column(
        children: [
          // FutureBuilder to fetch leaderboard data
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: getPlayers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error fetching leaderboard data."));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No players found."));
                }

                final players = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Text('#${index + 1}'),
                      title: Text(player['playerName'] ?? 'Unknown'),
                      subtitle: Text('Country: ${player['country'] ?? 'Unknown'}'),
                      trailing: Text('Score: ${player['score']}'),
                    );
                  },
                );
              },
            ),
          ),
          // Buttons to switch between Local and Global leaderboard
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedLocation = 'Local';
                    });
                  },
                  child: Text('Local'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    selectedLocation == 'Local' ? Colors.blue : Colors.grey,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedLocation = 'Global';
                    });
                  },
                  child: Text('Global'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    selectedLocation == 'Global' ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
