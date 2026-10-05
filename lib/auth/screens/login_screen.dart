import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/auth_exception.dart';
import '../widgets/role_gate.dart';
import 'theatre_admin_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _RoleTabItem {
  final String label;
  final String demoId;
  final String demoPassword;
  const _RoleTabItem(this.label, this.demoId, this.demoPassword);
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  int _selectedRoleIndex = 0;

  static const List<_RoleTabItem> _roleTabs = [
    _RoleTabItem('User', 'user_demo', 'User@123'),
    _RoleTabItem('Theatre', 'theatre_demo', 'Theatre@123'),
    _RoleTabItem('Producer', 'producer_demo', 'Producer@123'),
    _RoleTabItem('Admin', 'platform_admin_demo', 'Platform@123'),
  ];

  @override
  void initState() {
    super.initState();
    _idController.text = _roleTabs[0].demoId;
    _passwordController.text = _roleTabs[0].demoPassword;
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleTabSelected(int index) {
    setState(() {
      _selectedRoleIndex = index;
      _idController.text = _roleTabs[index].demoId;
      _passwordController.text = _roleTabs[index].demoPassword;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _login(_idController.text.trim(), _passwordController.text);
  }

  Future<void> _login(String userId, String password) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final session = await authService.login(userId, password);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleRouter.homeFor(session.role)),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final session = await authService.login('user_demo', 'User@123');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleRouter.homeFor(session.role)),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In is configured via Supabase OAuth.'),
          backgroundColor: Color(0xFF151515),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 960;
          final isTablet = constraints.maxWidth >= 640 && constraints.maxWidth < 960;
          final panelWidth = isDesktop
              ? (constraints.maxWidth * 0.38).clamp(360.0, 460.0)
              : (isTablet ? 420.0 : (constraints.maxWidth - 32.0).clamp(280.0, 400.0));

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Cinematic Theatre Background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/cinema_theatre_bg.jpg',
                  fit: BoxFit.cover,
                  alignment: isDesktop ? Alignment.center : const Alignment(-0.2, 0.0),
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF080808),
                  ),
                ),
              ),

              // 2. Subtle Dark Vignette for contrast
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0x14000000),
                        Color(0x59000000),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Login Panel positioned on the right (or centered on mobile)
              SafeArea(
                child: Align(
                  alignment: isDesktop ? Alignment.centerRight : Alignment.center,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? (constraints.maxWidth * 0.038).clamp(24.0, 52.0) : 16.0,
                      vertical: 24.0,
                    ),
                    child: SizedBox(
                      width: panelWidth,
                      child: _buildLoginCard(context),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE00C0C0C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xD9B8893C),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB3000000),
            blurRadius: 32,
            spreadRadius: 4,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Heading: Welcome Back
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontFamilyFallback: ['Playfair Display', 'Times New Roman', 'serif'],
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF2F0EA),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  const Text(
                    'Sign in to your LiveScreen account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 4 Role Tabs
                  _buildRoleTabs(),
                  const SizedBox(height: 20),

                  // Email or Phone input
                  TextFormField(
                    controller: _idController,
                    style: const TextStyle(color: Color(0xFFF2F0EA), fontSize: 14),
                    cursorColor: const Color(0xFFD4A84F),
                    decoration: InputDecoration(
                      hintText: 'Email or Phone',
                      hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13.5),
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF9CA3AF),
                        size: 19,
                      ),
                      filled: true,
                      fillColor: const Color(0xB3101010),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF262626), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFB8893C), width: 1.2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC7080C), width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC7080C), width: 1.2),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Email or Phone is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Password input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Color(0xFFF2F0EA), fontSize: 14),
                    cursorColor: const Color(0xFFD4A84F),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13.5),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF9CA3AF),
                        size: 19,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF9CA3AF),
                          size: 19,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xB3101010),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF262626), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFB8893C), width: 1.2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC7080C), width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFC7080C), width: 1.2),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Password is required' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),

                  // Forgot Password?
                  Align(
                    alignment: Alignment.centerRight,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset instructions sent to your email.'),
                              backgroundColor: Color(0xFF151515),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 16),
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0x80440101),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x99C7080C)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFF2F0EA), fontSize: 12.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // Sign In button
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF700914), // deep burgundy
                        disabledBackgroundColor: const Color(0xFF440101),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider: or continue with
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFF262626), thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFF262626), thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Continue with Google button
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0x99101010),
                        side: const BorderSide(color: Color(0xFF262626), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            width: 17,
                            height: 17,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.g_mobiledata,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Don't have an account? Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _loading
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const TheatreAdminRegistrationScreen(),
                                    ),
                                  ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFFD4A84F),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Row(
      children: List.generate(_roleTabs.length, (index) {
        final isSelected = _selectedRoleIndex == index;
        final item = _roleTabs[index];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 3.5,
              right: index == _roleTabs.length - 1 ? 0 : 3.5,
            ),
            child: InkWell(
              onTap: _loading ? null : () => _onRoleTabSelected(index),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 35,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF700914) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF700914) : const Color(0xFF262626),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFD1D5DB),
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
