// lib/models/gift.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Gift {
  final String id;
  final String name;
  final String description;
  final String familyGroupId;  // Added required field
  final double? price;
  final String? url;
  final String? category;
  final String? reservedBy;
  final String? purchasedBy;
  final bool visibility;
  final bool purchased;
  final Timestamp createdAt;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.familyGroupId,  // Added to constructor
    this.price,
    this.url,
    this.category,
    this.reservedBy,
    this.purchasedBy,
    required this.visibility,
    required this.purchased,
    required this.createdAt,
  });

  Gift copyWith({
    String? id,
    String? name,
    String? description,
    String? familyGroupId,  // Added to copyWith
    double? price,
    String? url,
    String? category,
    String? reservedBy,
    String? purchasedBy,
    bool? visibility,
    bool? purchased,
    Timestamp? createdAt,
  }) {
    return Gift(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      familyGroupId: familyGroupId ?? this.familyGroupId,  // Added to copyWith
      price: price ?? this.price,
      url: url ?? this.url,
      category: category ?? this.category,
      reservedBy: reservedBy ?? this.reservedBy,
      purchasedBy: purchasedBy ?? this.purchasedBy,
      visibility: visibility ?? this.visibility,
      purchased: purchased ?? this.purchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Gift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gift(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      familyGroupId: data['familyGroupId'] ?? '',  // Added familyGroupId
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      url: data['url'] as String?,
      category: data['category'] as String?,
      reservedBy: data['reservedBy'] as String?,
      purchasedBy: data['purchasedBy'] as String?,
      visibility: data['visibility'] ?? true,
      purchased: data['purchased'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'familyGroupId': familyGroupId,  // Added to toFirestore
      'price': price,
      'url': url,
      'category': category,
      'reservedBy': reservedBy,
      'purchasedBy': purchasedBy,
      'visibility': visibility,
      'purchased': purchased,
      'createdAt': createdAt,
    };
  }
}
