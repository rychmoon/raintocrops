import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/onboarding_slides_widget.dart';
import '/features/auth/login.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final Color primaryBlue = const Color(0xFF4DA6FF);

  late AnimationController _rippleController;
  late Animation<double> _rippleProgress;
  late Animation<double> _fadeOutContent;

  bool _showRipple = false;
  bool _isFinishing = false;
  Offset _rippleOrigin = Offset.zero;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _rippleProgress = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeInOutCubic,
    );

    _fadeOutContent = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  void _nextPage() {
    if (_isFinishing) return;

    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _triggerRipple();
    }
  }

  Future<void> _triggerRipple() async {
    if (_isFinishing) return;

    final size = MediaQuery.of(context).size;

    setState(() {
      _isFinishing = true;
      _rippleOrigin = Offset(size.width * 0.78, size.height - 76);
      _showRipple = true;
    });

    await _rippleController.forward(from: 0.0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _skip() {
    if (_isFinishing) return;

    _controller.animateToPage(
      2,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    double maxRadius() {
      final corners = [
        const Offset(0, 0),
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ];

      return corners
          .map((corner) => (_rippleOrigin - corner).distance)
          .reduce(max);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, _) {
              return Opacity(
                opacity: _showRipple ? _fadeOutContent.value : 1.0,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        children: const [
                          OnboardingPageWidget(
                            image: "assets/illustrations/slide-5.png",
                            title: "Harvest Rainwater",
                            description:
                            "Collect and store rain to create a natural water source for your plants.",
                          ),
                          OnboardingPageWidget(
                            image: "assets/illustrations/slide-7.png",
                            title: "Smart Watering",
                            description:
                            "Soil and weather data work together to water your plants at the right time.",
                          ),
                          OnboardingPageWidget(
                            image: "assets/illustrations/slide-6.png",
                            title: "Stay in Control",
                            description:
                            "Monitor water levels, soil moisture, and pH anytime from your phone.",
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              3,
                                  (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentPage == index ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? primaryBlue
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: _currentPage == 2 ? 0.0 : 1.0,
                                  child: IgnorePointer(
                                    ignoring:
                                    _currentPage == 2 || _isFinishing,
                                    child: TextButton(
                                      onPressed: _skip,
                                      child: Text(
                                        "Skip",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: (_showRipple || _isFinishing)
                                      ? null
                                      : _nextPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    disabledBackgroundColor: primaryBlue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _currentPage == 2
                                        ? "Get Started"
                                        : "Next",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_showRipple)
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, _) {
                final radius = _rippleProgress.value * maxRadius();

                return ClipPath(
                  clipper: _CircleRevealClipper(
                    center: _rippleOrigin,
                    radius: radius,
                  ),
                  child: Container(color: primaryBlue),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const _CircleRevealClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}