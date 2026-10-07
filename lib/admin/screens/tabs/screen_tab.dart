import 'package:flutter/material.dart';
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
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          color: const Color(0xFF0F0F12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Projection Screen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${config.screen.type.label} · ${config.screen.width.toStringAsFixed(1)}m × ${config.screen.height.toStringAsFixed(1)}m · Tap to customize, drag to reposition',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _screenSelected = !_screenSelected),
                icon: Icon(
                  _screenSelected ? Icons.check : Icons.tune,
                  size: 16,
                  color: const Color(0xFFD4AF37),
                ),
                label: Text(
                  _screenSelected ? 'Done' : 'Edit Screen',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0x66D4AF37)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
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
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E1E26)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.info_outline, size: 16, color: Color(0xFFD4AF37)),
                SizedBox(width: 8),
                Text(
                  'Tap the gold screen above to customize its physical dimensions and curvature, or drag to reposition.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
