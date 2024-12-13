import 'package:http/http.dart' as http;
import 'dart:convert';

class CountryService {
  static Future<String> getCountry() async {
    final response = await http.get(Uri.parse('https://ipinfo.io/json'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['country'] ?? 'Unknown';
    } else {
      throw Exception('Failed to load country data');
    }
  }
}
