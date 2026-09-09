import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/theatre_configuration.dart';
import '../services/theatre_repository.dart';
import 'create_theatre_screen.dart';
import 'theatre_editor_screen.dart';

class TheatreListScreen extends StatefulWidget {
  const TheatreListScreen({super.key});

  @override
  State<TheatreListScreen> createState() => _TheatreListScreenState();
}

class _TheatreListScreenState extends State<TheatreListScreen> {
  late Future<List<TheatreConfiguration>> _theatresFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    // This is the Theatre Admin's own list — must be their theatres only,
    // never every theatre in the database (getMyTheatres filters by
    // ownership server-side).
    _theatresFuture = theatreRepository.getMyTheatres();
  }

  Future<void> _openTheatre(TheatreConfiguration config) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TheatreEditorScreen(theatreId: config.id)),
    );
    setState(_refresh);
  }

  Future<void> _createTheatre() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTheatreScreen()),
    );
    if (created == true) {
      setState(_refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Theatres')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTheatre,
        icon: const Icon(Icons.add),
        label: const Text('Create Theatre'),
      ),
      body: FutureBuilder<List<TheatreConfiguration>>(
        future: _theatresFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final theatres = snapshot.data!;
          if (theatres.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.theaters_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text('No theatres yet', style: AppTextStyles.subheading),
                    const SizedBox(height: 6),
                    const Text(
                      'Create your first theatre to start configuring its room, '
                      'screen, seating, and speakers.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: theatres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final theatre = theatres[index];
              return Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openTheatre(theatre),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                theatre.basicInfo.name.isEmpty
                                    ? '(Untitled theatre)'
                                    : theatre.basicInfo.name,
                                style: AppTextStyles.subheading,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${theatre.basicInfo.hallName.isEmpty ? 'No hall name' : theatre.basicInfo.hallName} · '
                                '${theatre.seats.length} seats · ${theatre.speakers.length} speakers',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: theatre.status),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TheatreStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case TheatreStatus.published:
        color = AppColors.success;
        break;
      case TheatreStatus.archived:
        color = AppColors.textMuted;
        break;
      case TheatreStatus.draft:
        color = AppColors.accent;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
