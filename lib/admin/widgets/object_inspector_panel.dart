import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// One editable row shown in an [ObjectInspectorPanel] (PART 9). Kept as a
/// tiny type hierarchy rather than a big config map, so adding a new field
/// kind later (e.g. a slider) is a new subclass, not a rewrite.
///
/// Each subtype builds its OWN editor widget via [build] rather than
/// [ObjectInspectorPanel] switching on `is SomeFieldType` from the outside.
/// This matters specifically for [InspectorDropdownField]'s generic type
/// parameter T: a bare `field is InspectorDropdownField` check (with no
/// type argument) promotes the reference to `InspectorDropdownField<dynamic>`,
/// and Dart then has to insert an implicit runtime cast when reading a
/// T-typed member back off it — e.g. `String Function(SpeakerType)` being
/// coerced down to `String Function(dynamic)`. That cast is unsound
/// (function parameters are contravariant, and `dynamic` is not a subtype
/// of `SpeakerType`), so it throws a `TypeError` at the exact point the
/// dropdown tries to render — which is exactly the runtime error this
/// fixes. Letting each field build itself keeps T inside the generic
/// class's own scope, where it's always concretely known, so that cast
/// never has to happen.
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
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
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
    // T is concretely known right here (e.g. SpeakerType, ScreenType,
    // SeatCategory) — DropdownButtonFormField<T> and labelBuilder(option)
    // both stay properly typed the whole way through, no dynamic involved.
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: [
        for (final option in options)
          DropdownMenuItem<T>(
            value: option,
            child: Text(labelBuilder(option), style: AppTextStyles.body),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
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
        Expanded(child: Text(label, style: AppTextStyles.body)),
        Switch(
          value: value,
          activeThumbColor: AppColors.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Shows a selected object's editable properties (PART 9: "SELECTED SPEAKER
/// / SELECTED SEAT / SCREEN" panels), driven entirely by a list of
/// [InspectorField]s so the same widget serves seats, speakers, and the
/// screen without three near-duplicate panels.
///
/// [objectId] MUST uniquely identify whichever object is currently shown
/// (e.g. a seat or speaker ID) — it's used to key every field's live text
/// state, so switching from one object to another resets each field to
/// that new object's values instead of a stale, previously-typed one.
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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
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
                    Text(title.toUpperCase(), style: AppTextStyles.caption),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.subheading),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final field in fields) ...[
            KeyedSubtree(
              key: ValueKey('$objectId::${field.label}'),
              // field.build() — polymorphic, no external type switch, no
              // dynamic cast (see the class-level doc comment above).
              child: field.build(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (onDelete != null) ...[
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              ElevatedButton(onPressed: onSave, child: const Text('Save')),
            ],
          ),
        ],
      ),
    );
  }
}
