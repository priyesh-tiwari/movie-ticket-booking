import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static final String omdbApiKey = dotenv.env['OMDB_API_KEY'] ?? '';
  static final String omdbBaseUrl = dotenv.env['OMDB_BASE_URL'] ?? '';
}
