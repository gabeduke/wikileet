// lib/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Test function to add data
  Future<void> addTestDocument() async {
    await _db.collection('testCollection').add({
      'name': 'Test Document',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Test function to read data
  Stream<QuerySnapshot> getTestDocuments() {
    return _db.collection('testCollection').snapshots();
  }
}
