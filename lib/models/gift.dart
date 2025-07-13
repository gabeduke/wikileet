// lib/models/gift.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class Gift {
  final String id;
  final String name;
  final String description;
  final String familyGroupId;
  final String? ownerId;  // Add ownerId field
  final double? price;
  final String? url;
  final List<String> categories;  // Changed from String? to List<String>
  final String? reservedBy;
  final String? purchasedBy;
  final bool visibility;
  final bool purchased;
  final Timestamp createdAt;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.familyGroupId,
    this.ownerId,  // Add to constructor
    this.price,
    this.url,
    this.categories = const [],  // Default to empty list
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
    String? familyGroupId,
    String? ownerId,  // Add to copyWith
    double? price,
    String? url,
    List<String>? categories,
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
      familyGroupId: familyGroupId ?? this.familyGroupId,
      ownerId: ownerId ?? this.ownerId,  // Add to return
      price: price ?? this.price,
      url: url ?? this.url,
      categories: categories ?? this.categories,
      reservedBy: reservedBy ?? this.reservedBy,
      purchasedBy: purchasedBy ?? this.purchasedBy,
      visibility: visibility ?? this.visibility,
      purchased: purchased ?? this.purchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Factory constructor to create a Gift from a map
  factory Gift.fromMap(Map<String, dynamic> data) {
    if (kDebugMode) {
      print('\n=== Gift.fromMap ===');
      print('Creating gift from data: $data');
    }
    
    // Handle timestamp more robustly
    Timestamp createdAt;
    final timestamp = data['createdAt'];
    if (timestamp is Timestamp) {
      createdAt = timestamp;
    } else if (timestamp is int) {
      createdAt = Timestamp.fromMillisecondsSinceEpoch(timestamp);
    } else {
      createdAt = Timestamp.now();
    }

    // Handle categories more robustly
    List<String> categories = [];
    final categoryData = data['categories'];
    if (categoryData != null) {
      if (categoryData is List) {
        categories = categoryData.map((e) => e.toString()).toList();
      } else if (categoryData is String) {
        categories = [categoryData];
      }
    }
    
    // Ensure we have a valid ID
    final String id = data['id']?.toString() ?? 
                     DateTime.now().millisecondsSinceEpoch.toString();
    
    if (kDebugMode) {
      print('Processed gift data:');
      print('- ID: $id');
      print('- Categories: $categories');
      print('- Timestamp: $createdAt');
      print('=== End Gift.fromMap ===\n');
    }
        
    return Gift(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      familyGroupId: data['familyGroupId'] as String? ?? '',
      ownerId: data['ownerId'] as String?,  // Add to fromMap constructor
      price: data['price'] != null ? (data['price'] as num).toDouble() : null,
      url: data['url'] as String?,
      categories: categories,
      reservedBy: data['reservedBy'] as String?,
      purchasedBy: data['purchasedBy'] as String?,
      visibility: data['visibility'] ?? true,
      purchased: data['purchased'] ?? false,
      createdAt: createdAt,
    );
  }

  factory Gift.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gift.fromMap({...data, 'id': doc.id});
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'familyGroupId': familyGroupId,
      'ownerId': ownerId,  // Add to toFirestore
      'price': price,
      'url': url,
      'categories': categories,
      'reservedBy': reservedBy,
      'purchasedBy': purchasedBy,
      'visibility': visibility,
      'purchased': purchased,
      'createdAt': createdAt,
    };
  }
}
