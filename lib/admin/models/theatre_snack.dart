import 'package:flutter/material.dart';

/// Represents a concession/snack item belonging strictly to a specific theatre.
class TheatreSnack {
  final String id;
  final String theatreId;
  final String name;
  final String description;
  final String category;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TheatreSnack({
    required this.id,
    required this.theatreId,
    required this.name,
    this.description = '',
    this.category = 'Snacks',
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory TheatreSnack.fromMap(Map<String, dynamic> map) {
    return TheatreSnack(
      id: map['id']?.toString() ?? '',
      theatreId: map['theatre_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Snacks',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: map['image_url']?.toString(),
      isAvailable: map['is_available'] == true || map['is_available'] == null,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap({bool forInsert = false}) {
    final map = <String, dynamic>{
      'theatre_id': theatreId,
      'name': name.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'price': price,
      'image_url': imageUrl?.trim(),
      'is_available': isAvailable,
    };
    if (!forInsert && id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  TheatreSnack copyWith({
    String? id,
    String? theatreId,
    String? name,
    String? description,
    String? category,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TheatreSnack(
      id: id ?? this.id,
      theatreId: theatreId ?? this.theatreId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'popcorn':
        return Icons.grain_rounded;
      case 'combos':
        return Icons.lunch_dining_rounded;
      case 'beverages':
      case 'drinks':
        return Icons.local_drink_rounded;
      case 'desserts':
      case 'sweets':
        return Icons.icecream_rounded;
      case 'snacks':
      default:
        return Icons.dinner_dining_rounded;
    }
  }
}
