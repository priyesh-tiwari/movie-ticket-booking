import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api_constants.dart';

class MovieService {
  Future<List<Map>> fetchMovies(String query) async {
    final url = Uri.parse(
        '${ApiConstants.omdbBaseUrl}?s=$query&apikey=${ApiConstants.omdbApiKey}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['Response'] == 'True' && data['Search'] != null) {
        return List<Map>.from(data['Search']);
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> loadMovies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      var trendingResult = await fetchMovies('star');
      var topRatedResult = await fetchMovies('batman');
      var tvResult = await fetchMovies('marvel');

      await prefs.setString('trendingMovies', json.encode(trendingResult));
      await prefs.setString('topRatedMovies', json.encode(topRatedResult));
      await prefs.setString('tvShows', json.encode(tvResult));

      return {
        'trending': trendingResult,
        'topRated': topRatedResult,
        'tv': tvResult,
      };
    } catch (e) {
      String? cachedTrending = prefs.getString('trendingMovies');
      String? cachedTopRated = prefs.getString('topRatedMovies');
      String? cachedTV = prefs.getString('tvShows');

      if (cachedTrending != null &&
          cachedTopRated != null &&
          cachedTV != null) {
        return {
          'trending': List<Map>.from(json.decode(cachedTrending)),
          'topRated': List<Map>.from(json.decode(cachedTopRated)),
          'tv': List<Map>.from(json.decode(cachedTV)),
        };
      }
      return {'trending': [], 'topRated': [], 'tv': []};
    }
  }
}
