import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:provider/provider.dart';

import '/features/irrigation/controller/irrigation_controller.dart';
import '/features/irrigation/models/telemetry_model.dart';

class CustomCircleIndicator extends StatelessWidget {
  const CustomCircleIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CircleIndicatorCard(
      title: 'Rainwater Tank',
      isPond: false,
    );
  }
}

class PondCircleIndicator extends StatelessWidget {
  const PondCircleIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CircleIndicatorCard(
      title: 'Fish Pond',
      isPond: true,
    );
  }
}

class DualCircleIndicators extends StatelessWidget {
  const DualCircleIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: CustomCircleIndicator()),
        SizedBox(width: 10),
        Expanded(child: PondCircleIndicator()),
      ],
    );
  }
}

class _CircleIndicatorCard extends StatelessWidget {
  final String title;
  final bool isPond;

  const _CircleIndicatorCard({
    required this.title,
    required this.isPond,
  });

  double _percent(TelemetryModel? telemetry) {
    if (telemetry == null) return 0.0;
    final value = isPond ? telemetry.pondLevel : telemetry.level;
    return value.clamp(0.0, 100.0);
  }

  double _progress(TelemetryModel? telemetry) {
    return (_percent(telemetry) / 100.0).clamp(0.0, 1.0);
  }

  double _liters(TelemetryModel? telemetry) {
    if (telemetry == null) return 0.0;
    return isPond ? telemetry.pondVolume : telemetry.volume;
  }

  String _percentText(TelemetryModel? telemetry) {
    return '${_percent(telemetry).toStringAsFixed(0)}%';
  }

  String _litersText(TelemetryModel? telemetry) {
    return '${_liters(telemetry).toStringAsFixed(1)} L';
  }

  String _statusText(TelemetryModel? telemetry) {
    final raw = isPond ? telemetry?.pondStatus : telemetry?.tankStatus;
    final status = raw?.trim().toUpperCase() ?? 'UNKNOWN';
    if (status == 'MID' || status == 'NORMAL') return 'MIDDLE';
    return status;
  }

  _TankVisuals _visualsForStatus(String status) {
    switch (status) {
      case 'LOW':
        return const _TankVisuals(
          liquidColor: Color(0xFFF87171),
          ringColor: Color(0xFFFEE2E2),
          chipBg: Color(0xFFFEF2F2),
          chipText: Color(0xFFDC2626),
          chipBorder: Color(0xFFFECACA),
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFDC2626),
          label: 'Low',
          info: 'Water is low. Refill soon.',
        );
      case 'MIDDLE':
      case 'MEDIUM':
        return const _TankVisuals(
          liquidColor: Color(0xFF60A5FA),
          ringColor: Color(0xFFEFF6FF),
          chipBg: Color(0xFFEEF4FF),
          chipText: Color(0xFF2563EB),
          chipBorder: Color(0xFFBFDBFE),
          icon: Icons.water_drop_outlined,
          iconColor: Color(0xFF3B82F6),
          label: 'Medium',
          info: 'Water level is okay.',
        );
      case 'HIGH':
        return const _TankVisuals(
          liquidColor: Color(0xFF38BDF8),
          ringColor: Color(0xFFE0F2FE),
          chipBg: Color(0xFFEFF8FF),
          chipText: Color(0xFF0284C7),
          chipBorder: Color(0xFFBAE6FD),
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF0EA5E9),
          label: 'High',
          info: 'Water level is good.',
        );
      case 'FULL':
        return const _TankVisuals(
          liquidColor: Color(0xFF0EA5E9),
          ringColor: Color(0xFFDDF4FF),
          chipBg: Color(0xFFEFF8FF),
          chipText: Color(0xFF0369A1),
          chipBorder: Color(0xFFBAE6FD),
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF0284C7),
          label: 'Full',
          info: 'Tank is near full capacity.',
        );
      case 'EMPTY':
        return const _TankVisuals(
          liquidColor: Color(0xFFEF4444),
          ringColor: Color(0xFFFEE2E2),
          chipBg: Color(0xFFFEF2F2),
          chipText: Color(0xFFB91C1C),
          chipBorder: Color(0xFFFECACA),
          icon: Icons.error_outline_rounded,
          iconColor: Color(0xFFDC2626),
          label: 'Empty',
          info: 'No usable water in tank.',
        );
      case 'UNKNOWN':
      default:
        return const _TankVisuals(
          liquidColor: Color(0xFF94A3B8),
          ringColor: Color(0xFFF1F5F9),
          chipBg: Color(0xFFF8FAFC),
          chipText: Color(0xFF475569),
          chipBorder: Color(0xFFE2E8F0),
          icon: Icons.priority_high_rounded,
          iconColor: Color(0xFF64748B),
          label: 'Unknown',
          info: 'Waiting for stable sensor reading.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<IrrigationController>().telemetry;

    final rawStatusText = _statusText(telemetry);
    final visuals = _visualsForStatus(rawStatusText);

    final progress = _progress(telemetry);
    final liquidValue = rawStatusText == 'UNKNOWN' ? 0.45 : progress;

    final percentText = _percentText(telemetry);
    final litersText = _litersText(telemetry);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1), // matched to chart
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardW = constraints.maxWidth;
            final circle = (cardW * 0.76).clamp(120.0, 170.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: circle,
                  height: circle,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: circle,
                        height: circle,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: visuals.ringColor,
                        ),
                      ),
                      SizedBox(
                        width: circle * 0.87,
                        height: circle * 0.87,
                        child: ClipOval(
                          child: LiquidCircularProgressIndicator(
                            value: liquidValue,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation(visuals.liquidColor),
                            borderColor: Colors.transparent,
                            borderWidth: 0,
                            direction: Axis.vertical,
                          ),
                        ),
                      ),
                      if (rawStatusText == 'UNKNOWN')
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(visuals.icon, size: circle * 0.12, color: visuals.iconColor),
                            const SizedBox(height: 3),
                            Text(
                              visuals.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              percentText,
                              style: TextStyle(
                                fontSize: (circle * 0.18).clamp(20.0, 30.0),
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              litersText,
                              style: TextStyle(
                                fontSize: (circle * 0.075).clamp(10.0, 13.0),
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: visuals.chipBg,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: visuals.chipBorder.withOpacity(0.75), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(visuals.icon, size: 14, color: visuals.iconColor),
                      const SizedBox(width: 5),
                      Text(
                        visuals.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: visuals.chipText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  visuals.info,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.25,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TankVisuals {
  final Color liquidColor;
  final Color ringColor;
  final Color chipBg;
  final Color chipText;
  final Color chipBorder;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String info;

  const _TankVisuals({
    required this.liquidColor,
    required this.ringColor,
    required this.chipBg,
    required this.chipText,
    required this.chipBorder,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.info,
  });
}