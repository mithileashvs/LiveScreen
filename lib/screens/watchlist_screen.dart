import 'package:flutter/material.dart';
import '../models/event.dart';
import '../theme/customer_theme.dart';

/// Clean Watchlist screen matching the LiveScreen visual language.
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final List<EventModel> _watchlist = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.background,
      appBar: AppBar(
        title: const Text(
          'My Watchlist',
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
      body: _watchlist.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: CustomerColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: CustomerColors.borderGold),
                      ),
                      child: const Icon(
                        Icons.bookmark_outline_rounded,
                        size: 34,
                        color: CustomerColors.gold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Movies Saved Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap the bookmark icon on any movie to save it for later.',
                      style: TextStyle(
                        color: CustomerColors.textSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _watchlist.length,
              itemBuilder: (context, index) {
                final item = _watchlist[index];
                return ListTile(
                  title: Text(item.title, style: const TextStyle(color: CustomerColors.textPrimary)),
                );
              },
            ),
    );
  }
}
