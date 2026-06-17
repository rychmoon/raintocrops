import 'package:flutter/material.dart';

class ConnectedDeviceItemCard extends StatelessWidget {
  final String category;
  final String title;
  final String value;
  final String status;
  final Color statusColor;
  final String imagePath;
  final Color progressColor;
  final double progress;

  // NEW: wave overlay options
  final bool useWaveOverlay;
  final double waveLevel; // 0.0 .. 1.0

  const ConnectedDeviceItemCard({
    super.key,
    required this.category,
    required this.title,
    required this.value,
    required this.status,
    required this.statusColor,
    required this.imagePath,
    required this.progressColor,
    required this.progress,
    this.useWaveOverlay = false,
    this.waveLevel = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final double scale = width >= 900
        ? 1.0
        : width >= 600
        ? 0.96
        : 0.93;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF3F8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white,
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 64 * scale,
                    child: useWaveOverlay
                        ? _WaveImageOverlay(
                      imagePath: imagePath,
                      level: waveLevel.clamp(0.0, 1.0),
                    )
                        : Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              Flexible(
                flex: 5,
                child: Align(
                  alignment: Alignment.topRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 110 * scale,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(50),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w600,
                          color: statusColor.withAlpha(220),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8 * scale),

          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11 * scale,
              color: const Color(0xFFB0B3B8),
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 3 * scale),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15.5 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E1E),
              height: 1.2,
            ),
          ),

          SizedBox(height: 10 * scale),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 23 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),

          const Spacer(),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 7 * scale,
              width: double.infinity,
              color: progressColor.withAlpha(65),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveImageOverlay extends StatelessWidget {
  final String imagePath;
  final double level;

  const _WaveImageOverlay({
    required this.imagePath,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final fillHeight = h * level;

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: fillHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFB3E5FC).withOpacity(0.35), // very light blue
                        const Color(0xFF81D4FA).withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}