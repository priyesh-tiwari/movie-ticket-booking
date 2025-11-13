// Import dependencies
const express = require("express");
const cors = require("cors");
const Stripe = require("stripe");
require("dotenv").config();

// Initialize Express app and middleware
const app = express();
app.use(cors());
app.use(express.json());

// Initialize Stripe with your secret key
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

// ✅ Payment Intent Route
app.post("/create-payment-intent", async (req, res) => {
  try {
    const {
      amount,
      currency,
      userId,
      movieId,
      theaterId,
      showtimeId,
      selectedSeats,
      metadata,
    } = req.body;

    if (!amount || amount <= 0) {
      return res
        .status(400)
        .json({ error: "Invalid amount. Must be greater than 0." });
    }

    console.log("💳 Creating payment intent for movie booking:", {
      amount,
      currency: currency || "inr",
      userId,
      movieId,
      theaterId,
      showtimeId,
      selectedSeats,
    });

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount), // Stripe expects amount in smallest currency unit (e.g. paise)
      currency: currency || "inr",
      metadata: {
        userId: metadata?.userId || userId || "",
        movieId: metadata?.movieId || movieId || "",
        theaterId: metadata?.theaterId || theaterId || "",
        showtimeId: metadata?.showtimeId || showtimeId || "",
        selectedSeats:
          metadata?.selectedSeats || selectedSeats?.join(", ") || "",
        type: "movie_booking",
        timestamp: new Date().toISOString(),
      },
      automatic_payment_methods: { enabled: true },
    });

    console.log("✅ Payment intent created:", paymentIntent.id);

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
      amount: paymentIntent.amount,
      currency: paymentIntent.currency,
    });
  } catch (error) {
    console.error("❌ Error creating payment intent:", error.message);
    res.status(500).json({
      error: error.message,
      details:
        "Failed to create payment intent. Please check Stripe configuration.",
    });
  }
});

// ✅ Default route
app.get("/", (req, res) => {
  res.send("🎬 Movie Ticket Stripe backend is running ✅");
});

// ✅ Start server
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
