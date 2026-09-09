import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A labeled numeric text field shared by every admin tab, so each screen
/// isn't redefining its own near-identical version (PART 19).
///
/// Keyed by [label] alone (not by the current value) so Flutter keeps the
/// same underlying text-field State across parent rebuilds — typing stays
/// smooth and the cursor doesn't jump, even though the model value changes
/// on every keystroke.
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
      child: TextFormField(
        key: ValueKey(label),
        initialValue: value.toString(),
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption,
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) {
          final parsed = double.tryParse(text);
          if (parsed == null) return;
          if (validator != null && validator!(parsed) != null) return;
          onChanged(parsed);
        },
      ),
    );
  }
}
