import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';

import '/features/presentation/home/widgets/manual_mode_cards.dart';
import '/features/irrigation/controller/irrigation_controller.dart';

class ManualModeBoxes extends StatelessWidget {
  const ManualModeBoxes({super.key});

  String _tankText(dynamic telemetry) {
    final level = telemetry?.level;
    if (level == null) return '--';

    final parsed = level is num ? level.toDouble() : double.tryParse('$level');
    if (parsed == null) return '--';

    return '${parsed.toStringAsFixed(0)}%';
  }

  String _pondText(dynamic telemetry) {
    final level = telemetry?.pondLevel;
    if (level == null) return '--';

    final parsed = level is num ? level.toDouble() : double.tryParse('$level');
    if (parsed == null) return '--';

    return '${parsed.toStringAsFixed(0)}%';
  }

  String _phText(dynamic telemetry) {
    final formatted = _formatPHValue(telemetry?.ph);
    if (formatted == null) return '--';
    return '$formatted pH';
  }

  String? _formatPHValue(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble().toStringAsFixed(1);
    }

    final parsed = double.tryParse(value.toString());
    if (parsed == null) return null;

    return parsed.toStringAsFixed(1);
  }

  String _phLabel(dynamic telemetry) {
    final condition = telemetry?.phCondition;
    if (condition == null || '$condition'.trim().isEmpty) {
      return 'pH reading unavailable';
    }

    final normalized = '$condition'.toUpperCase();

    if (normalized == 'GOOD' || normalized == 'NORMAL' || normalized == 'OK') {
      return 'Water is balanced';
    }
    if (normalized == 'LOW' || normalized == 'ACIDIC') {
      return 'Acidic water';
    }
    if (normalized == 'HIGH' || normalized == 'ALKALINE') {
      return 'Alkaline water';
    }
    if (normalized == 'UNKNOWN') {
      return 'pH reading unavailable';
    }

    return condition.toString();
  }

  String _phBottleStatus(dynamic telemetry) {
    final hasBottle = telemetry?.phBottle;
    if (hasBottle == null) return 'Bottle unknown';
    return hasBottle ? 'Bottle ready' : 'Bottle empty';
  }

  String _phBottleNote(dynamic telemetry, bool dosingPumpOn) {
    final hasBottle = telemetry?.phBottle;
    final condition = (telemetry?.phCondition ?? '').toString().toUpperCase();

    if (hasBottle == null) return 'Check bottle';
    if (!hasBottle) return 'Refill bottle';

    if (_isLowPH(condition)) {
      return dosingPumpOn ? 'Dosing active' : 'Ready to dose';
    }

    if (_isHighPH(condition)) {
      return 'Dosing not needed';
    }

    return dosingPumpOn ? 'Liquid available' : 'Bottle available';
  }

  String _countdownText(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    final secText = secs.toString().padLeft(2, '0');
    return '$mins:$secText';
  }

  String _statusLabel(String? raw) {
    final s = (raw ?? 'UNKNOWN').toUpperCase();
    switch (s) {
      case 'OK':
      case 'NORMAL':
      case 'GOOD':
        return 'Normal';
      case 'LOW':
        return 'Low';
      case 'HIGH':
        return 'High';
      case 'FULL':
        return 'Full';
      case 'EMPTY':
        return 'Empty';
      case 'UNKNOWN':
      default:
        return 'Unknown';
    }
  }

  bool _isLowPH(String condition) {
    final s = condition.toUpperCase();
    return s == 'LOW' || s == 'ACIDIC';
  }

  bool _isHighPH(String condition) {
    final s = condition.toUpperCase();
    return s == 'HIGH' || s == 'ALKALINE';
  }

  bool _isGoodPH(String condition) {
    final s = condition.toUpperCase();
    return s == 'GOOD' || s == 'NORMAL' || s == 'OK';
  }

  Future<void> _showLowTankDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFFEF4444),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tank level is too low',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: Color(0xFFDC2626),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Irrigation cannot start right now because the tank water level is too low.',
                          style: TextStyle(
                            fontSize: 12.8,
                            height: 1.45,
                            color: Color(0xFF7F1D1D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please refill the tank first, then try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showUnknownTankDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 86,
                      height: 86,
                      child: LiquidCircularProgressIndicator(
                        value: 0.55,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF7DD3FC),
                        ),
                        backgroundColor: const Color(0xFFF0F9FF),
                        borderColor: const Color(0xFFBAE6FD),
                        borderWidth: 2,
                        direction: Axis.vertical,
                        center: const Icon(
                          Icons.question_mark_rounded,
                          color: Color(0xFF0284C7),
                          size: 34,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFCD34D),
                          ),
                        ),
                        child: const Icon(
                          Icons.priority_high_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tank level is still checking',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF0284C7),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The tank sensor has not produced a stable reading yet, so irrigation is temporarily paused for safety.',
                          style: TextStyle(
                            fontSize: 12.8,
                            height: 1.45,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please wait a moment, then try again once the tank status is ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Got It',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPhBlockedDialog(
      BuildContext context, {
        required String message,
      }) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: Color(0xFF4F46E5),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Low pH detected',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBottleEmptyDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.opacity_rounded,
                    color: Color(0xFFF97316),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dosing bottle is empty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFED7AA),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Color(0xFFEA580C),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The dosing pump cannot start because the pH solution bottle has no liquid left.',
                          style: TextStyle(
                            fontSize: 12.8,
                            height: 1.45,
                            color: Color(0xFF9A3412),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please refill the bottle first before turning on the dosing pump.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBottleUnknownDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Color(0xFFF59E0B),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bottle status is unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The system could not confirm whether the dosing bottle still has liquid. For safety, the dosing pump will stay off.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDosingOnlyForLowPHDialog(
      BuildContext context, {
        required String phCondition,
        required dynamic phValue,
      }) async {
    final phText = _formatPHValue(phValue);

    final message = phCondition == 'UNKNOWN' || phCondition.isEmpty
        ? 'The system cannot confirm the pH reading yet. For safety, the dosing pump will stay off.'
        : phText == null
        ? 'The dosing pump is only needed when pH is low or acidic.'
        : 'Current pH is $phText. The dosing pump is only needed when pH is low or acidic.';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: Colors.lightBlue,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dosing not needed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleIrrigationToggle(
      BuildContext context,
      IrrigationController controller,
      bool on,
      ) async {
    if (!on) {
      controller.stopManualIrrigation();
      return;
    }

    final telemetry = controller.telemetry;
    final tankStatus = (telemetry?.tankStatus ?? '').toString().toUpperCase();
    final phCondition = (telemetry?.phCondition ?? '').toString().toUpperCase();
    final phText = _formatPHValue(telemetry?.ph);

    if (tankStatus == 'LOW') {
      await _showLowTankDialog(context);
      return;
    }

    if (tankStatus == 'UNKNOWN' || tankStatus.isEmpty) {
      await _showUnknownTankDialog(context);
      return;
    }

    // Only LOW / ACIDIC pH blocks manual irrigation.
    // HIGH / ALKALINE pH is allowed.
    if (_isLowPH(phCondition)) {
      final phMessage = phText == null
          ? 'The pH is currently too low. Please wait until the water condition becomes stable before turning on irrigation.'
          : 'The current pH is $phText, which is too low for irrigation. Please wait until the water condition becomes stable before turning on irrigation.';

      await _showPhBlockedDialog(
        context,
        message: phMessage,
      );
      return;
    }

    controller.startManualIrrigation(duration: 60);
  }

  Future<void> _handleDosingPumpToggle(
      BuildContext context,
      IrrigationController controller,
      bool on,
      ) async {
    if (!on) {
      controller.setDosingPump(false);
      return;
    }

    final telemetry = controller.telemetry;
    final hasBottle = telemetry?.phBottle;
    final phCondition = (telemetry?.phCondition ?? '').toString().toUpperCase();
    final phValue = telemetry?.ph;

    if (hasBottle == null) {
      await _showBottleUnknownDialog(context);
      return;
    }

    if (!hasBottle) {
      await _showBottleEmptyDialog(context);
      return;
    }

    // Dosing pump should only run when pH is LOW / ACIDIC.
    if (!_isLowPH(phCondition)) {
      await _showDosingOnlyForLowPHDialog(
        context,
        phCondition: phCondition,
        phValue: phValue,
      );
      return;
    }

    controller.setDosingPump(true);
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _sectionGrid(List<Widget> children) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.84,
      ),
      itemBuilder: (_, index) => children[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<IrrigationController>();
    final telemetry = controller.telemetry;

    final valveOn = controller.valveOn;
    final irrigationPumpOn =
        controller.isManualIrrigationActive || telemetry?.irrigationRunning == true;
    final pondPumpOn = controller.pondPumpOn;
    final dosingPumpOn = controller.dosingPumpOn;

    final mainPumpOn = controller.mainPumpOn;
    final valve2ToPondOn = controller.valve2ToPondOn;
    final valve3ToReserveOn = controller.valve3ToReserveOn;

    final tankValue = _tankText(telemetry);
    final pondValue = _pondText(telemetry);
    final phValue = _phText(telemetry);

    final irrigationRemaining = controller.manualIrrigationRemainingSeconds;
    final irrigationValue =
    irrigationRemaining > 0 ? _countdownText(irrigationRemaining) : '1:00';

    final irrigationStatus =
    irrigationRemaining > 0 || telemetry?.irrigationRunning == true
        ? 'In progress'
        : 'Ready';

    String irrigationNote = irrigationRemaining > 0 ? 'Running' : 'Tap to run';

    final tankStatus = (telemetry?.tankStatus ?? '').toString().toUpperCase();
    final phCondition = (telemetry?.phCondition ?? '').toString().toUpperCase();

    if (_isLowPH(phCondition)) {
      irrigationNote = 'Low pH blocked';
    } else if (_isHighPH(phCondition)) {
      irrigationNote = 'High pH allowed';
    } else if (_isGoodPH(phCondition)) {
      irrigationNote = irrigationRemaining > 0 ? 'Running' : 'Tap to run';
    } else if (tankStatus == 'LOW') {
      irrigationNote = 'Tank too low';
    } else if (tankStatus == 'UNKNOWN' || tankStatus.isEmpty) {
      irrigationNote = 'Checking sensors';
    }

    final mainPumps = <Widget>[
      ManualModeCard(
        category: "Rainwater Source",
        title: "Main Tank Pump",
        value: tankValue,
        imagePath: "assets/images/IBC_tank.webp",
        isOn: mainPumpOn,
        statusText: mainPumpOn ? "Running" : "Stopped",
        levelLabel: "Tank Water Level",
        toggleNote: mainPumpOn ? "Pump is ON" : "Pump is OFF",
        onToggle: controller.setMainPump,
      ),
      ManualModeCard(
        category: "Plant Watering",
        title: "Irrigation Pump",
        value: irrigationValue,
        imagePath: "assets/images/irrigate.png",
        isOn: irrigationPumpOn,
        statusText: irrigationStatus,
        levelLabel: "Max Time",
        toggleNote: irrigationNote,
        onToggle: (value) => _handleIrrigationToggle(context, controller, value),
      ),
    ];

    final selenoidValves = <Widget>[
      ManualModeCard(
        category: "Water Routing 1",
        title: "Irrigation Valve",
        value: tankValue,
        imagePath: "assets/images/faucet.png",
        isOn: valveOn,
        statusText: valveOn ? "Open" : "Closed",
        levelLabel: "Tank Level",
        toggleNote: valveOn ? "Open" : "Closed",
        onToggle: controller.setValve,
      ),
      ManualModeCard(
        category: "Water Routing 2",
        title: "Pond Diversion Valve",
        value: tankValue,
        imagePath: "assets/images/faucet.png",
        isOn: valve2ToPondOn,
        statusText: valve2ToPondOn ? "Open" : "Closed",
        levelLabel: "Tank Level",
        toggleNote: valve2ToPondOn ? "To pond" : "Off",
        onToggle: controller.setValve2ToPond,
      ),
      ManualModeCard(
        category: "Water Routing 3",
        title: "Reserve Tank Valve",
        value: tankValue,
        imagePath: "assets/images/faucet.png",
        isOn: valve3ToReserveOn,
        statusText: valve3ToReserveOn ? "Open" : "Closed",
        levelLabel: "Tank Level",
        toggleNote: valve3ToReserveOn ? "To reserve" : "Off",
        onToggle: controller.setValve3ToReserve,
      ),
    ];

    final otherPumps = <Widget>[
      ManualModeCard(
        category: "Alternative Source",
        title: "Fishpond Pump",
        value: pondValue,
        imagePath: "assets/images/pond-1.png",
        isOn: pondPumpOn,
        statusText: _statusLabel(telemetry?.pondStatus),
        levelLabel: "Pond Level",
        toggleNote: pondPumpOn ? "Active" : "Idle",
        onToggle: controller.setPondPump,
      ),
      ManualModeCard(
        category: "pH Adjustment",
        title: "Dosing Pump",
        value: phValue,
        imagePath: "assets/images/ph_check.png",
        isOn: dosingPumpOn,
        statusText: _phBottleStatus(telemetry),
        levelLabel: _phLabel(telemetry),
        toggleNote: _phBottleNote(telemetry, dosingPumpOn),
        onToggle: (value) => _handleDosingPumpToggle(context, controller, value),
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("Main Pumps"),
          _sectionGrid(mainPumps),
          const SizedBox(height: 16),
          _sectionLabel("Selenoid Valves"),
          _sectionGrid(selenoidValves),
          const SizedBox(height: 16),
          _sectionLabel("Other Pumps"),
          _sectionGrid(otherPumps),
        ],
      ),
    );
  }
}