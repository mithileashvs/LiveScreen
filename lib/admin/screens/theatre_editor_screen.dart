import 'package:flutter/material.dart';
import '../models/theatre_configuration.dart';
import '../services/theatre_repository.dart';
import 'tabs/room_tab.dart';
import 'tabs/screen_tab.dart';
import 'tabs/seating_tab.dart';
import 'tabs/speakers_tab.dart';
import 'tabs/acoustics_tab.dart';
import 'tabs/movie_tab.dart';
import 'tabs/preview_publish_tab.dart';

/// The Redesigned LiveScreen Theatre Studio Editor.
/// Hosts configuration surfaces for one theatre in the master dark cinematic design language:
/// Room, Screen, Seating, Speakers, Acoustics, Movie, Preview & Publish.
class TheatreEditorScreen extends StatefulWidget {
  final String theatreId;
  final int initialIndex;

  const TheatreEditorScreen({
    super.key,
    required this.theatreId,
    this.initialIndex = 0,
  });

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
        backgroundColor: Color(0xFF070709),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    final config = _config;
    if (config == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF070709),
        appBar: AppBar(
          title: const Text('Theatre Not Found', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0C0C10),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('This theatre no longer exists.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ),
      );
    }

    final validIndex = widget.initialIndex.clamp(0, 6);

    return DefaultTabController(
      length: 7,
      initialIndex: validIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFF070709),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.basicInfo.name.isEmpty ? 'Untitled Theatre' : config.basicInfo.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFFFFFFFF)),
              ),
              const Text(
                'Theatre Studio 3D Venue Editor',
                style: TextStyle(fontSize: 11, color: Color(0xFFD4AF37), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          elevation: 0,
          backgroundColor: const Color(0xFF0C0C10),
          foregroundColor: const Color(0xFFF7F5F0),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFFD4AF37),
            indicatorWeight: 2.5,
            labelColor: Color(0xFFD4AF37),
            unselectedLabelColor: Color(0xFF9CA3AF),
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
