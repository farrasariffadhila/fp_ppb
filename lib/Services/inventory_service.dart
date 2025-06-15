import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryService {
  final CollectionReference _inventory =
      FirebaseFirestore.instance.collection('inventory');

  Future<bool> reserveMovie(int movieId) async {
    final docRef = _inventory.doc(movieId.toString());
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      int available;
      if (!snapshot.exists) {
        available = 2;
        transaction.set(docRef, {'availableCount': available});
      } else {
        available = (snapshot.data() as Map<String, dynamic>)['availableCount'] ?? 0;
      }
      if (available <= 0) {
        return false;
      }
      transaction.update(docRef, {'availableCount': available - 1});
      return true;
    });
  }

  Future<void> returnMovie(int movieId) async {
    final docRef = _inventory.doc(movieId.toString());
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        int available = data['availableCount'] ?? 0;
        transaction.update(docRef, {'availableCount': available + 1});
      } else {
        transaction.set(docRef, {'availableCount': 1});
      }
    });
  }
}