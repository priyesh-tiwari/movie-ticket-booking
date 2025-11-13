import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageShowtimesScreen extends StatefulWidget {
  final String theaterId;

  const ManageShowtimesScreen({Key? key, required this.theaterId})
      : super(key: key);

  @override
  _ManageShowtimesScreenState createState() => _ManageShowtimesScreenState();
}

class _ManageShowtimesScreenState extends State<ManageShowtimesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('🎬 Manage Showtimes'),
        backgroundColor: Colors.grey[900],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('theaters')
            .doc(widget.theaterId)
            .collection('screens')
            .snapshots(),
        builder: (context, screenSnapshot) {
          if (screenSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!screenSnapshot.hasData || screenSnapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_filter, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'No screens available',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: screenSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var screen = screenSnapshot.data!.docs[index];
              return _buildScreenCard(screen);
            },
          );
        },
      ),
    );
  }

  Widget _buildScreenCard(QueryDocumentSnapshot screen) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.tv, color: Colors.blueAccent),
        ),
        title: Text(
          'Screen ${screen.id}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: screen.reference
                .collection('showtimes')
                .orderBy('startTime', descending: false)
                .snapshots(),
            builder: (context, showtimeSnapshot) {
              if (!showtimeSnapshot.hasData ||
                  showtimeSnapshot.data!.docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    '📭 No showtimes scheduled',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: showtimeSnapshot.data!.docs.length,
                itemBuilder: (context, idx) {
                  var showtime = showtimeSnapshot.data!.docs[idx];
                  return _buildShowtimeCard(showtime, screen.id);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShowtimeCard(QueryDocumentSnapshot showtime, String screenId) {
    String movieId = showtime['movieId'] ?? 'N/A';
    String time = showtime['time'] ?? 'N/A';
    Timestamp? startTime = showtime['startTime'];
    List selectedSeats = showtime['selectedSeats'] ?? [];
    bool isAvailable = showtime['isAvailable'] ?? true;

    DateTime? startDateTime = startTime?.toDate();
    bool isPastShowtime =
        startDateTime != null && startDateTime.isBefore(DateTime.now());

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isPastShowtime ? Colors.grey : Colors.tealAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPastShowtime
                ? Colors.grey.withOpacity(0.2)
                : Colors.orangeAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.access_time,
            color: isPastShowtime ? Colors.grey : Colors.orangeAccent,
          ),
        ),
        title: Text(
          '🎬 Movie: $movieId',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Text(
              '⏰ Time: $time',
              style: TextStyle(color: Colors.grey[400]),
            ),
            Text(
              '🪑 Seats Booked: ${selectedSeats.length}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (isPastShowtime)
              Text(
                '⚠️ Past Showtime',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: Colors.white),
          color: Colors.grey[800],
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Text('Edit', style: TextStyle(color: Colors.white)),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  _showEditDialog(showtime, screenId);
                });
              },
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: Colors.white)),
                ],
              ),
              onTap: () {
                Future.delayed(Duration.zero, () {
                  _deleteShowtime(showtime, screenId);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(QueryDocumentSnapshot showtime, String screenId) {
    TextEditingController timeController =
        TextEditingController(text: showtime['time']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
              Text('✏️ Edit Showtime', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Time',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[850],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('theaters')
                    .doc(widget.theaterId)
                    .collection('screens')
                    .doc(screenId)
                    .collection('showtimes')
                    .doc(showtime.id)
                    .update({'time': timeController.text});

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Showtime updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
              ),
              child: Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _deleteShowtime(QueryDocumentSnapshot showtime, String screenId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('🗑️ Delete Showtime',
              style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete this showtime?',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('theaters')
                    .doc(widget.theaterId)
                    .collection('screens')
                    .doc(screenId)
                    .collection('showtimes')
                    .doc(showtime.id)
                    .delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Showtime deleted'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
