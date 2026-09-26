import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_menu_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await AuthService.initSampleData();

    // Splash screen display duration: 2.2 seconds
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: loggedIn ? const HomeMenuScreen() : const LoginScreen(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF030A1C), // Deep midnight abyss
              Color(0xFF071938), // Cosmic sapphire
              Color(0xFF0A224E), // Deep sky navy
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient glowing background orb
            Positioned(
              top: MediaQuery.of(context).size.height * 0.28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                        blurRadius: 100,
                        spreadRadius: 30,
                      ),
                      BoxShadow(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                        blurRadius: 80,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content Center
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Futuristic "ALLCORESOLUTION" Emblem
                            Container(
                              width: 124,
                              height: 124,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [
                                    Color(0xFF0D47A1),
                                    Color(0xFF011A48),
                                  ],
                                  center: Alignment(0.0, -0.2),
                                  radius: 0.9,
                                ),
                                border: Border.all(
                                  color: const Color(0xFF00E5FF),
                                  width: 2.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF)
                                        .withValues(alpha: 0.45 * _glowAnimation.value),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 6),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF2979FF)
                                        .withValues(alpha: 0.35 * _glowAnimation.value),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Subtle outer geometric solutions ring
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF80D8FF)
                                            .withValues(alpha: 0.35),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  // High-tech Solution Hub / Core Glyph
                                  const Icon(
                                    Icons.hub_rounded,
                                    size: 52,
                                    color: Color(0xFF00E5FF),
                                  ),
                                  // Central optic focus sparkle
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Main Title: ALLCORESOLUTION
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF00E5FF),
                                  Colors.white,
                                  Color(0xFF80D8FF),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                "ALLCORESOLUTION",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Subtitle / Tagline
                            const Text(
                              "Complete Solutions • Infinite Possibilities",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF90CAF9),
                                fontSize: 13,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 52),

                            // Futuristic Sky-Blue Loading Indicator
                            const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.8,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
