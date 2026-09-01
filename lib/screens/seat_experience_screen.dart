import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Placeholder for the future 3D "experience this seat" feature.
/// In Phase 2+, this screen will be replaced by the actual Unity 3D view.
class SeatExperienceScreen extends StatelessWidget {
  final String seatLabel;
  final String screenName;
  final String venueName;

  const SeatExperienceScreen({
    super.key,
    required this.seatLabel,
    required this.screenName,
    required this.venueName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('LiveScreen Experience')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 2),
              ),
              child: const Icon(Icons.view_in_ar_rounded, color: AppColors.accent, size: 52),
            ),
            const SizedBox(height: 28),
            Text('Your seat experience is coming', style: AppTextStyles.heading, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'In the next phase, you\'ll be able to experience the venue from this exact seat — sights, sounds, and all.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _infoRow('Selected Seat', seatLabel),
            _infoRow('Screen', screenName),
            _infoRow('Venue', venueName),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.accent),
                ),
                child: const Text('Back to Seats', style: TextStyle(color: AppColors.accent)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.subheading.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}
