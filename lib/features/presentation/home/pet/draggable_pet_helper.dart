import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:lottie/lottie.dart';
import 'package:characters/characters.dart';
import 'package:provider/provider.dart';

import '/features/irrigation/controller/irrigation_controller.dart';

class DraggablePetHelper extends StatefulWidget {
  final VoidCallback? onTap;

  const DraggablePetHelper({
    super.key,
    this.onTap,
  });

  @override
  State<DraggablePetHelper> createState() => _DraggablePetHelperState();
}

class _DraggablePetHelperState extends State<DraggablePetHelper>
    with TickerProviderStateMixin {
  static const double petSize = 160;

  static const double rightMargin = -40;
  static const double bottomMargin = -40;

  Offset? _position;
  bool _initialized = false;

  int _chatIndex = 0;
  bool _showChatBubble = false;
  bool _chatLoopActive = true;
  String _typedText = '';

  List<String> _activeChats = const [
    'Hi! 👋',
    'Tap me!',
    'Check your water supply 💧',
    'I can help with your tank 🌱',
    'Open tank insights!',
  ];

  late final AnimationController _floatController;
  late final AnimationController _momentumController;

  _CombinedSimulation? _simulation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _momentumController = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        final simulation = _simulation;
        final elapsed = _momentumController.lastElapsedDuration;

        if (simulation == null || elapsed == null) return;

        final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

        setState(() {
          _position = simulation.position(seconds);
        });
      });

    _startChatLoop();
  }

  List<String> _buildSmartChats({
    required dynamic prediction,
    required bool isUsingCached,
    required String? liveTankStatus,
  }) {
    if (prediction == null) {
      return const [
        'Hi! Connect your device first 💧',
        'I am waiting for tank data',
        'Tap me to open tank insights',
        'Once connected, I can check your supply',
        'Your tank status will show here soon',
      ];
    }

    final int activeScheduleCount = prediction.activeScheduleCount;
    final double currentTankLiters = prediction.currentTankLiters;
    final double usableTankLiters = prediction.usableTankLiters;
    final double estimatedLitersPerDay = prediction.estimatedLitersPerDay;
    final double estimatedDaysLeft = prediction.estimatedDaysLeft;
    final double estimatedRunsLeft = prediction.estimatedScheduleRunsLeft;

    final bool hasSchedule = activeScheduleCount > 0;
    final bool hasDailyUse = estimatedLitersPerDay > 0;

    final String normalizedTankStatus =
    (liveTankStatus ?? '').trim().toUpperCase();

    final bool tankIsFull = normalizedTankStatus == 'FULL';
    final bool tankIsHigh = normalizedTankStatus == 'HIGH';
    final bool tankIsLow = normalizedTankStatus == 'LOW';

    String daysText() {
      if (!hasDailyUse) return 'not set yet';

      if (estimatedDaysLeft <= 0) return 'very low';
      if (estimatedDaysLeft < 1) return 'less than 1 day';
      if (estimatedDaysLeft < 2) return 'about 1 day';

      return '${estimatedDaysLeft.toStringAsFixed(1)} days';
    }

    String runsText() {
      if (!hasSchedule) return 'No schedule yet';

      if (estimatedRunsLeft <= 0) return 'Not enough data yet';

      return '${estimatedRunsLeft.toStringAsFixed(0)} watering times left';
    }

    String savedText() {
      if (!isUsingCached) return '';

      try {
        return prediction.savedTimeText;
      } catch (_) {
        return 'saved data';
      }
    }

    if (isUsingCached) {
      return [
        'Using saved tank data 💾',
        savedText(),
        'Tap me to refresh insights',
        hasSchedule
            ? 'Saved supply can last ${daysText()}'
            : 'No schedule saved yet',
        'Live data will update once connected',
      ];
    }

    if (tankIsFull) {
      return [
        'Ohh nice, your tank is full 💧',
        'You have ${currentTankLiters.toStringAsFixed(1)}L right now',
        hasSchedule ? 'Tank can last ${daysText()}' : 'Add schedule to estimate supply',
        'Tap me to check tank insights',
        runsText(),
      ];
    }

    if (tankIsHigh) {
      return [
        'Your tank level looks good 🌱',
        'Available supply: ${usableTankLiters.toStringAsFixed(1)}L',
        hasSchedule ? 'Tank can last ${daysText()}' : 'No schedule yet',
        'Tap me to check your supply',
        runsText(),
      ];
    }

    if (tankIsLow || usableTankLiters <= 0) {
      return [
        'Ohh, your water is low 💧',
        'Better check your tank soon',
        'Current water: ${currentTankLiters.toStringAsFixed(1)}L',
        'Tap me to view tank insights',
        hasSchedule ? runsText() : 'Add schedule to track usage',
      ];
    }

    if (!hasSchedule) {
      return [
        'No schedule yet 🌱',
        'Tap me to check your tank',
        'Add a schedule to estimate supply',
        'Current water: ${currentTankLiters.toStringAsFixed(1)}L',
        'I can show how long your water can last',
      ];
    }

    if (hasDailyUse && estimatedDaysLeft < 1) {
      return [
        'Water may last less than 1 day ⚠️',
        'Your tank is getting low',
        'Tap me to check your supply',
        'Daily need: ${estimatedLitersPerDay.toStringAsFixed(1)}L',
        runsText(),
      ];
    }

    if (hasDailyUse && estimatedDaysLeft < 2) {
      return [
        'Tank can last about 1 day 💧',
        'You still have ${usableTankLiters.toStringAsFixed(1)}L to use',
        'Tap me to check your supply',
        'Daily need: ${estimatedLitersPerDay.toStringAsFixed(1)}L',
        runsText(),
      ];
    }

    return [
      'Nice! Tank can last ${daysText()} 🌱',
      'Tap me to check your supply',
      'Available water: ${usableTankLiters.toStringAsFixed(1)}L',
      'Daily need: ${estimatedLitersPerDay.toStringAsFixed(1)}L',
      runsText(),
    ];
  }

  Future<void> _startChatLoop() async {
    await Future.delayed(const Duration(milliseconds: 700));

    while (mounted && _chatLoopActive) {
      final chats = _activeChats.isEmpty
          ? const ['Tap me to check your tank 💧']
          : _activeChats;

      final safeIndex = _chatIndex % chats.length;
      final message = chats[safeIndex];
      final messageCharacters = message.characters.toList();

      setState(() {
        _showChatBubble = true;
        _typedText = '';
      });

      for (int i = 0; i < messageCharacters.length; i++) {
        if (!mounted || !_chatLoopActive) return;

        await Future.delayed(const Duration(milliseconds: 42));

        if (!mounted || !_chatLoopActive) return;

        setState(() {
          _typedText = messageCharacters.take(i + 1).join();
        });
      }

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted || !_chatLoopActive) return;

      setState(() {
        _showChatBubble = false;
      });

      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted || !_chatLoopActive) return;

      _chatIndex = (_chatIndex + 1) % chats.length;
    }
  }

  void _handlePetTap() {
    setState(() {
      _showChatBubble = true;
      _typedText = 'Opening tank insights...';
    });

    widget.onTap?.call();
  }

  @override
  void dispose() {
    _chatLoopActive = false;
    _floatController.dispose();
    _momentumController.dispose();
    super.dispose();
  }

  Offset _getDefaultFabPosition(Size size, EdgeInsets padding) {
    return Offset(
      size.width - petSize - rightMargin,
      size.height - petSize - bottomMargin - padding.bottom,
    );
  }

  Offset _clampPosition(Offset position, Size size, EdgeInsets padding) {
    final maxX = size.width - petSize - rightMargin;
    final maxY = size.height - petSize - bottomMargin - padding.bottom;

    return Offset(
      position.dx.clamp(8.0, maxX).toDouble(),
      position.dy.clamp(8.0, maxY).toDouble(),
    );
  }

  void _startMomentum(
      Offset pixelsPerSecond,
      Size size,
      EdgeInsets padding,
      ) {
    final currentPosition = _position;
    if (currentPosition == null) return;

    final simX = FrictionSimulation(
      0.12,
      currentPosition.dx,
      pixelsPerSecond.dx,
    );

    final simY = FrictionSimulation(
      0.12,
      currentPosition.dy,
      pixelsPerSecond.dy,
    );

    _simulation = _CombinedSimulation(simX, simY);

    _momentumController
      ..stop()
      ..value = 0
      ..animateWith(_simulation!);
  }

  Widget _buildChatBubble() {
    final chats = _activeChats.isEmpty
        ? const ['Tap me to check your tank 💧']
        : _activeChats;

    final safeIndex = _chatIndex % chats.length;
    final currentMessage = chats[safeIndex];

    final isStillTyping =
        _typedText.characters.length < currentMessage.characters.length;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
      child: !_showChatBubble
          ? const SizedBox(
        key: ValueKey('hidden-chat'),
        width: 0,
        height: 0,
      )
          : Container(
        key: ValueKey('chat-$safeIndex-${currentMessage.hashCode}'),
        constraints: const BoxConstraints(
          minWidth: 70,
          maxWidth: 185,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFBAE6FD),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _typedText,
                softWrap: true,
                style: const TextStyle(
                  color: Color(0xFF0369A1),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            if (isStillTyping)
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  '|',
                  style: TextStyle(
                    color: Color(0xFF0369A1),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final irrigation = context.watch<IrrigationController>();

    final prediction = irrigation.tankInsightForDisplay;
    final bool isUsingCached = irrigation.isUsingCachedTankInsight;

    final String? liveTankStatus =
        irrigation.telemetry?.tankStatus ?? irrigation.state?.tank;

    _activeChats = _buildSmartChats(
      prediction: prediction,
      isUsingCached: isUsingCached,
      liveTankStatus: liveTankStatus,
    );

    final padding = MediaQuery.of(context).padding;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          if (!_initialized) {
            _position = _getDefaultFabPosition(size, padding);
            _initialized = true;
          }

          return AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              final floatOffset = Tween<double>(
                begin: -6,
                end: 6,
              ).evaluate(
                CurvedAnimation(
                  parent: _floatController,
                  curve: Curves.easeInOut,
                ),
              );

              final currentPosition = _clampPosition(
                _position ?? _getDefaultFabPosition(size, padding),
                size,
                padding,
              );

              return Stack(
                children: [
                  Positioned(
                    left: currentPosition.dx,
                    top: currentPosition.dy + floatOffset,
                    child: child!,
                  ),
                ],
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _handlePetTap,
              onPanStart: (_) {
                _momentumController.stop();
              },
              onPanUpdate: (details) {
                setState(() {
                  final currentPosition =
                      _position ?? _getDefaultFabPosition(size, padding);

                  _position = _clampPosition(
                    currentPosition + details.delta,
                    size,
                    padding,
                  );
                });
              },
              onPanEnd: (details) {
                _startMomentum(
                  details.velocity.pixelsPerSecond,
                  size,
                  padding,
                );
              },
              child: SizedBox(
                width: petSize,
                height: petSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: 100,
                      top: 35,
                      child: _buildChatBubble(),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: SizedBox(
                        width: petSize,
                        height: petSize,
                        child: Lottie.asset(
                          'assets/lottie/mascot.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CombinedSimulation extends Simulation {
  final Simulation _simX;
  final Simulation _simY;

  _CombinedSimulation(this._simX, this._simY);

  @override
  double x(double time) => _simX.x(time);

  @override
  double dx(double time) => _simX.dx(time);

  @override
  bool isDone(double time) {
    return _simX.isDone(time) && _simY.isDone(time);
  }

  Offset position(double time) {
    return Offset(
      _simX.x(time),
      _simY.x(time),
    );
  }
}