import 'package:flutter/material.dart';
import '../../models/acoustics_config.dart';
import '../../models/theatre_configuration.dart';

class AcousticsTab extends StatefulWidget {
  final TheatreConfiguration config;
  final VoidCallback onChanged;

  const AcousticsTab({super.key, required this.config, required this.onChanged});

  @override
  State<AcousticsTab> createState() => _AcousticsTabState();
}

class _AcousticsTabState extends State<AcousticsTab> {
  @override
  Widget build(BuildContext context) {
    final acoustics = widget.config.acoustics;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Room / Acoustic Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Spatial-audio simulation parameters and surface materials for audio engineering.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 20),
        _surfaceSection('Floor Surface', acoustics.floor),
        const SizedBox(height: 16),
        _surfaceSection('Wall Treatments', acoustics.walls),
        const SizedBox(height: 16),
        _surfaceSection('Ceiling Baffles', acoustics.ceiling),
        const SizedBox(height: 24),
        _panelsSection(acoustics),
        const SizedBox(height: 24),
        _curtainSection(acoustics.curtain),
      ],
    );
  }

  Widget _surfaceSection(String title, SurfaceAcoustics surface) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('$title-material'),
            initialValue: surface.material,
            style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Material Name',
              labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF14141A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
              isDense: true,
            ),
            onChanged: (v) {
              surface.material = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Absorption Coefficient', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              Text(
                surface.absorptionCoefficient.toStringAsFixed(2),
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            value: surface.absorptionCoefficient,
            min: 0,
            max: 1,
            activeColor: const Color(0xFFD4AF37),
            inactiveColor: const Color(0xFF22222A),
            onChanged: (v) => setState(() {
              surface.absorptionCoefficient = v;
              widget.onChanged();
            }),
          ),
        ],
      ),
    );
  }

  Widget _panelsSection(AcousticsConfig acoustics) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Acoustic Panels',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    acoustics.panels.add(
                      AcousticPanelConfig(
                        id: 'panel-${DateTime.now().millisecondsSinceEpoch}',
                        material: 'Acoustic Foam',
                        coverageSqm: 2.0,
                      ),
                    );
                  });
                  widget.onChanged();
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Panel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (acoustics.panels.isEmpty)
            const Text('No panels installed.', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12))
          else
            for (int i = 0; i < acoustics.panels.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: Color(0xFF1E1E26)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Panel ${i + 1} (${acoustics.panels[i].material}, ${acoustics.panels[i].coverageSqm.toStringAsFixed(1)} m²)',
                      style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    onPressed: () {
                      setState(() => acoustics.panels.removeAt(i));
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  Widget _curtainSection(CurtainConfig curtain) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stage Curtain Acoustics',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Has Stage Curtain', style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5)),
            value: curtain.enabled,
            activeThumbColor: const Color(0xFFD4AF37),
            onChanged: (v) => setState(() {
              curtain.enabled = v;
              widget.onChanged();
            }),
          ),
          if (curtain.enabled) ...[
            const SizedBox(height: 12),
            TextFormField(
              initialValue: curtain.material,
              style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Curtain Material',
                labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF14141A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                isDense: true,
              ),
              onChanged: (v) {
                curtain.material = v;
                widget.onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}
