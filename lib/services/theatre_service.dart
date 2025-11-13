import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/showtime_model.dart';
import '../models/theater_model.dart';

Future<List<Theater>> fetchTheatersForMovie(String movieId) async {
  try {
    QuerySnapshot theaterSnapshot =
        await FirebaseFirestore.instance.collection('theaters').get();
    if (theaterSnapshot.docs.isEmpty) return [];

    List<Theater> theaters = [];

    for (var doc in theaterSnapshot.docs) {
      String theaterId = doc.id;
      String theaterName = doc['name'];
      String location = doc['location'];

      QuerySnapshot screenSnapshot =
          await doc.reference.collection('screens').get();
      List<Showtime> allShowtimes = [];

      for (var screenDoc in screenSnapshot.docs) {
        QuerySnapshot showtimeSnapshot = await screenDoc.reference
            .collection('showtimes')
            .where('startTime', isGreaterThan: Timestamp.now())
            .get();

        List<Showtime> showtimes = showtimeSnapshot.docs
            .where((showtimeDoc) => showtimeDoc['movieId'] == movieId)
            .map((showtimeDoc) => Showtime(
                  id: showtimeDoc.id,
                  time: showtimeDoc['time'],
                  screenId: screenDoc.id,
                ))
            .toList();
        allShowtimes.addAll(showtimes);
      }

      if (allShowtimes.isNotEmpty) {
        theaters.add(Theater(
          id: theaterId,
          name: theaterName,
          location: location,
          showtimes: allShowtimes,
        ));
      }
    }
    return theaters;
  } catch (e) {
    print("Error fetching theaters: $e");
    return [];
  }
}
