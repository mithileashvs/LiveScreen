import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/theatre_configuration.dart';
import '../services/theatre_repository.dart';
import 'tabs/room_tab.dart';
import 'tabs/screen_tab.dart';
import 'tabs/seating_tab.dart';
import 'tabs/speakers_tab.dart';
import 'tabs/acoustics_tab.dart';
import 'tabs/movie_tab.dart';
import 'tabs/preview_publish_tab.dart';

/// PART 1/8/9: the single screen that hosts every configuration surface
/// for one theatre (Room, Screen, Seating, Speakers, Acoustics, Movie,
/// Preview & Publish) as tabs over one shared [TheatreConfiguration]
/// instance, so every tab is always editing the same in-memory object —
/// no risk of one tab's edits being silently discarded by another's.
class TheatreEditorScreen extends StatefulWidget {
  final String theatreId;

  const TheatreEditorScreen({super.key, required this.theatreId});

  @override
  State<TheatreEditorScreen> createState() => _TheatreEditorScreenState();
}

class _TheatreEditorScreenState extends State<TheatreEditorScreen> {
  TheatreConfiguration? _config;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await theatreRepository.loadTheatre(widget.theatreId);
    setState(() {
      _config = config;
      _loading = false;
    });
  }

  /// Every tab calls this after mutating [_config] in place. It re-persists
  /// through the repository (rather than relying on the in-memory object
  /// already being shared) so the same call keeps working unchanged once a
  /// real backend-backed [TheatreRepository] replaces the mock one.
  void _onChanged() {
    setState(() {});
    if (_config != null) {
      theatreRepository.saveTheatre(_config!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final config = _config;
    if (config == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Theatre Not Found')),
        body: const Center(
          child: Text('This theatre no longer exists.', style: AppTextStyles.body),
        ),
      );
    }

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(config.basicInfo.name.isEmpty ? 'Untitled Theatre' : config.basicInfo.name),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Room'),
              Tab(text: 'Screen'),
              Tab(text: 'Seating'),
              Tab(text: 'Speakers'),
              Tab(text: 'Acoustics'),
              Tab(text: 'Movie'),
              Tab(text: 'Preview & Publish'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RoomTab(config: config, onChanged: _onChanged),
            ScreenTab(config: config, onChanged: _onChanged),
            SeatingTab(config: config, onChanged: _onChanged),
            SpeakersTab(config: config, onChanged: _onChanged),
            AcousticsTab(config: config, onChanged: _onChanged),
            MovieTab(config: config, onChanged: _onChanged),
            PreviewPublishTab(config: config, onChanged: _onChanged),
          ],
        ),
      ),
    );
  }
}
