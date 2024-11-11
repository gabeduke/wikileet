// lib/models/gift.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Gift {
  final String id;
  final String name;
  final String description;
  final double? price;
  final String? link;
  final String? reservedBy;
  final String? purchasedBy; // New field to track who marked as purchased
  final bool visibility;
  final bool purchased;
  final Timestamp createdAt;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    this.price,
    this.link,
    this.reservedBy,
    this.purchasedBy, // Initialize the new field
    required this.visibility,
    required this.purchased,
    required this.createdAt,
  });

  // Factory constructor to create a Gift instance from Firestore document
  factory Gift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gift(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      link: data['link'],
      reservedBy: data['reservedBy'],
      purchasedBy: data['purchasedBy'], // Retrieve purchasedBy from Firestore
      visibility: data['visibility'] ?? true,
      purchased: data['purchased'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Convert Gift instance to Firestore-compatible JSON
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'link': link,
      'reservedBy': reservedBy,
      'purchasedBy': purchasedBy, // Include purchasedBy when saving to Firestore
      'visibility': visibility,
      'purchased': purchased,
      'createdAt': createdAt,
    };
  }
}
