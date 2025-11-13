import 'package:movie_app_flutter/models/showtime_model.dart';

class Theater {
  final String id;
  final String name;
  final String location;
  final List<Showtime> showtimes;

  Theater({
    required this.id,
    required this.name,
    required this.location,
    required this.showtimes,
  });
}
