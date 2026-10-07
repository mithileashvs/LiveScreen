import 'package:flutter/material.dart';

/// A labeled numeric text field shared by admin tabs in the dark cinematic style.
class AdminNumberField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? Function(double)? validator;

  const AdminNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey(label),
            initialValue: value.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF14141A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onChanged: (text) {
              final parsed = double.tryParse(text);
              if (parsed == null) return;
              if (validator != null && validator!(parsed) != null) return;
              onChanged(parsed);
            },
          ),
        ],
      ),
    );
  }
}
