// lib/models/gift.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Gift {
  final String id;
  final String name;
  final String description;
  final double? price;
  final String? url; // New field
  final String? category; // New field
  final String? reservedBy;
  final String? purchasedBy;
  final bool visibility;
  final bool purchased;
  final Timestamp createdAt;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    this.price,
    this.url,
    this.category,
    this.reservedBy,
    this.purchasedBy,
    required this.visibility,
    required this.purchased,
    required this.createdAt,
  });

  factory Gift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gift(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      url: data['url'], // Retrieve url from Firestore
      category: data['category'], // Retrieve category from Firestore
      reservedBy: data['reservedBy'],
      purchasedBy: data['purchasedBy'],
      visibility: data['visibility'] ?? true,
      purchased: data['purchased'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'url': url, // Include url when saving to Firestore
      'category': category, // Include category when saving to Firestore
      'reservedBy': reservedBy,
      'purchasedBy': purchasedBy,
      'visibility': visibility,
      'purchased': purchased,
      'createdAt': createdAt,
    };
  }
}
