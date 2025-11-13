import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widget/search_movie.dart'; // Import the reusable widget

class AddMovieScreen extends StatefulWidget {
  final String theaterId;
  final String theaterName;

  const AddMovieScreen({
    Key? key,
    required this.theaterId,
    required this.theaterName,
  }) : super(key: key);

  @override
  _AddMovieScreenState createState() => _AddMovieScreenState();
}

class _AddMovieScreenState extends State<AddMovieScreen> {
  String? selectedMovieId;
  String? selectedMovieTitle;
  String? selectedMoviePoster;

  String? selectedScreen;
  String? selectedTime;
  DateTime? selectedDate;
  TimeOfDay? selectedTimeOfDay;

  List<String> availableScreens = [];
  List<String> predefinedTimes = [
    '09:00 AM',
    '12:00 PM',
    '03:00 PM',
    '06:00 PM',
    '09:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    fetchScreens();
  }

  Future<void> fetchScreens() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('theaters')
          .doc(widget.theaterId)
          .collection('screens')
          .get();

      setState(() {
        availableScreens = snapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print('Error fetching screens: $e');
    }
  }

  Future<void> addShowtime() async {
    if (selectedMovieId == null ||
        selectedScreen == null ||
        selectedDate == null ||
        selectedTimeOfDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create timestamp from selected date and time
      DateTime startTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTimeOfDay!.hour,
        selectedTimeOfDay!.minute,
      );

      // Generate showtime ID
      QuerySnapshot existingShowtimes = await FirebaseFirestore.instance
          .collection('theaters')
          .doc(widget.theaterId)
          .collection('screens')
          .doc(selectedScreen)
          .collection('showtimes')
          .get();

      int showtimeCount = existingShowtimes.docs.length + 1;
      String showtimeId = 'showtime_$showtimeCount';

      // Add showtime to Firestore
      await FirebaseFirestore.instance
          .collection('theaters')
          .doc(widget.theaterId)
          .collection('screens')
          .doc(selectedScreen)
          .collection('showtimes')
          .doc(showtimeId)
          .set({
        'isAvailable': true,
        'movieId': selectedMovieId,
        'movieTitle': selectedMovieTitle,
        'moviePoster': selectedMoviePoster,
        'selectedSeats': [],
        'startTime': Timestamp.fromDate(startTime),
        'time': selectedTime,
        'timestamp': FieldValue.serverTimestamp(),
        'totalAmount': 0,
        'userId': '',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Showtime added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        selectedMovieId = null;
        selectedMovieTitle = null;
        selectedMoviePoster = null;
        selectedScreen = null;
        selectedTime = null;
        selectedDate = null;
        selectedTimeOfDay = null;
      });
    } catch (e) {
      print('Error adding showtime: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to add showtime: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('🎬 Add Movie Showtime'),
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theater Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_movies, color: Colors.tealAccent, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theater',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          widget.theaterName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Search Movies Section
            Text(
              '🔍 Search Movie',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),

            // Use the reusable search widget
            MovieSearchWidget(
              selectedMovieId: selectedMovieId,
              onMovieSelected: (movieId, movieTitle, posterUrl) {
                setState(() {
                  selectedMovieId = movieId;
                  selectedMovieTitle = movieTitle;
                  selectedMoviePoster = posterUrl;
                });
              },
            ),

            // Selected Movie Indicator
            if (selectedMovieId != null) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.tealAccent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.tealAccent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Movie',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            selectedMovieTitle ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          selectedMovieId = null;
                          selectedMovieTitle = null;
                          selectedMoviePoster = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 30),

            // Select Screen
            Text(
              '📺 Select Screen',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedScreen,
              dropdownColor: Colors.grey[850],
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              hint: Text('Choose Screen', style: TextStyle(color: Colors.grey)),
              items: availableScreens.map((screen) {
                return DropdownMenuItem(
                  value: screen,
                  child: Text(screen),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedScreen = value;
                });
              },
            ),

            SizedBox(height: 30),

            // Select Date
            Text(
              '📅 Select Date',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 30)),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: Colors.tealAccent,
                          onPrimary: Colors.black,
                          surface: Colors.grey[850]!,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              icon: Icon(Icons.calendar_today, color: Colors.black),
              label: Text(
                selectedDate == null
                    ? 'Pick Date'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedDate == null ? Colors.grey[850] : Colors.tealAccent,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Select Time
            Text(
              '⏰ Select Time',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: predefinedTimes.map((time) {
                bool isSelected = selectedTime == time;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTime = time;
                      // Parse time for timestamp
                      List<String> parts = time.split(' ');
                      List<String> timeParts = parts[0].split(':');
                      int hour = int.parse(timeParts[0]);
                      int minute = int.parse(timeParts[1]);
                      if (parts[1] == 'PM' && hour != 12) hour += 12;
                      if (parts[1] == 'AM' && hour == 12) hour = 0;
                      selectedTimeOfDay = TimeOfDay(hour: hour, minute: minute);
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.tealAccent : Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? Colors.tealAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 40),

            // Add Showtime Button
            Center(
              child: ElevatedButton(
                onPressed: addShowtime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  '➕ Add Showtime',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
