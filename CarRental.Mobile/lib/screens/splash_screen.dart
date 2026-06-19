import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final loggedIn = await ApiService.isLoggedIn();
    if (mounted) {
      if (loggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: Stack(
          children: [
            // Background circles for depth
            Positioned(
              top: -100, right: -100,
              child: Container(
                width: 350, height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -120, left: -80,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Retrix Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  )
                  .animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 12),

                  // App name
                  Text(
                    'RETRIX',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: 4,
                    ),
                  )
                  .animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.3, end: 0),

                  Text(
                    'CAR RENTAL',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 6,
                    ),
                  )
                  .animate().fadeIn(delay: 450.ms, duration: 500.ms),

                  const SizedBox(height: 60),

                  // Loading indicator
                  SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      borderRadius: BorderRadius.circular(999),
                      minHeight: 3,
                    ),
                  )
                  .animate().fadeIn(delay: 700.ms, duration: 400.ms),

                  const SizedBox(height: 16),

                  Text(
                    'Premium Car Rentals',
                    style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.white.withOpacity(0.6),
                    ),
                  )
                  .animate().fadeIn(delay: 800.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
