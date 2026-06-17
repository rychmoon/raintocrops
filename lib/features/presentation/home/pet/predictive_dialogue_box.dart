import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/features/irrigation/controller/irrigation_controller.dart';

Future<void> showPredectiveDialogueBox(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return const _PredectiveDialogueBox();
    },
  );
}

// Optional corrected alias
Future<void> showPredictiveDialogueBox(BuildContext context) {
  return showPredectiveDialogueBox(context);
}

class _PredectiveDialogueBox extends StatelessWidget {
  const _PredectiveDialogueBox();

  static const Color primaryBlue = Color(0xFF38BDF8);
  static const Color deepBlue = Color(0xFF0369A1);
  static const Color softBlue = Color(0xFFE0F7FF);
  static const Color paleBlue = Color(0xFFF0FAFF);
  static const Color darkText = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  // Image for no schedule / no data
  static const String noScheduleImage = 'assets/lottie/water_preview.webp';

  // Image for active schedule / with insights
  static const String withInsightsImage = 'assets/lottie/water_info.webp';

  @override
  Widget build(BuildContext context) {
    final irrigation = context.watch<IrrigationController>();

    // Updated: live data first, saved data fallback second
    final prediction = irrigation.tankInsightForDisplay;
    final bool isUsingCached = irrigation.isUsingCachedTankInsight;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: prediction == null
            ? _EmptyState(
          imagePath: noScheduleImage,
          title: 'No water data yet',
          message:
          'Connect your device first so RainToCrops can check your tank and watering status.',
          buttonText: 'Okay',
          onClose: () => Navigator.pop(context),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TopBar(
              onClose: () => Navigator.pop(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: _PredictionContent(
                  prediction: prediction,
                  isUsingCached: isUsingCached,
                  noScheduleImage: noScheduleImage,
                  withInsightsImage: withInsightsImage,
                  onClose: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;

  const _TopBar({
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 6),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _PredectiveDialogueBox.softBlue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: _PredectiveDialogueBox.primaryBlue,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tank Insights',
                  style: TextStyle(
                    color: _PredectiveDialogueBox.darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'See how long your rainwater can last',
                  style: TextStyle(
                    color: _PredectiveDialogueBox.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            splashRadius: 20,
            icon: const Icon(
              Icons.close_rounded,
              color: _PredectiveDialogueBox.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionContent extends StatelessWidget {
  final dynamic prediction;
  final bool isUsingCached;
  final String noScheduleImage;
  final String withInsightsImage;
  final VoidCallback onClose;

  const _PredictionContent({
    required this.prediction,
    required this.isUsingCached,
    required this.noScheduleImage,
    required this.withInsightsImage,
    required this.onClose,
  });

  bool get hasSchedule => prediction.activeScheduleCount > 0;

  bool get hasDailyUse => prediction.estimatedLitersPerDay > 0;

  String get heroImagePath {
    return hasSchedule ? withInsightsImage : noScheduleImage;
  }

  String get daysLeftText {
    if (!hasDailyUse) return 'Not set';

    final double days = prediction.estimatedDaysLeft;

    if (days <= 0) return 'Low';
    if (days < 1) return 'Less than 1 day';
    if (days < 2) return 'About 1 day';

    return '${days.toStringAsFixed(1)} days';
  }

  String get friendlyMessage {
    if (!hasSchedule) {
      return 'Add a watering schedule so the app can estimate how long your tank will last.';
    }

    if (!hasDailyUse) {
      return 'No watering is expected right now. Your tank water is safe for now.';
    }

    if (isUsingCached) {
      return 'Based on your saved data, your tank can support watering for about $daysLeftText.';
    }

    return 'Based on your schedule, your tank can support watering for about $daysLeftText.';
  }

  String get wateringLeftText {
    if (!hasSchedule) return 'No schedule';

    final double runsLeft = prediction.estimatedScheduleRunsLeft;

    if (runsLeft <= 0) return 'Not enough data';

    return '${runsLeft.toStringAsFixed(0)} times';
  }

  String get savedTimeText {
    if (!isUsingCached) return '';

    try {
      return prediction.savedTimeText;
    } catch (_) {
      return 'Saved data';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUsingCached) ...[
          _CacheNotice(
            text: savedTimeText,
          ),
          const SizedBox(height: 12),
        ],

        _HeroCard(
          imagePath: heroImagePath,
          title: hasSchedule ? 'Tank can last' : 'No schedule yet',
          value: daysLeftText,
          message: friendlyMessage,
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _SimpleInfoCard(
                icon: Icons.water_drop_rounded,
                label: 'Water level',
                value: '${prediction.currentTankLiters.toStringAsFixed(1)}L',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SimpleInfoCard(
                icon: Icons.verified_rounded,
                label: 'Available supply',
                value: '${prediction.usableTankLiters.toStringAsFixed(1)}L',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _SimpleInfoCard(
                icon: Icons.local_florist_rounded,
                label: 'Daily need',
                value: hasDailyUse
                    ? '${prediction.estimatedLitersPerDay.toStringAsFixed(1)}L'
                    : 'None',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SimpleInfoCard(
                icon: Icons.repeat_rounded,
                label: 'Watering left',
                value: wateringLeftText,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        isUsingCached
            ? _SmallNoteBox(
          title: 'Saved insight',
          message:
          'Using saved data from your phone while waiting for live tank data to update.',
        )
            : hasSchedule
            ? _SmallNoteBox(
          title: 'How we got this',
          message:
          'This is calculated from your current tank level, saved watering schedule, and recorded water flow of ${prediction.litersPer60Sec.toStringAsFixed(2)}L per 60 seconds.',
        )
            : const _SmallNoteBox(
          title: 'Tip',
          message:
          'Once you set a watering schedule, this screen will show how many days your tank can support your plants.',
        ),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _PredectiveDialogueBox.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Text(
              'Got it',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CacheNotice extends StatelessWidget {
  final String text;

  const _CacheNotice({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            color: Color(0xFFD97706),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Using saved data • $text',
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String value;
  final String message;

  const _HeroCard({
    required this.imagePath,
    required this.title,
    required this.value,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _PredectiveDialogueBox.softBlue,
            _PredectiveDialogueBox.paleBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFBAE6FD),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _SafeAssetImage(
            imagePath: imagePath,
            width: 92,
            height: 92,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _PredectiveDialogueBox.deepBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _PredectiveDialogueBox.darkText,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SimpleInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _PredectiveDialogueBox.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _PredectiveDialogueBox.primaryBlue,
            size: 23,
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PredectiveDialogueBox.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PredectiveDialogueBox.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallNoteBox extends StatelessWidget {
  final String title;
  final String message;

  const _SmallNoteBox({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _PredectiveDialogueBox.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            color: Color(0xFFF59E0B),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _PredectiveDialogueBox.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: _PredectiveDialogueBox.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeAssetImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;

  const _SafeAssetImage({
    required this.imagePath,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.image_not_supported_rounded,
            color: _PredectiveDialogueBox.primaryBlue,
            size: 42,
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String imagePath;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onClose;

  const _EmptyState({
    required this.imagePath,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SafeAssetImage(
            imagePath: imagePath,
            width: 125,
            height: 125,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PredectiveDialogueBox.darkText,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PredectiveDialogueBox.mutedText,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _PredectiveDialogueBox.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}