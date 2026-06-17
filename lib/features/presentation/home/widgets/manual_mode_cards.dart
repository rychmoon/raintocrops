import 'package:flutter/material.dart';

class ManualModeCard extends StatelessWidget {
  final String category;
  final String title;
  final String value;
  final String imagePath;
  final bool isOn;
  final ValueChanged<bool> onToggle;

  // NEW: custom status text on top-right
  final String statusText;

  // NEW: small label on the left of toggle row
  final String levelLabel;

  // NEW: small text under the toggle (ex. Normal / Middle / High / Low)
  final String toggleNote;

  const ManualModeCard({
    super.key,
    required this.category,
    required this.title,
    required this.value,
    required this.imagePath,
    required this.isOn,
    required this.onToggle,
    required this.statusText,
    required this.levelLabel,
    required this.toggleNote,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final double scale = width >= 900
        ? 1.0
        : width >= 600
        ? 0.96
        : 0.90;

    final Color statusColor =
    isOn ? const Color(0xFF38BDF8) : const Color(0xFF9CA3AF);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * scale),
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
          /// TOP: image left, custom status right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                height: 46 * scale,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 5 * scale,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
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
              fontSize: 12 * scale,
              color: const Color(0xFFB0B3B8),
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: 6 * scale),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5 * scale,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E1E),
              height: 1.2,
            ),
          ),

          SizedBox(height: 8 * scale),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111111),
            ),
          ),

          const Spacer(),

          /// BOTTOM: left label + toggle on right + small note under toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  levelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isOn,
                      onChanged: onToggle,

                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.lightBlue,

                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFD1D5DB),

                      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.lightBlue; // border when ON
                          }
                          return const Color(0xFF9CA3AF); // border when OFF
                        },
                      ),

                      trackOutlineWidth:WidgetStateProperty.all(1),

                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    toggleNote,
                    style: TextStyle(
                      fontSize: 10 * scale,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}