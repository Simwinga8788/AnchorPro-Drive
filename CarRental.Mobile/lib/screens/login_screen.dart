import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    final result = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
    
    if (mounted) {
      setState(() => _loading = false);
      if (result['success'] == true) {
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Login failed'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg2,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient banner
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -50, right: -50,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Retrix Car Rental',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome back 👋',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
                            ),
                          ),
                          Text(
                            'Sign in to continue',
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withOpacity(0.75)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // Email field
                    _buildLabel('Email Address'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.text3, size: 20),
                      ),
                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                    ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 20),

                    // Password field
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.text3, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.text3, size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Password too short' : null,
                    ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1, end: 0),

                    const SizedBox(height: 12),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('Forgot password?', style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.blue, fontWeight: FontWeight.w500,
                      )),
                    ),

                    const SizedBox(height: 28),

                    // Sign in button
                    _GradientButton(
                      label: 'Sign In',
                      loading: _loading,
                      onPressed: _login,
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 24),

                    // Divider
                    Row(children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: GoogleFonts.inter(fontSize: 13, color: AppColors.text3)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ]),

                    const SizedBox(height: 24),

                    // Register link
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 14, color: AppColors.text2)),
                            Text('Sign Up', style: GoogleFonts.spaceGrotesk(
                              fontSize: 14, color: AppColors.blue, fontWeight: FontWeight.w600,
                            )),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1),
  );
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const _GradientButton({required this.label, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: loading ? null : AppColors.gradient,
          color: loading ? AppColors.border : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: loading ? [] : [
            BoxShadow(color: AppColors.blue.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}
