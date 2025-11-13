import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_app_flutter/widget/TV.dart';
import 'package:movie_app_flutter/widget/search_movie.dart';
import 'package:movie_app_flutter/widget/topRatedMovies.dart';
import 'package:movie_app_flutter/widget/trending.dart';

import '../services/firebase_service.dart';
import '../services/movie_service.dart';
import '../widget/carousel_slider_widget.dart';
import '../widget/drawer_widget.dart';
import '../widget/movie_details_sheet.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map> userReceipts = [];
  List trendingmovies = [];
  List topratedmovies = [];
  List tv = [];
  bool showSearch = false;

  final MovieService _movieService = MovieService();
  final FirebaseService _firebaseService = FirebaseService();
  var user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    loadMovies();
    fetchUserReceipts();
  }

  Future fetchUserReceipts() async {
    if (user == null) {
      print("User is null, skipping receipt fetch.");
      return;
    }

    final receipts = await _firebaseService.fetchUserReceipts(user!.uid);

    if (mounted) {
      setState(() {
        userReceipts = receipts;
      });
    }

    print("Fetched receipts: $userReceipts");
  }

  void _showReceiptDialog(Map receipt) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: Colors.tealAccent,
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Booking Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24),

                // Details
                _buildDetailRow(Icons.movie, "Movie", receipt['movieId']),
                SizedBox(height: 12),
                _buildDetailRow(
                    Icons.location_city, "Theater", receipt['theaterId']),
                SizedBox(height: 12),
                _buildDetailRow(
                    Icons.access_time, "Showtime", receipt['showtimeId']),
                SizedBox(height: 12),
                _buildDetailRow(Icons.event_seat, "Seats",
                    receipt['selectedSeats'].join(', ')),
                SizedBox(height: 20),

                // Amount
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.tealAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Amount",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "\$${receipt['totalAmount']}",
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.tealAccent, size: 20),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future loadMovies() async {
    final movies = await _movieService.loadMovies();

    if (mounted) {
      setState(() {
        trendingmovies = movies['trending']!;
        topratedmovies = movies['topRated']!;
        tv = movies['tv']!;
      });
    }
  }

  void _handleMovieTap(Map movie) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MovieDetailsSheet(movie: movie),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000),
      appBar: AppBar(
        title: Text(
          'filmFest 🎬',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: showSearch
                    ? Colors.tealAccent.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                showSearch ? Icons.close : Icons.search,
                color: Colors.tealAccent,
                size: 24,
              ),
            ),
            onPressed: () {
              setState(() {
                showSearch = !showSearch;
              });
            },
          ),
        ],
      ),
      drawer: DrawerWidget(user: user),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (showSearch)
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.search,
                              color: Colors.tealAccent, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Search Movies',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      MovieSearchWidget(
                        showSelectionIndicator: false,
                        onMovieTap: _handleMovieTap,
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 10),
              CarouselSliderWidget(movies: trendingmovies),
              TV(tv: tv),
              TrendingMovies(trending: trendingmovies),
              TopRatedMovies(toprated: topratedmovies),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
