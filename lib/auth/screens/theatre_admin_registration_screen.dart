import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../admin/services/theatre_admin_repository.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/auth_exception.dart';
import '../widgets/role_gate.dart';

/// Theatre Admin registration (task section 2). Two distinct steps, run
/// back-to-back on submit:
///   A. account credentials — [AuthService.signUp] creates the Supabase
///      Auth user + `profiles` row (role='theatre_admin').
///   B. operator/business info — [TheatreAdminRepository.registerAdmin]
///      creates the `theatre_admins` identity row (generates the admin
///      code server-side) for the account just created.
///
/// Deliberately asks only for what the existing verification model
/// actually uses (task: "do not collect unnecessary sensitive
/// information") — no documents/uploads, since nothing else in this app
/// has file-upload infrastructure yet; Platform Admin's review screen
/// shows exactly these fields back to reviewers.
///
/// This does NOT grant ownership of any theatre — registering only
/// creates the admin identity. Adding a theatre (and submitting it for
/// ownership verification) happens afterward, from "My Theatres" ->
/// "+ Add Theatre".
class TheatreAdminRegistrationScreen extends StatefulWidget {
  const TheatreAdminRegistrationScreen({super.key});

  @override
  State<TheatreAdminRegistrationScreen> createState() => _TheatreAdminRegistrationScreenState();
}

class _TheatreAdminRegistrationScreenState extends State<TheatreAdminRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // A. account credentials
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // B. operator/business information
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  String? _required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      // A. account credentials.
      final session = await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: UserRole.theatreAdmin,
        displayName: _fullNameController.text.trim(),
      );

      // B. operator/business info — the account above now exists and is
      // signed in, so this insert satisfies theatre_admins_insert_own's
      // `auth.uid() = profile_id` check.
      try {
        await theatreAdminRepository.registerAdmin(
          organizationName: _organizationController.text.trim(),
          businessAddress: _addressController.text.trim(),
          city: _cityController.text.trim(),
          country: _countryController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      } catch (e) {
        // The auth account was created successfully even if this second
        // step fails (e.g. a transient network error) — don't strand the
        // person on an error with no way forward. AdminDashboardScreen
        // handles "logged in as theatre_admin but no admin identity yet"
        // by prompting them to finish registration, rather than crashing.
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => RoleRouter.homeFor(session.role)),
          (route) => false,
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleRouter.homeFor(session.role)),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Register as Theatre Admin')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Account', style: AppTextStyles.subheading),
                    const SizedBox(height: 4),
                    const Text(
                      'Used to sign in — this is separate from your business information below.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 12),
                    _field(_emailController, 'Email', keyboardType: TextInputType.emailAddress,
                        validator: (v) => _required(v, 'Email')),
                    _field(
                      _passwordController,
                      'Password',
                      obscureText: _obscurePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Use at least 8 characters';
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    _field(_confirmPasswordController, 'Confirm password', obscureText: _obscurePassword,
                        validator: (v) => _required(v, 'Confirm password')),
                    const SizedBox(height: 20),
                    const Text('Operator / business information', style: AppTextStyles.subheading),
                    const SizedBox(height: 4),
                    const Text(
                      'Reviewed by Platform Admin when you submit a theatre for ownership verification.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 12),
                    _field(_fullNameController, 'Full name', validator: (v) => _required(v, 'Full name')),
                    _field(_phoneController, 'Phone', keyboardType: TextInputType.phone,
                        validator: (v) => _required(v, 'Phone')),
                    _field(_organizationController, 'Organization / business name',
                        validator: (v) => _required(v, 'Organization name')),
                    _field(_addressController, 'Business address', maxLines: 2,
                        validator: (v) => _required(v, 'Business address')),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_cityController, 'City', validator: (v) => _required(v, 'City')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child:
                              _field(_countryController, 'Country', validator: (v) => _required(v, 'Country')),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
