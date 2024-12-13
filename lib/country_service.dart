import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class CountryService {
  /// Fetches the user's country using the API
  static Future<String> fetchCountry() async {
    try {
      final url = Uri.parse('https://api.country.is');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['country'] ?? 'Unknown';
      } else {
        throw Exception('Failed to fetch country: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching country: $e');
      return 'Unknown';
    }
  }

  /// Saves player data to Firebase
  static Future<void> saveToFirebase(String playerName, int score, String country) async {
    try {
      final dbRef = FirebaseDatabase.instance.ref('players').push();
      await dbRef.set({
        'playerName': playerName,
        'country': country,
        'score': score,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('Data saved to Firebase.');
    } catch (e) {
      print('Error saving data to Firebase: $e');
    }
  }
}
