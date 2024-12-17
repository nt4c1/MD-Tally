import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Leaderboard extends StatefulWidget {
  @override
  _LeaderboardState createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  final CollectionReference playersCollection =
  FirebaseFirestore.instance.collection('players');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Leaderboard"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: playersCollection.orderBy('score', descending: true).get(),
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
    );
  }
}
