import 'package:flutter/material.dart';
import '../theme/customer_theme.dart';

/// Exclusive Offers screen matching the LiveScreen visual system.
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  static const List<Map<String, String>> _offers = [
    {
      'code': 'LIVESCREEN3D',
      'discount': '20% OFF',
      'title': 'First 3D Experience Booking',
      'description': 'Enjoy 20% off on your first seat booking with 3D Venue preview.',
      'validity': 'Valid till 30 Sep 2026',
    },
    {
      'code': 'GOLDWEEKEND',
      'discount': 'FLAT ₹150 OFF',
      'title': 'Weekend Cinema Binge',
      'description': 'Get flat ₹150 discount on premium recliner bookings on weekends.',
      'validity': 'Valid on Sat & Sun shows',
    },
    {
      'code': 'PARTY4',
      'discount': 'BUY 3 GET 1',
      'title': 'Group Movie Outing',
      'description': 'Book 3 tickets for any IMAX or Dolby Atmos show and get the 4th ticket free.',
      'validity': 'Valid for groups of 4+',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.background,
      appBar: AppBar(
        title: const Text(
          'Exclusive Offers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CustomerColors.textPrimary,
          ),
        ),
        backgroundColor: CustomerColors.surface,
        foregroundColor: CustomerColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: CustomerColors.borderSubtle, height: 1),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _offers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CustomerColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CustomerColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: CustomerColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CustomerColors.borderGold),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: CustomerColors.gold,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CustomerColors.burgundy,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              offer['discount']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            offer['title']!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: CustomerColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        offer['description']!,
                        style: const TextStyle(
                          color: CustomerColors.textSecondary,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            offer['validity']!,
                            style: const TextStyle(
                              color: CustomerColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: CustomerColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: CustomerColors.borderGold),
                            ),
                            child: Text(
                              offer['code']!,
                              style: const TextStyle(
                                color: CustomerColors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
