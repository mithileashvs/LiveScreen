import 'package:flutter/material.dart';
import '../../models/seat_config.dart';
import '../../models/theatre_configuration.dart';
import '../../services/seat_layout_generator.dart';
import '../../widgets/admin_number_field.dart';
import '../../widgets/object_inspector_panel.dart';
import '../../widgets/visual_theatre_canvas.dart';

class SeatingTab extends StatefulWidget {
  final TheatreConfiguration config;
  final VoidCallback onChanged;

  const SeatingTab({super.key, required this.config, required this.onChanged});

  @override
  State<SeatingTab> createState() => _SeatingTabState();
}

class _SeatingTabState extends State<SeatingTab> {
  late SeatLayoutParams _params;
  SeatConfig? _selectedSeat;
  bool _showLayoutForm = false;

  @override
  void initState() {
    super.initState();
    _params = widget.config.lastSeatLayout ?? SeatLayoutParams();
  }

  void _generate() {
    final generated = SeatLayoutGenerator.generate(_params);
    widget.config.seats = generated;
    widget.config.lastSeatLayout = _params;
    _selectedSeat = null;
    widget.onChanged();
  }

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
                      'Auditorium Seating Grid',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${config.seats.length} seats configured · Tap a seat to inspect or customize',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showLayoutForm = !_showLayoutForm),
                icon: Icon(
                  _showLayoutForm ? Icons.expand_less : Icons.tune,
                  size: 16,
                  color: const Color(0xFFD4AF37),
                ),
                label: Text(
                  _showLayoutForm ? 'Hide Settings' : 'Layout Settings',
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
        if (_showLayoutForm) Flexible(child: SingleChildScrollView(child: _buildLayoutForm())),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: config.seats.isEmpty
                ? const Center(
                    child: Text(
                      'No seats yet. Open Layout Settings above and tap Generate Seats.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                : VisualTheatreCanvas(
                    room: config.room,
                    screen: config.screen,
                    seats: config.seats,
                    speakers: config.speakers,
                    selectedId: _selectedSeat?.id,
                    onSelectSeat: (seat) => setState(() => _selectedSeat = seat),
                    onSelectSpeaker: (_) {},
                    onSelectScreen: () {},
                    onMoveSpeaker: (_, _) {},
                    onMoveScreen: (_) {},
                  ),
          ),
        ),
        if (_selectedSeat != null)
          Flexible(child: SingleChildScrollView(child: _buildSeatInspector(_selectedSeat!))),
      ],
    );
  }

  Widget _buildLayoutForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AdminNumberField(
                  label: 'Rows',
                  value: _params.rows.toDouble(),
                  onChanged: (v) => _params.rows = v.round().clamp(1, 100).toInt(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminNumberField(
                  label: 'Seats / Row',
                  value: _params.seatsPerRow.toDouble(),
                  onChanged: (v) => _params.seatsPerRow = v.round().clamp(1, 100).toInt(),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AdminNumberField(
                  label: 'Row Spacing (m)',
                  value: _params.rowSpacing,
                  onChanged: (v) => _params.rowSpacing = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminNumberField(
                  label: 'Seat Spacing (m)',
                  value: _params.seatSpacing,
                  onChanged: (v) => _params.seatSpacing = v,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AdminNumberField(
                  label: 'Seat Width (m)',
                  value: _params.seatWidth,
                  onChanged: (v) => _params.seatWidth = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminNumberField(
                  label: 'Seat Depth (m)',
                  value: _params.seatDepth,
                  onChanged: (v) => _params.seatDepth = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminNumberField(
                  label: 'Seat Height (m)',
                  value: _params.seatHeight,
                  onChanged: (v) => _params.seatHeight = v,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AdminNumberField(
                  label: 'Row Elevation (m)',
                  value: _params.rowElevation,
                  onChanged: (v) => _params.rowElevation = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminNumberField(
                  label: 'Start Z (m from screen)',
                  value: _params.startPosition.z,
                  onChanged: (v) => _params.startPosition.z = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                widget.config.seats.isEmpty ? 'Generate Seats' : 'Regenerate Seats',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
          if (widget.config.seats.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Regenerating replaces the current seat grid with a fresh one using these settings.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeatInspector(SeatConfig seat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ObjectInspectorPanel(
        objectId: seat.id,
        title: 'Selected Seat',
        subtitle: seat.id,
        fields: [
          InspectorDropdownField<SeatCategory>(
            label: 'Category',
            value: seat.category,
            options: SeatCategory.values,
            labelBuilder: (c) => c.name[0].toUpperCase() + c.name.substring(1),
            onChanged: (v) => seat.category = v,
          ),
          InspectorTextField(
            label: 'Position X',
            initialValue: seat.position.x.toString(),
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) seat.position.x = parsed;
            },
          ),
          InspectorTextField(
            label: 'Position Y',
            initialValue: seat.position.y.toString(),
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) seat.position.y = parsed;
            },
          ),
          InspectorTextField(
            label: 'Position Z',
            initialValue: seat.position.z.toString(),
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            onChanged: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) seat.position.z = parsed;
            },
          ),
        ],
        onSave: () {
          widget.onChanged();
          setState(() => _selectedSeat = null);
        },
        onClose: () => setState(() => _selectedSeat = null),
      ),
    );
  }
}
