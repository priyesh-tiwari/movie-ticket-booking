import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map>> fetchUserReceipts(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('receipts')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future createTheater({
    required String name,
    required String location,
    required String adminId,
  }) async {
    String theaterId = 'theater_${DateTime.now().millisecondsSinceEpoch}';

    await _firestore.collection('theaters').doc(theaterId).set({
      'name': name,
      'location': location,
      'createdAt': FieldValue.serverTimestamp(),
      'adminId': adminId,
    });

    for (int i = 1; i <= 3; i++) {
      await _firestore
          .collection('theaters')
          .doc(theaterId)
          .collection('screens')
          .doc('screen_$i')
          .set({
        'screenNumber': i,
        'capacity': 100,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
