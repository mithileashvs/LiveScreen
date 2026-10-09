import 'package:flutter/material.dart';
import '../models/room_config.dart';
import '../models/theatre_configuration.dart';
import '../services/theatre_admin_repository.dart';
import '../services/theatre_repository.dart';
import '../capture/ui/venue_capture_screen.dart';

/// "Add Theatre" Screen for Theatre Admin.
/// Styled in the master dark cinematic design language (Black, Gold & Burgundy).
class CreateTheatreScreen extends StatefulWidget {
  const CreateTheatreScreen({super.key});

  @override
  State<CreateTheatreScreen> createState() => _CreateTheatreScreenState();
}

class _CreateTheatreScreenState extends State<CreateTheatreScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _hallController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _contactController = TextEditingController();
  final _widthController = TextEditingController(text: '20');
  final _lengthController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '8');
  final _authorizationNoteController = TextEditingController();
  bool _confirmedAuthorized = false;

  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _hallController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _contactController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _authorizationNoteController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _validateDimension(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    return RoomConfig.validateDimension(label, parsed);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_confirmedAuthorized) {
      setState(() => _errorMessage = 'Confirm you are authorized to manage this theatre to continue.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final basicInfo = TheatreBasicInfo(
        name: _nameController.text.trim(),
        hallName: _hallController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        contactNumber: _contactController.text.trim(),
      );

      final room = RoomConfig(
        width: double.parse(_widthController.text),
        length: double.parse(_lengthController.text),
        height: double.parse(_heightController.text),
      );

      final config = await theatreAdminRepository.addTheatre(basicInfo);
      config.room = room;
      await theatreRepository.saveTheatre(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theatre submitted for Platform Admin verification.'),
            backgroundColor: Color(0xFF16161D),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      appBar: AppBar(
        title: const Text('Add Theatre', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: const Color(0xFF0C0C10),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFD4AF37)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            const Text(
              'Theatre Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
            ),
            const SizedBox(height: 14),
            _field(_nameController, 'Theatre / Complex Name *', validator: _requiredText),
            _field(_hallController, 'Screen / Hall Name (e.g. Screen 1 - Main) *', validator: _requiredText),
            _field(_descriptionController, 'Description', maxLines: 2),
            _field(_addressController, 'Address *', validator: _requiredText),
            Row(
              children: [
                Expanded(child: _field(_cityController, 'City *', validator: _requiredText)),
                const SizedBox(width: 12),
                Expanded(child: _field(_stateController, 'State *', validator: _requiredText)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(_countryController, 'Country *', validator: _requiredText)),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _contactController,
                    'Contact Number *',
                    keyboardType: TextInputType.phone,
                    validator: _requiredText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Room Dimensions (metres)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.document_scanner_outlined, color: Color(0xFFD4AF37), size: 16),
                  label: const Text('Capture with AI', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF14141A),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFF2E2E38)),
                    ),
                  ),
                  onPressed: () {
                    final baselineRoom = RoomConfig(
                      width: double.tryParse(_widthController.text.trim()) ?? 20.0,
                      length: double.tryParse(_lengthController.text.trim()) ?? 25.0,
                      height: double.tryParse(_heightController.text.trim()) ?? 8.0,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VenueCaptureScreen(
                          theatreId: 'draft-${DateTime.now().millisecondsSinceEpoch}',
                          isDraftTheatre: true,
                          initialConfig: TheatreConfiguration(
                            id: 'draft-temp',
                            basicInfo: TheatreBasicInfo(
                              name: _nameController.text.trim(),
                              hallName: _hallController.text.trim(),
                            ),
                            room: baselineRoom,
                          ),
                          onConfigurationUpdated: (updated) {
                            setState(() {
                              _widthController.text = updated.room.width.toString();
                              _lengthController.text = updated.room.length.toString();
                              _heightController.text = updated.room.height.toString();
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _widthController,
                    'Width (m) *',
                    keyboardType: TextInputType.number,
                    validator: (v) => _validateDimension(v, 'Width'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _lengthController,
                    'Length (m) *',
                    keyboardType: TextInputType.number,
                    validator: (v) => _validateDimension(v, 'Length'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _heightController,
                    'Height (m) *',
                    keyboardType: TextInputType.number,
                    validator: (v) => _validateDimension(v, 'Height'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Ownership / Authorization',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Reviewed by Platform Admin before this theatre becomes fully manageable. '
              'Your registered business credentials are automatically attached.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 14),
            _field(
              _authorizationNoteController,
              'Ownership / authorization details (e.g. role, lease agreement reference)',
              maxLines: 3,
            ),
            Theme(
              data: ThemeData.dark().copyWith(
                unselectedWidgetColor: const Color(0xFF71717A),
              ),
              child: CheckboxListTile(
                value: _confirmedAuthorized,
                activeColor: const Color(0xFFD4AF37),
                checkColor: Colors.black,
                onChanged: (v) => setState(() => _confirmedAuthorized = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I confirm I am authorized to manage this theatre on LiveScreen.',
                  style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF29080A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDC2626)),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFF87171), fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Submit for Verification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF14141A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDC2626))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
