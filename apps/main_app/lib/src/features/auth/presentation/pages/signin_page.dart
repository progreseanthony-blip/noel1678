import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noel_core/noel_core.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberDevice = false;
  String? _errorMessage;

  void _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Attempting sign in with ${EnvConfig.supabaseUrl}');
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        debugPrint('Sign in successful for: ${response.user!.email}');
        context.go('/');
      } else {
        debugPrint('Sign in failed: No user returned');
      }
    } on AuthException catch (e) {
      debugPrint('AuthException: ${e.message}');
      setState(() => _errorMessage = e.message);
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      setState(() => _errorMessage = 'Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── Left Hero Panel (hidden on narrow screens) ──
          if (isWide)
            Expanded(
              child: _HeroPanel(),
            ),

          // ── Right Form Panel ──
          Expanded(
            child: _buildFormPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Logo header
          Padding(
            padding: const EdgeInsets.only(top: 32, left: 40, right: 40),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.golf_course, color: AppTheme.primaryGreen, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Global Golf Construction',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title section
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.manrope(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your credentials to access the project dashboard.',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          color: AppTheme.slate500,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Error message
                      if (_errorMessage != null && _errorMessage!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.manrope(
                                    color: const Color(0xFF991B1B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Email field
                      Text(
                        'Professional Email',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.slate900),
                        decoration: InputDecoration(
                          hintText: 'name@company.com',
                          prefixIcon: Icon(Icons.mail_outline, color: AppTheme.slate400, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.slate700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.slate900),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.slate400, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppTheme.slate400,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        onSubmitted: (_) => _signIn(),
                      ),
                      const SizedBox(height: 16),

                      // Remember checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: Checkbox(
                              value: _rememberDevice,
                              onChanged: (v) => setState(() => _rememberDevice = v ?? false),
                              activeColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: BorderSide(color: AppTheme.slate400, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Remember this device for 30 days',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppTheme.slate500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Sign In button
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 6,
                            shadowColor: AppTheme.primaryGreen.withOpacity(0.35),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22, width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In to Dashboard',
                                      style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Divider + Sign Up link
                      Container(
                        padding: const EdgeInsets.only(top: 24),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account yet? ",
                              style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/signup'),
                              child: Text(
                                'Sign up',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 8),
            child: Text(
              '© 2024 Global Golf Construction Company. All rights reserved.',
              style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Hero Panel Widget ──
class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.slate900,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/golf_hero.png',
            fit: BoxFit.cover,
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.backgroundDark.withOpacity(0.85),
                ],
                stops: const [0.2, 1.0],
              ),
            ),
          ),

          // Content overlay at the bottom
          Positioned(
            bottom: 48,
            left: 48,
            right: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Text(
                    'ENGINEERING EXCELLENCE',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Headline
                Text(
                  'Building the future of\nworld-class greens.',
                  style: GoogleFonts.manrope(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),

                // Subtitle
                Text(
                  'Global logistics and site analytics for premier golf course construction, managed through a single professional portal.',
                  style: GoogleFonts.manrope(
                    fontSize: 17,
                    color: const Color(0xFFCBD5E1),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
