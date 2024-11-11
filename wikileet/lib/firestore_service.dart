import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add a test product under the user's document
  Future<void> addTestProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    await _db.collection('users')
        .doc(user.uid)
        .collection('products')
        .add({
      'name': 'Sample Product',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Retrieve products for the authenticated user
  Stream<QuerySnapshot> getUserProducts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _db.collection('users')
        .doc(user.uid)
        .collection('products')
        .snapshots();
  }
}
