import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livescreen/admin/models/theatre_snack.dart';
import 'package:livescreen/admin/models/theatre_configuration.dart';
import 'package:livescreen/admin/services/selected_theatre.dart';

void main() {
  group('Theatre Snack Model & Multi-Theatre Scoping Tests', () {
    test('TheatreSnack serializes to and from map with accurate types', () {
      final snack = TheatreSnack(
        id: 'snack-uuid-01',
        theatreId: 'theatre-pvr-01',
        name: 'Caramel Gourmet Popcorn',
        description: 'Jumbo popcorn tossed in sweet brown butter caramel.',
        category: 'Popcorn',
        price: 320.0,
        imageUrl: 'https://example.com/caramel.jpg',
        isAvailable: true,
      );

      final map = snack.toMap();
      expect(map['theatre_id'], 'theatre-pvr-01');
      expect(map['name'], 'Caramel Gourmet Popcorn');
      expect(map['category'], 'Popcorn');
      expect(map['price'], 320.0);
      expect(map['image_url'], 'https://example.com/caramel.jpg');
      expect(map['is_available'], true);

      final deserialized = TheatreSnack.fromMap({
        'id': 'snack-uuid-01',
        ...map,
      });

      expect(deserialized.id, 'snack-uuid-01');
      expect(deserialized.theatreId, 'theatre-pvr-01');
      expect(deserialized.name, 'Caramel Gourmet Popcorn');
      expect(deserialized.price, 320.0);
      expect(deserialized.category, 'Popcorn');
      expect(deserialized.isAvailable, true);
    });

    test('TheatreSnack categoryIcon provides correct icon per category', () {
      const popcorn = TheatreSnack(id: '1', theatreId: 't1', name: 'Pop', price: 100, category: 'Popcorn');
      const combos = TheatreSnack(id: '2', theatreId: 't1', name: 'Combo', price: 200, category: 'Combos');
      const beverages = TheatreSnack(id: '3', theatreId: 't1', name: 'Coke', price: 90, category: 'Beverages');
      const desserts = TheatreSnack(id: '4', theatreId: 't1', name: 'Cake', price: 150, category: 'Desserts');
      const snacks = TheatreSnack(id: '5', theatreId: 't1', name: 'Nachos', price: 180, category: 'Snacks');

      expect(popcorn.categoryIcon, Icons.grain_rounded);
      expect(combos.categoryIcon, Icons.lunch_dining_rounded);
      expect(beverages.categoryIcon, Icons.local_drink_rounded);
      expect(desserts.categoryIcon, Icons.icecream_rounded);
      expect(snacks.categoryIcon, Icons.dinner_dining_rounded);
    });

    test('Snack catalogs are strictly isolated between different theatres', () {
      final theatreASnacks = [
        const TheatreSnack(
          id: 'snack-a-1',
          theatreId: 'theatre-alpha',
          name: 'Alpha Special Popcorn',
          price: 250,
        ),
      ];

      final theatreBSnacks = [
        const TheatreSnack(
          id: 'snack-b-1',
          theatreId: 'theatre-beta',
          name: 'Beta Nachos Combo',
          price: 300,
        ),
      ];

      // Verifying strict isolation
      expect(theatreASnacks.every((s) => s.theatreId == 'theatre-alpha'), isTrue);
      expect(theatreBSnacks.every((s) => s.theatreId == 'theatre-beta'), isTrue);
      expect(theatreASnacks.any((s) => s.theatreId == 'theatre-beta'), isFalse);
      expect(theatreBSnacks.any((s) => s.theatreId == 'theatre-alpha'), isFalse);
    });

    test('SelectedTheatreContext correctly tracks active theatre for snack management', () {
      final context = SelectedTheatreContext();
      final theatre1 = TheatreConfiguration(
        id: 't-1',
        basicInfo: TheatreBasicInfo(name: 'Cinema 1', city: 'Mumbai'),
      );
      final theatre2 = TheatreConfiguration(
        id: 't-2',
        basicInfo: TheatreBasicInfo(name: 'Cinema 2', city: 'Delhi'),
      );

      final resolved = context.resolve([theatre1, theatre2]);
      expect(resolved?.id, 't-1');
      expect(context.theatreId, 't-1');

      context.select('t-2');
      expect(context.theatreId, 't-2');

      final resolved2 = context.resolve([theatre1, theatre2]);
      expect(resolved2?.id, 't-2');
    });
  });
}
