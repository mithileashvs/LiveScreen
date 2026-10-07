import 'package:flutter/material.dart';

abstract class InspectorField {
  final String label;
  const InspectorField(this.label);

  Widget build();
}

class InspectorTextField extends InspectorField {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;

  const InspectorTextField({
    required String label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
  }) : super(label);

  @override
  Widget build() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11.5)),
        const SizedBox(height: 5),
        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF14141A),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF22222A))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class InspectorDropdownField<T> extends InspectorField {
  final T value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const InspectorDropdownField({
    required String label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  }) : super(label);

  @override
  Widget build() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11.5)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF14141A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF22222A)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF14141A),
              style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
              items: [
                for (final option in options)
                  DropdownMenuItem<T>(
                    value: option,
                    child: Text(labelBuilder(option)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class InspectorSwitchField extends InspectorField {
  final bool value;
  final ValueChanged<bool> onChanged;

  const InspectorSwitchField({
    required String label,
    required this.value,
    required this.onChanged,
  }) : super(label);

  @override
  Widget build() {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13))),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFFD4AF37),
          activeTrackColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class ObjectInspectorPanel extends StatelessWidget {
  final String objectId;
  final String title;
  final String? subtitle;
  final List<InspectorField> fields;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  const ObjectInspectorPanel({
    super.key,
    required this.objectId,
    required this.title,
    this.subtitle,
    required this.fields,
    required this.onSave,
    this.onDelete,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD4AF37), letterSpacing: 1),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF))),
                    ],
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF), size: 18),
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final field in fields) ...[
            KeyedSubtree(
              key: ValueKey('$objectId::${field.label}'),
              child: field.build(),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              if (onDelete != null) ...[
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
