import 'package:flutter/material.dart';
import '../clippers/wave_clipper.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPageWidget({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF4DA6FF);
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        /// WAVE BACKGROUND — extends behind status bar
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: 320 + topPadding,
            width: double.infinity,
            color: primaryBlue,
          ),
        ),

        /// CONTENT — keep original spacing feel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 80 + topPadding * 0.2),

              Image.asset(
                image,
                height: MediaQuery.of(context).size.height * 0.30,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 50),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}