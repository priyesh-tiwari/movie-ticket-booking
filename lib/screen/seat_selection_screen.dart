import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:movie_app_flutter/screen/payment.dart';
import 'package:movie_app_flutter/screen/receipt_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String movieId;
  final String theaterId;
  final String screenId;
  final String showtimeId;
  final String userId;

  const SeatSelectionScreen({
    Key? key,
    required this.movieId,
    required this.theaterId,
    required this.screenId,
    required this.showtimeId,
    required this.userId,
  }) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<String> selectedSeats = [];
  List<String> bookedSeats = [];
  final double seatPrice = 10.0;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchBookedSeats();
  }

  Future<void> _fetchBookedSeats() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('theaters')
          .doc(widget.theaterId)
          .collection('screens')
          .doc(widget.screenId)
          .collection('showtimes')
          .doc(widget.showtimeId)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          bookedSeats = List<String>.from(data['selectedSeats'] ?? []);
        });
      }
    } catch (e) {
      print("⚠️ Error fetching booked seats: $e");
    }
  }

  Future<bool> _bookSeats(double totalAmount) async {
    DocumentReference bookingRef = FirebaseFirestore.instance
        .collection('theaters')
        .doc(widget.theaterId)
        .collection('screens')
        .doc(widget.screenId)
        .collection('showtimes')
        .doc(widget.showtimeId);

    return FirebaseFirestore.instance
        .runTransaction((transaction) async {
          DocumentSnapshot snapshot = await transaction.get(bookingRef);

          List<String> alreadyBooked = [];
          if (snapshot.exists && snapshot.data() != null) {
            var data = snapshot.data() as Map<String, dynamic>;
            alreadyBooked = List<String>.from(data['selectedSeats'] ?? []);
          }

          bool isSeatAvailable =
              selectedSeats.every((seat) => !alreadyBooked.contains(seat));
          if (!isSeatAvailable) {
            throw Exception(
                "Some selected seats are already booked. Try again.");
          }

          transaction.set(
            bookingRef,
            {
              'selectedSeats': FieldValue.arrayUnion(selectedSeats),
              'totalAmount': totalAmount,
              'userId': widget.userId,
              'movieId': widget.movieId,
              'timestamp': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        })
        .then((_) => true)
        .catchError((error) {
          print("⚠️ Booking Error: $error");
          return false;
        });
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = selectedSeats.length * seatPrice;

    return Scaffold(
      backgroundColor: Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Your Seats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Screen Indicator
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.tealAccent, Colors.cyanAccent],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.tealAccent.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'SCREEN',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),

            // Legend
            FadeInDown(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSeatLegend(Colors.tealAccent, "Selected"),
                    _buildSeatLegend(Colors.red.shade400, "Booked"),
                    _buildSeatLegend(Colors.grey.shade700, "Available"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Seat Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  physics: BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    String seatNumber = 'S${index + 1}';
                    bool isBooked = bookedSeats.contains(seatNumber);
                    bool isSelected = selectedSeats.contains(seatNumber);

                    return GestureDetector(
                      onTap: isBooked
                          ? null
                          : () {
                              setState(() {
                                isSelected
                                    ? selectedSeats.remove(seatNumber)
                                    : selectedSeats.add(seatNumber);
                              });
                            },
                      child: FadeInUp(
                        duration: Duration(milliseconds: 300),
                        delay: Duration(milliseconds: index * 50),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBooked
                                ? Colors.red.shade400
                                : isSelected
                                    ? Colors.tealAccent
                                    : Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: isBooked
                                  ? Colors.red.shade700
                                  : isSelected
                                      ? Colors.tealAccent
                                      : Colors.grey.shade800,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.tealAccent.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_seat,
                                  color: isBooked
                                      ? Colors.white
                                      : isSelected
                                          ? Colors.black
                                          : Colors.grey.shade600,
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  seatNumber,
                                  style: TextStyle(
                                    color: isBooked
                                        ? Colors.white
                                        : isSelected
                                            ? Colors.black
                                            : Colors.grey.shade400,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom Section
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF1C1C1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Selected Seats Info
                  if (selectedSeats.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.tealAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.tealAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Seats',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                selectedSeats.join(', '),
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.tealAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${selectedSeats.length} Seat${selectedSeats.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedSeats.isNotEmpty && !isProcessing
                                ? Colors.tealAccent
                                : Colors.grey.shade800,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: (selectedSeats.isNotEmpty && !isProcessing)
                          ? () async {
                              setState(() {
                                isProcessing = true;
                              });

                              bool? paymentSuccess = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentScreen(
                                    amount: totalAmount,
                                    userId: widget.userId,
                                    movieId: widget.movieId,
                                    theaterId: widget.theaterId,
                                    showtimeId: widget.showtimeId,
                                    selectedSeats: List.from(selectedSeats),
                                    screenId: widget.screenId,
                                  ),
                                ),
                              );

                              if (paymentSuccess == true) {
                                bool bookingSuccess =
                                    await _bookSeats(totalAmount);
                                if (bookingSuccess) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReceiptScreen(
                                        userId: widget.userId,
                                        movieId: widget.movieId,
                                        theaterId: widget.theaterId,
                                        showtimeId: widget.showtimeId,
                                        selectedSeats: List.from(selectedSeats),
                                        totalAmount: totalAmount,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text("⚠️ Booking failed. Try again."),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }

                              setState(() {
                                isProcessing = false;
                              });
                            }
                          : null,
                      child: isProcessing
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  selectedSeats.isEmpty
                                      ? 'Select Seats'
                                      : 'Proceed to Payment (\$${totalAmount.toStringAsFixed(2)})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
