import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../models/screen_config.dart';
import '../../models/speaker_model.dart';
import '../../models/theatre_configuration.dart';
import '../../widgets/object_inspector_panel.dart';
import '../../widgets/visual_theatre_canvas.dart';

class SpeakersTab extends StatefulWidget {
  final TheatreConfiguration config;
  final VoidCallback onChanged;

  const SpeakersTab({super.key, required this.config, required this.onChanged});

  @override
  State<SpeakersTab> createState() => _SpeakersTabState();
}

class _SpeakersTabState extends State<SpeakersTab> {
  SpeakerModel? _selected;
  int _nextSpeakerNumber = 1;

  void _addSpeaker() {
    final config = widget.config;
    final id = 'speaker_${_nextSpeakerNumber++}';
    final speaker = SpeakerModel(
      id: id,
      name: 'Speaker ${config.speakers.length + 1}',
      position: Position3(x: 0, y: 2.5, z: config.room.length / 2),
    );
    config.speakers.add(speaker);
    setState(() => _selected = speaker);
    widget.onChanged();
  }

  void _deleteSelected() {
    if (_selected == null) return;
    widget.config.speakers.removeWhere((s) => s.id == _selected!.id);
    setState(() => _selected = null);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('${config.speakers.length} speakers configured',
                    style: AppTextStyles.subheading),
              ),
              ElevatedButton.icon(
                onPressed: _addSpeaker,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Speaker'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: VisualTheatreCanvas(
              room: config.room,
              screen: config.screen,
              seats: config.seats,
              speakers: config.speakers,
              selectedId: _selected?.id,
              onSelectSeat: (_) {},
              onSelectSpeaker: (speaker) => setState(() => _selected = speaker),
              onSelectScreen: () {},
              onMoveSpeaker: (speaker, delta) {
                speaker.position.x += delta.dx;
                speaker.position.z += delta.dy;
                widget.onChanged();
              },
              onMoveScreen: (_) {},
            ),
          ),
        ),
        if (_selected != null)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _buildInspector(_selected!),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tap a speaker to edit it, or drag it to reposition. Required fields '
              'are position, type, and channel — everything else is optional.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildInspector(SpeakerModel speaker) {
    String specsText(double? v) => v?.toString() ?? '';

    return ObjectInspectorPanel(
      objectId: speaker.id,
      title: 'Selected Speaker',
      subtitle: speaker.id,
      onDelete: _deleteSelected,
      onClose: () => setState(() => _selected = null),
      onSave: () {
        widget.onChanged();
        setState(() => _selected = null);
      },
      fields: [
        InspectorTextField(
          label: 'Speaker Name',
          initialValue: speaker.name,
          onChanged: (v) => speaker.name = v,
        ),
        InspectorDropdownField<SpeakerType>(
          label: 'Type',
          value: speaker.type,
          options: SpeakerType.values,
          labelBuilder: (t) => t.label,
          onChanged: (v) => speaker.type = v,
        ),
        InspectorDropdownField<SpeakerChannel>(
          label: 'Channel',
          value: speaker.channel,
          options: SpeakerChannel.values,
          labelBuilder: (c) => c.label,
          onChanged: (v) => speaker.channel = v,
        ),
        InspectorSwitchField(
          label: 'Enabled',
          value: speaker.enabled,
          onChanged: (v) {
            speaker.enabled = v;
            widget.onChanged();
          },
        ),
        InspectorTextField(
          label: 'Position X',
          initialValue: speaker.position.x.toString(),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (v) {
            final p = double.tryParse(v);
            if (p != null) speaker.position.x = p;
          },
        ),
        InspectorTextField(
          label: 'Position Y',
          initialValue: speaker.position.y.toString(),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (v) {
            final p = double.tryParse(v);
            if (p != null) speaker.position.y = p;
          },
        ),
        InspectorTextField(
          label: 'Position Z',
          initialValue: speaker.position.z.toString(),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (v) {
            final p = double.tryParse(v);
            if (p != null) speaker.position.z = p;
          },
        ),
        InspectorTextField(
          label: 'Rotation Y (deg)',
          initialValue: speaker.rotationY.toString(),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          onChanged: (v) {
            final p = double.tryParse(v);
            if (p != null) speaker.rotationY = p;
          },
        ),
        // --- Optional technical specifications (PART 6) ---
        InspectorTextField(
          label: 'Rated Power (W) — optional',
          initialValue: specsText(speaker.specs.ratedPowerWatts),
          keyboardType: TextInputType.number,
          onChanged: (v) => speaker.specs.ratedPowerWatts = v.isEmpty ? null : double.tryParse(v),
        ),
        InspectorTextField(
          label: 'Frequency Range Low (Hz) — optional',
          initialValue: specsText(speaker.specs.frequencyRangeLowHz),
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              speaker.specs.frequencyRangeLowHz = v.isEmpty ? null : double.tryParse(v),
        ),
        InspectorTextField(
          label: 'Frequency Range High (Hz) — optional',
          initialValue: specsText(speaker.specs.frequencyRangeHighHz),
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              speaker.specs.frequencyRangeHighHz = v.isEmpty ? null : double.tryParse(v),
        ),
        InspectorTextField(
          label: 'Sensitivity (dB) — optional',
          initialValue: specsText(speaker.specs.sensitivityDb),
          keyboardType: TextInputType.number,
          onChanged: (v) => speaker.specs.sensitivityDb = v.isEmpty ? null : double.tryParse(v),
        ),
      ],
    );
  }
}
