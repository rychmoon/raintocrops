import 'package:flutter/material.dart';

class UnpairedDeviceCard extends StatelessWidget {
  const UnpairedDeviceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // tuned for your homepage: bg #F6F6F6 + light-blue accent
    const bg = Color(0xFFffffff);
    const border = Color(0xFFE6EAF0);
    const iconBg = Color(0xFFDFF0FF);
    const accent = Colors.lightBlue;
    const titleColor = Color(0xFF1F2937);
    const bodyColor = Color(0xFF5F6B7A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.wifi_tethering_off_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No paired device',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap + to pair your device. After pairing, live sensor data will appear here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: bodyColor,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Waiting for first connection',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: bodyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaitingForDeviceCard extends StatefulWidget {
  final String pairedCode;
  final String role;

  const WaitingForDeviceCard({
    super.key,
    required this.pairedCode,
    required this.role,
  });

  @override
  State<WaitingForDeviceCard> createState() => _WaitingForDeviceCardState();
}

class _WaitingForDeviceCardState extends State<WaitingForDeviceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Color _cardBg = Color(0xFFF6F6F6);
  static const Color _boneBase = Color(0xFFEAEAEA);
  static const Color _boneHighlight = Color(0xFFF7F7F7);
  static const Color _tileBg = Color(0xFFF1F1F1);
  static const Color _border = Color(0xFFE5E5E5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bone({
    required double height,
    required double width,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: _boneBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _boneExpanded({
    required double height,
    double radius = 8,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _boneBase,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final dx = (bounds.width * 2) * _controller.value - bounds.width;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [_boneBase, _boneHighlight, _boneBase],
              stops: const [0.22, 0.5, 0.78],
              transform: _SlidingGradientTransform(dx),
            ).createShader(bounds);
          },
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: _cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: _border, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bone(height: 64, width: 72, radius: 12),
                      const Spacer(),
                      _bone(height: 22, width: 84, radius: 30),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _bone(height: 10, width: 76, radius: 6),
                  const SizedBox(height: 6),
                  _bone(height: 14, width: 128, radius: 6),
                  const SizedBox(height: 12),
                  _bone(height: 24, width: 92, radius: 8),
                  const SizedBox(height: 22),
                  Container(
                    height: 7,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _tileBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _bone(height: 7, width: 110, radius: 20),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _boneExpanded(height: 1.5, radius: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double dx;
  const _SlidingGradientTransform(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}

class _SimpleInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SimpleInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}