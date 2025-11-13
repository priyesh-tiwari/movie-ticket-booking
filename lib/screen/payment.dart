import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String userId;
  final String movieId;
  final String theaterId;
  final String showtimeId;
  final List<String> selectedSeats;
  final String screenId; // REQUIRED: screen ID

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.userId,
    required this.movieId,
    required this.theaterId,
    required this.showtimeId,
    required this.selectedSeats,
    required this.screenId, // Must be passed from previous screen
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isProcessing = false;
  Map<String, dynamic>? paymentIntent;

  @override
  void initState() {
    super.initState();
    makePayment();
  }

  Future<void> makePayment() async {
    setState(() => isProcessing = true);

    try {
      // Validate user authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("User not authenticated!");
      }

      if (currentUser.uid != widget.userId) {
        throw Exception("User ID mismatch!");
      }

      final backendUrl = dotenv.env['STRIPE_BACKEND_URL'];

      // 1️⃣ Create PaymentIntent via backend
      final response = await http
          .post(
        Uri.parse(backendUrl!),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": (widget.amount * 100).toInt(),
          "currency": "usd",
          "userId": widget.userId,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("Payment server timeout. Please try again.");
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to create PaymentIntent: ${response.body}");
      }

      // 2️⃣ Decode clientSecret
      paymentIntent = jsonDecode(response.body);
      final clientSecret = paymentIntent!['clientSecret'];

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception("Invalid client secret received");
      }

      // 3️⃣ Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Movie App 🎬',
          customFlow: true,
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            currencyCode: 'USD',
            testEnv: true,
          ),
        ),
      );

      // 4️⃣ Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // ✅ 5️⃣ Payment success → Save booking
      await _saveBookingToFirestore();

      Fluttertoast.showToast(
        msg: "🎉 Payment successful! Booking confirmed.",
        backgroundColor: Colors.green,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      if (mounted) Navigator.pop(context, true);
    } on StripeException catch (e) {
      debugPrint("❌ Stripe Error: ${e.error.message}");

      Fluttertoast.showToast(
        msg: e.error.localizedMessage ?? "Payment cancelled",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      if (mounted) Navigator.pop(context, false);
    } catch (e) {
      debugPrint("❌ Payment failed: $e");

      String errorMessage = "Payment failed. Please try again.";

      if (e.toString().contains("Showtime not found")) {
        errorMessage = "Showtime not available.";
      } else if (e.toString().contains("already booked")) {
        errorMessage = "Selected seats are no longer available.";
      } else if (e.toString().contains("not authenticated")) {
        errorMessage = "Please login again.";
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      if (mounted) Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> _saveBookingToFirestore() async {
    final firestore = FirebaseFirestore.instance;

    // Correct path: theaters/{id}/screens/{id}/showtimes/{id}
    final showtimeRef = firestore
        .collection('theaters')
        .doc(widget.theaterId)
        .collection('screens')
        .doc(widget.screenId)
        .collection('showtimes')
        .doc(widget.showtimeId);

    final bookingRef = firestore
        .collection('bookings')
        .doc(widget.userId)
        .collection('userBookings')
        .doc();

    await firestore.runTransaction((transaction) async {
      final showtimeSnapshot = await transaction.get(showtimeRef);

      if (!showtimeSnapshot.exists) {
        throw Exception("Showtime not found!");
      }

      final showtimeData = showtimeSnapshot.data();
      final List<dynamic> bookedSeats = showtimeData?['bookedSeats'] ?? [];

      // Check if seats are available
      for (var seat in widget.selectedSeats) {
        if (bookedSeats.contains(seat)) {
          throw Exception("Seat $seat is already booked!");
        }
      }

      // Save booking
      transaction.set(bookingRef, {
        'bookingId': bookingRef.id,
        'userId': widget.userId,
        'movieId': widget.movieId,
        'theaterId': widget.theaterId,
        'screenId': widget.screenId,
        'showtimeId': widget.showtimeId,
        'selectedSeats': widget.selectedSeats,
        'amount': widget.amount,
        'timestamp': FieldValue.serverTimestamp(),
        'paymentStatus': 'Paid',
      });

      // Update booked seats
      transaction.update(showtimeRef, {
        'bookedSeats': FieldValue.arrayUnion(widget.selectedSeats),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Processing Payment"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: isProcessing
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.tealAccent),
                    SizedBox(height: 16),
                    Text(
                      "Processing your payment...",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Please do not close the app",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                )
              : const Text(
                  "Finalizing payment...",
                  style: TextStyle(color: Colors.white70),
                ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
