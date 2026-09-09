import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../models/acoustics_config.dart';
import '../../models/screen_config.dart';
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
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Room / Acoustic Properties', style: AppTextStyles.subheading),
        const SizedBox(height: 4),
        const Text(
          'This is stored for the future spatial-audio engine — no simulation '
          'runs on this data yet.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 20),
        _surfaceSection('Floor', acoustics.floor),
        const SizedBox(height: 16),
        _surfaceSection('Walls', acoustics.walls),
        const SizedBox(height: 16),
        _surfaceSection('Ceiling', acoustics.ceiling),
        const SizedBox(height: 24),
        _panelsSection(acoustics),
        const SizedBox(height: 24),
        _curtainSection(acoustics.curtain),
      ],
    );
  }

  Widget _surfaceSection(String title, SurfaceAcoustics surface) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.subheading),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey('$title-material'),
            initialValue: surface.material,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Material',
              labelStyle: AppTextStyles.caption,
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              surface.material = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Absorption Coefficient: ${surface.absorptionCoefficient.toStringAsFixed(2)}',
            style: AppTextStyles.caption,
          ),
          Slider(
            value: surface.absorptionCoefficient,
            min: 0,
            max: 1,
            activeColor: AppColors.accent,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Acoustic Panels', style: AppTextStyles.subheading)),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    acoustics.panels.add(AcousticPanelConfig(
                      id: 'panel_${acoustics.panels.length + 1}',
                      position: Position3(x: 0, y: 2, z: 0),
                    ));
                    widget.onChanged();
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (acoustics.panels.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No acoustic panels configured.', style: AppTextStyles.caption),
            ),
          for (final panel in acoustics.panels)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: ValueKey('${panel.id}-material'),
                      initialValue: panel.material,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Material',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        panel.material = v;
                        widget.onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('${panel.id}-coverage'),
                      initialValue: panel.coverageSqm.toString(),
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Coverage m²',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          panel.coverageSqm = parsed;
                          widget.onChanged();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        acoustics.panels.removeWhere((p) => p.id == panel.id);
                        widget.onChanged();
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _curtainSection(CurtainConfig curtain) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Curtains', style: AppTextStyles.subheading)),
              Switch(
                value: curtain.enabled,
                activeThumbColor: AppColors.accent,
                onChanged: (v) => setState(() {
                  curtain.enabled = v;
                  widget.onChanged();
                }),
              ),
            ],
          ),
          if (curtain.enabled) ...[
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('curtain-material'),
              initialValue: curtain.material,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Material',
                isDense: true,
                border: OutlineInputBorder(),
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
