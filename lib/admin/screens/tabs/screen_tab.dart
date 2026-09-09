import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../models/screen_config.dart';
import '../../models/theatre_configuration.dart';
import '../../widgets/object_inspector_panel.dart';
import '../../widgets/visual_theatre_canvas.dart';

class ScreenTab extends StatefulWidget {
  final TheatreConfiguration config;
  final VoidCallback onChanged;

  const ScreenTab({super.key, required this.config, required this.onChanged});

  @override
  State<ScreenTab> createState() => _ScreenTabState();
}

class _ScreenTabState extends State<ScreenTab> {
  bool _screenSelected = false;

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: VisualTheatreCanvas(
              room: config.room,
              screen: config.screen,
              seats: config.seats,
              speakers: config.speakers,
              selectedId: _screenSelected ? '__screen__' : null,
              onSelectSeat: (_) {},
              onSelectSpeaker: (_) {},
              onSelectScreen: () => setState(() => _screenSelected = true),
              onMoveSpeaker: (_, _) {},
              onMoveScreen: (delta) {
                config.screen.position.x += delta.dx;
                config.screen.position.z += delta.dy;
                widget.onChanged();
              },
            ),
          ),
        ),
        if (_screenSelected)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ObjectInspectorPanel(
              objectId: '__screen__',
              title: 'Screen',
              fields: [
                InspectorTextField(
                  label: 'Width (m)',
                  initialValue: config.screen.width.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) {
                      config.screen.width = parsed;
                      widget.onChanged();
                    }
                  },
                ),
                InspectorTextField(
                  label: 'Height (m)',
                  initialValue: config.screen.height.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) {
                      config.screen.height = parsed;
                      widget.onChanged();
                    }
                  },
                ),
                InspectorTextField(
                  label: 'Position X',
                  initialValue: config.screen.position.x.toString(),
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) {
                      config.screen.position.x = parsed;
                      widget.onChanged();
                    }
                  },
                ),
                InspectorTextField(
                  label: 'Position Y',
                  initialValue: config.screen.position.y.toString(),
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) {
                      config.screen.position.y = parsed;
                      widget.onChanged();
                    }
                  },
                ),
                InspectorTextField(
                  label: 'Position Z',
                  initialValue: config.screen.position.z.toString(),
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) {
                      config.screen.position.z = parsed;
                      widget.onChanged();
                    }
                  },
                ),
                InspectorTextField(
                  label: 'Rotation Y (deg)',
                  initialValue: config.screen.rotationY.toString(),
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed != null) {
                      config.screen.rotationY = parsed;
                      widget.onChanged();
                    }
                  },
                ),
                InspectorDropdownField<ScreenType>(
                  label: 'Screen Type',
                  value: config.screen.type,
                  options: ScreenType.values,
                  labelBuilder: (t) => t.label,
                  onChanged: (v) {
                    config.screen.type = v;
                    widget.onChanged();
                  },
                ),
              ],
              onSave: () {
                widget.onChanged();
                setState(() => _screenSelected = false);
              },
              onClose: () => setState(() => _screenSelected = false),
            ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tap the screen above to edit its size, position, and type. Drag it to reposition.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
