import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../models/room_config.dart';
import '../models/theatre_configuration.dart';
import '../services/theatre_repository.dart';

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
  final _widthController = TextEditingController(text: '20');
  final _lengthController = TextEditingController(text: '30');
  final _heightController = TextEditingController(text: '8');

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _hallController.dispose();
    _descriptionController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
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

    setState(() => _saving = true);

    final basicInfo = TheatreBasicInfo(
      name: _nameController.text.trim(),
      hallName: _hallController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    final config = await theatreRepository.createTheatre(basicInfo);
    config.room = RoomConfig(
      width: double.parse(_widthController.text),
      length: double.parse(_lengthController.text),
      height: double.parse(_heightController.text),
    );
    await theatreRepository.saveTheatre(config);

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Theatre')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Basic Information', style: AppTextStyles.subheading),
            const SizedBox(height: 12),
            _field(_nameController, 'Theatre Name', validator: _requiredText),
            _field(_hallController, 'Hall Name / Number', validator: _requiredText),
            _field(_descriptionController, 'Description', maxLines: 3),
            const SizedBox(height: 24),
            const Text('Room Dimensions (metres)', style: AppTextStyles.subheading),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _widthController,
                    'Width',
                    keyboardType: TextInputType.number,
                    validator: (v) => _validateDimension(v, 'Width'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _lengthController,
                    'Length',
                    keyboardType: TextInputType.number,
                    validator: (v) => _validateDimension(v, 'Length'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _heightController,
                    'Height',
                    keyboardType: TextInputType.number,
                    validator: (v) => _validateDimension(v, 'Height'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Create Theatre'),
            ),
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
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
