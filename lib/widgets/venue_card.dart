import 'package:flutter/material.dart';
import '../models/venue.dart';
import '../theme/app_theme.dart';

/// A compact card representing a venue, shown in the "Popular Venues" row.
class VenueCard extends StatelessWidget {
  final VenueModel venue;
  final VoidCallback onTap;

  const VenueCard({
    super.key,
    required this.venue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_city, color: AppColors.electricBlue, size: 26),
            const SizedBox(height: 10),
            Text(
              venue.name,
              style: AppTextStyles.subheading.copyWith(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              venue.location,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
