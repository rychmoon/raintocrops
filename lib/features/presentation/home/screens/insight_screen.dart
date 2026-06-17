import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '/features/roles/controller/device_session_controller.dart';
import '/features/presentation/home/widgets/custom_circle_indicator.dart';
import '/features/presentation/home/widgets/rainwater_chart_widget.dart';
import '/features/presentation/home/pet/draggable_pet_helper.dart';
import '/features/presentation/home/pet/predictive_dialogue_box.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceSession = context.watch<DeviceSessionController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'Insights',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          deviceSession.isLoading
              ? const Center(child: CircularProgressIndicator())
              : !deviceSession.isPaired
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: Lottie.asset(
                      'assets/lottie/connect.json',
                      repeat: true,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Connect a device first',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pair your device to view insights and rainwater trends.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                RainwaterChartWidget(),
                SizedBox(height: 24),
                Text(
                  'Water Levels',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check current water levels for tank and pond.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 12),
                DualCircleIndicators(),
                SizedBox(height: 12),
              ],
            ),
          ),

          DraggablePetHelper(
            onTap: () {
              showPredectiveDialogueBox(context);
            },
          ),
        ],
      ),
    );
  }
}