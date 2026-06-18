import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://moneyfactory-backend.onrender.com/api/courses');
  final res = await http.get(url);
  final data = jsonDecode(res.body);
  for (var c in data['courses']) {
    print(c['title']);
  }
}
