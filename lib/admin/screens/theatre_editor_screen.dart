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
import '../capture/ui/venue_capture_screen.dart';
import '../capture/models/reconstruction_draft.dart';
import '../capture/ui/widgets/floating_venue_assistant.dart';

/// The Redesigned LiveScreen Theatre Studio Editor.
/// Hosts configuration surfaces for one theatre in the master dark cinematic design language:
/// Room, Screen, Seating, Speakers, Acoustics, Movie, Preview & Publish.
class TheatreEditorScreen extends StatefulWidget {
  final String theatreId;
  final int initialIndex;
  final TheatreConfiguration? initialConfig;
  final TheatreRepository? repository;

  const TheatreEditorScreen({
    super.key,
    required this.theatreId,
    this.initialIndex = 0,
    this.initialConfig,
    this.repository,
  });

  @override
  State<TheatreEditorScreen> createState() => _TheatreEditorScreenState();
}

class _TheatreEditorScreenState extends State<TheatreEditorScreen>
    with SingleTickerProviderStateMixin {
  TheatreConfiguration? _config;
  ReconstructionDraft? _currentDraft;
  late TabController _tabController;
  bool _loading = true;

  TheatreRepository get _repo => widget.repository ?? theatreRepository;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 7,
      initialIndex: widget.initialIndex.clamp(0, 6),
      vsync: this,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.initialConfig != null) {
      setState(() {
        _config = widget.initialConfig;
        _currentDraft =
            ReconstructionDraft.fromTheatreConfiguration(widget.initialConfig!);
        _loading = false;
      });
      return;
    }
    final config = await _repo.loadTheatre(widget.theatreId);
    setState(() {
      _config = config;
      if (config != null) {
        _currentDraft = ReconstructionDraft.fromTheatreConfiguration(config);
      }
      _loading = false;
    });
  }

  void _onChanged() {
    setState(() {});
    if (_config != null) {
      _repo.saveTheatre(_config!);
    }
  }


  String get _currentContextName {
    switch (_tabController.index) {
      case 0:
        return 'Room Configuration';
      case 1:
        return 'Screen Configuration';
      case 2:
        return 'Seating Configuration';
      case 3:
        return 'Speaker Configuration';
      case 4:
        return 'Acoustics Configuration';
      case 5:
        return 'Movie Configuration';
      case 6:
        return 'Preview & Publish';
      default:
        return 'Venue Configuration';
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

    return Scaffold(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, color: Color(0xFFD4AF37)),
            tooltip: 'AI Venue Capture',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VenueCaptureScreen(
                    theatreId: config.id,
                    initialConfig: config,
                    onConfigurationUpdated: (updated) {
                      setState(() {
                        _config = updated;
                        _currentDraft =
                            ReconstructionDraft.fromTheatreConfiguration(updated);
                      });
                      _repo.saveTheatre(updated);
                    },
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFD4AF37),
          indicatorWeight: 2.5,
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
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
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
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
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingVenueAssistant(
              sessionId: 'editor-${config.id}',
              theatreId: config.id,
              contextName: _currentContextName,
              currentDraft: _currentDraft ??
                  ReconstructionDraft.fromTheatreConfiguration(config),
              onDraftUpdated: (updatedDraft) {
                setState(() {
                  _currentDraft = updatedDraft;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
