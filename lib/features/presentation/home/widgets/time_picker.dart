import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class TimePicker extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final ValueChanged<TimeOfDay>? onTimeChanged;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const TimePicker({
    super.key,
    this.initialHour = 8,
    this.initialMinute = 0,
    this.onTimeChanged,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<TimePicker> createState() => _TimePickerState();
}

enum _TimeInputMode {
  display,
  scroll,
  edit,
}

class _TimePickerState extends State<TimePicker> {
  late int hour12;
  late int minute;
  late String period;

  _TimeInputMode _mode = _TimeInputMode.display;

  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late final FocusNode _hourFocusNode;
  late final FocusNode _minuteFocusNode;

  late final FixedExtentScrollController _hourScrollController;
  late final FixedExtentScrollController _minuteScrollController;
  late final FixedExtentScrollController _periodScrollController;

  double? _lastDragAngle;
  bool _isDialDragging = false;
  bool _scrollLockedFromPointer = false;

  @override
  void initState() {
    super.initState();

    final initial24 = widget.initialHour;
    minute = widget.initialMinute;
    period = initial24 >= 12 ? 'PM' : 'AM';

    final h = initial24 % 12;
    hour12 = h == 0 ? 12 : h;

    _hourController = TextEditingController(
      text: hour12.toString().padLeft(2, '0'),
    );
    _minuteController = TextEditingController(
      text: minute.toString().padLeft(2, '0'),
    );

    _hourFocusNode = FocusNode();
    _minuteFocusNode = FocusNode();

    _hourScrollController = FixedExtentScrollController(
      initialItem: hour12 - 1,
    );
    _minuteScrollController = FixedExtentScrollController(
      initialItem: minute,
    );
    _periodScrollController = FixedExtentScrollController(
      initialItem: period == 'AM' ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocusNode.dispose();
    _minuteFocusNode.dispose();
    _hourScrollController.dispose();
    _minuteScrollController.dispose();
    _periodScrollController.dispose();
    super.dispose();
  }

  double get progress {
    final totalMinutes = ((hour12 % 12) * 60) + minute;
    return totalMinutes / 720;
  }

  String get formattedTime {
    final hh = hour12.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm $period';
  }

  int get hour24 {
    if (period == 'AM') {
      return hour12 == 12 ? 0 : hour12;
    } else {
      return hour12 == 12 ? 12 : hour12 + 12;
    }
  }

  void _notifyTimeChanged() {
    widget.onTimeChanged?.call(
      TimeOfDay(
        hour: hour24,
        minute: minute,
      ),
    );
  }

  void _syncControllers() {
    final hourText = hour12.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');

    _hourController.value = TextEditingValue(
      text: hourText,
      selection: TextSelection.collapsed(offset: hourText.length),
    );

    _minuteController.value = TextEditingValue(
      text: minuteText,
      selection: TextSelection.collapsed(offset: minuteText.length),
    );
  }

  void _syncScrollControllers() {
    if (_hourScrollController.hasClients) {
      _hourScrollController.jumpToItem(hour12 - 1);
    }
    if (_minuteScrollController.hasClients) {
      _minuteScrollController.jumpToItem(minute);
    }
    if (_periodScrollController.hasClients) {
      _periodScrollController.jumpToItem(period == 'AM' ? 0 : 1);
    }
  }

  void _setTime({
    required int newHour12,
    required int newMinute,
    required String newPeriod,
    bool syncText = true,
    bool syncScroll = true,
  }) {
    if (hour12 == newHour12 &&
        minute == newMinute &&
        period == newPeriod) {
      return;
    }

    setState(() {
      hour12 = newHour12;
      minute = newMinute;
      period = newPeriod;

      if (syncText) {
        _syncControllers();
      }
    });

    if (syncScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncScrollControllers();
      });
    }

    _notifyTimeChanged();
  }

  void _showInvalidTimeMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  bool _isHourValid(int? value) {
    return value != null && value >= 1 && value <= 12;
  }

  bool _isMinuteValid(int? value) {
    return value != null && value >= 0 && value <= 59;
  }

  void _applyTextEditLive() {
    final parsedHour = int.tryParse(_hourController.text.trim());
    final parsedMinute = int.tryParse(_minuteController.text.trim());

    if (_isHourValid(parsedHour) && _isMinuteValid(parsedMinute)) {
      _setTime(
        newHour12: parsedHour!,
        newMinute: parsedMinute!,
        newPeriod: period,
        syncText: false,
        syncScroll: true,
      );
    }
  }

  void _submitTextEdit() {
    final hourText = _hourController.text.trim();
    final minuteText = _minuteController.text.trim();

    final parsedHour = int.tryParse(hourText);
    final parsedMinute = int.tryParse(minuteText);

    if (hourText.isEmpty || minuteText.isEmpty) {
      _showInvalidTimeMessage('Please enter both hour and minute.');
      return;
    }

    if (!_isHourValid(parsedHour)) {
      _showInvalidTimeMessage('Hour must be from 1 to 12.');
      _hourFocusNode.requestFocus();
      _hourController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _hourController.text.length,
      );
      return;
    }

    if (!_isMinuteValid(parsedMinute)) {
      _showInvalidTimeMessage('Minute must be from 0 to 59.');
      _minuteFocusNode.requestFocus();
      _minuteController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _minuteController.text.length,
      );
      return;
    }

    _setTime(
      newHour12: parsedHour!,
      newMinute: parsedMinute!,
      newPeriod: period,
      syncText: true,
      syncScroll: true,
    );

    _closeInlineMode();
  }

  void _updatePeriodFromRotation(double currentAngle) {
    if (_lastDragAngle == null) {
      _lastDragAngle = currentAngle;
      return;
    }

    final previousAngle = _lastDragAngle!;

    if (previousAngle > 5.0 && currentAngle < 1.2) {
      period = period == 'AM' ? 'PM' : 'AM';
    } else if (previousAngle < 1.2 && currentAngle > 5.0) {
      period = period == 'AM' ? 'PM' : 'AM';
    }

    _lastDragAngle = currentAngle;
  }

  void _updateTimeFromOffset(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    double angle = atan2(dy, dx);
    angle += pi / 2;

    if (angle < 0) {
      angle += 2 * pi;
    }

    _updatePeriodFromRotation(angle);

    final rawMinutes = (angle / (2 * pi)) * 720;
    final snappedMinutes = (rawMinutes / 5).round() * 5;
    final safeMinutes = snappedMinutes == 720 ? 0 : snappedMinutes;

    final newHour = (safeMinutes ~/ 60) % 12;
    final newMinute = safeMinutes % 60;

    _setTime(
      newHour12: newHour == 0 ? 12 : newHour,
      newMinute: newMinute,
      newPeriod: period,
      syncScroll: false,
    );
  }

  bool _isPointerOnDial(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final distance = (localPosition - center).distance;

    const strokeWidth = 14.0;
    final radius = min(size.width, size.height) / 2 - strokeWidth - 4;

    return distance >= radius - 40 && distance <= radius + 32;
  }

  void _handlePointerDown(Offset localPosition, Size size) {
    if (_isPointerOnDial(localPosition, size)) {
      _scrollLockedFromPointer = true;
      widget.onDragStart?.call();
    }
  }

  void _handlePointerEnd() {
    if (_scrollLockedFromPointer || _isDialDragging) {
      _scrollLockedFromPointer = false;
      _isDialDragging = false;
      _lastDragAngle = null;
      _syncScrollControllers();
      widget.onDragEnd?.call();
    }
  }

  void _openScrollInline() {
    FocusScope.of(context).unfocus();

    setState(() {
      _mode = _TimeInputMode.scroll;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScrollControllers();
    });
  }

  void _openEditInline() {
    _syncControllers();

    setState(() {
      _mode = _TimeInputMode.edit;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourFocusNode.requestFocus();
      _hourController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _hourController.text.length,
      );
    });
  }

  void _closeInlineMode() {
    FocusScope.of(context).unfocus();

    setState(() {
      _mode = _TimeInputMode.display;
      _syncControllers();
    });
  }

  Widget _buildDisplayTime() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openScrollInline,
        onDoubleTap: _openEditInline,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            formattedTime,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B3B3B),
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerColumn({
    required double width,
    required FixedExtentScrollController controller,
    required int childCount,
    required ValueChanged<int> onSelectedItemChanged,
    required Widget Function(int index) itemBuilder,
  }) {
    return SizedBox(
      width: width,
      height: 120,
      child: CupertinoPicker.builder(
        scrollController: controller,
        itemExtent: 36,
        diameterRatio: 1.35,
        squeeze: 1.15,
        useMagnifier: true,
        magnification: 1.05,
        onSelectedItemChanged: onSelectedItemChanged,
        childCount: childCount,
        itemBuilder: (context, index) => Center(child: itemBuilder(index)),
      ),
    );
  }

  Widget _buildInlineScrollPicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPickerColumn(
                width: 62,
                controller: _hourScrollController,
                childCount: 12,
                onSelectedItemChanged: (index) {
                  _setTime(
                    newHour12: index + 1,
                    newMinute: minute,
                    newPeriod: period,
                    syncScroll: false,
                  );
                },
                itemBuilder: (index) => Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildPickerColumn(
                width: 62,
                controller: _minuteScrollController,
                childCount: 60,
                onSelectedItemChanged: (index) {
                  _setTime(
                    newHour12: hour12,
                    newMinute: index,
                    newPeriod: period,
                    syncScroll: false,
                  );
                },
                itemBuilder: (index) => Text(
                  index.toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 6),
              _buildPickerColumn(
                width: 72,
                controller: _periodScrollController,
                childCount: 2,
                onSelectedItemChanged: (index) {
                  _setTime(
                    newHour12: hour12,
                    newMinute: minute,
                    newPeriod: index == 0 ? 'AM' : 'PM',
                    syncScroll: false,
                  );
                },
                itemBuilder: (index) => Text(
                  index == 0 ? 'AM' : 'PM',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _closeInlineMode,
          child: const Text(
            'Done',
            style: TextStyle(
              color: Colors.lightBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineEditor() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 58,
                child: TextField(
                  controller: _hourController,
                  focusNode: _hourFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B3B3B),
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (_) => _applyTextEditLive(),
                  onSubmitted: (_) {
                    _minuteFocusNode.requestFocus();
                    _minuteController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _minuteController.text.length,
                    );
                  },
                ),
              ),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B3B3B),
                ),
              ),
              SizedBox(
                width: 58,
                child: TextField(
                  controller: _minuteController,
                  focusNode: _minuteFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B3B3B),
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  ),
                  onChanged: (_) => _applyTextEditLive(),
                  onSubmitted: (_) => _submitTextEdit(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _setTime(
                    newHour12: hour12,
                    newMinute: minute,
                    newPeriod: period == 'AM' ? 'PM' : 'AM',
                    syncText: false,
                    syncScroll: true,
                  );
                },
                child: Text(
                  period,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B3B3B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _submitTextEdit,
          child: const Text(
            'Done',
            style: TextStyle(
              color: Colors.lightBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeArea() {
    switch (_mode) {
      case _TimeInputMode.scroll:
        return _buildInlineScrollPicker();
      case _TimeInputMode.edit:
        return _buildInlineEditor();
      case _TimeInputMode.display:
        return _buildDisplayTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    const pickerSize = 220.0;
    final size = const Size(pickerSize, pickerSize);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Listener(
          onPointerDown: (event) {
            FocusScope.of(context).unfocus();
            _handlePointerDown(event.localPosition, size);
          },
          onPointerUp: (_) => _handlePointerEnd(),
          onPointerCancel: (_) => _handlePointerEnd(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: (details) {
              if (!_isPointerOnDial(details.localPosition, size)) return;
              _isDialDragging = true;
              _lastDragAngle = null;
              _updateTimeFromOffset(details.localPosition, size);
            },
            onPanUpdate: (details) {
              if (!_isDialDragging) return;
              _updateTimeFromOffset(details.localPosition, size);
            },
            onPanEnd: (_) => _handlePointerEnd(),
            onPanCancel: _handlePointerEnd,
            child: SizedBox(
              width: pickerSize,
              height: pickerSize,
              child: CustomPaint(
                painter: _TimePickerPainter(
                  progress: progress,
                  hour: hour12,
                  minute: minute,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _buildTimeArea(),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap to scroll • Double tap to edit',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF9AA3A8),
          ),
        ),
      ],
    );
  }
}

class _TimePickerPainter extends CustomPainter {
  final double progress;
  final int hour;
  final int minute;

  _TimePickerPainter({
    required this.progress,
    required this.hour,
    required this.minute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    final radius = min(size.width, size.height) / 2 - strokeWidth - 4;

    final bgPaint = Paint()
      ..color = const Color(0xFFE7E7E7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    final knobAngle = startAngle + sweepAngle;
    final knobOffset = Offset(
      center.dx + cos(knobAngle) * radius,
      center.dy + sin(knobAngle) * radius,
    );

    final knobPaint = Paint()..color = Colors.lightBlue;
    canvas.drawCircle(knobOffset, 10, knobPaint);

    final knobInnerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(knobOffset, 5, knobInnerPaint);

    final numberStyle = const TextStyle(
      color: Color(0xFF9AA3A8),
      fontSize: 11,
      fontWeight: FontWeight.w500,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final labelRadius = radius - 24;
      final offset = Offset(
        center.dx + cos(angle) * labelRadius,
        center.dy + sin(angle) * labelRadius,
      );

      final tp = TextPainter(
        text: TextSpan(text: '$i', style: numberStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(offset.dx - tp.width / 2, offset.dy - tp.height / 2),
      );
    }

    final minuteAngle = (minute * 6 - 90) * pi / 180;
    final hourAngle = (((hour % 12) + minute / 60) * 30 - 90) * pi / 180;

    final minutePaint = Paint()
      ..color = Colors.lightBlue
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final hourPaint = Paint()
      ..color = Colors.lightBlue
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final minuteEnd = Offset(
      center.dx + cos(minuteAngle) * (radius - 34),
      center.dy + sin(minuteAngle) * (radius - 34),
    );

    final hourEnd = Offset(
      center.dx + cos(hourAngle) * (radius - 54),
      center.dy + sin(hourAngle) * (radius - 54),
    );

    canvas.drawLine(center, hourEnd, hourPaint);
    canvas.drawLine(center, minuteEnd, minutePaint);

    final centerDotPaint = Paint()..color = Colors.lightBlue;
    canvas.drawCircle(center, 5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _TimePickerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.hour != hour ||
        oldDelegate.minute != minute;
  }
}