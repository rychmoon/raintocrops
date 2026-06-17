import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/features/auth/data/models/user_model.dart';
import '/features/auth/data/models/schedule_details_value.dart';

class ScheduleDetails extends StatefulWidget {
  final ValueChanged<ScheduleDetailsValue>? onChanged;

  final List<String>? initialSelectedDays;
  final String? initialNote;
  final bool? initialNotificationsEnabled;
  final String? initialCreatedBy;

  const ScheduleDetails({
    super.key,
    this.onChanged,
    this.initialSelectedDays,
    this.initialNote,
    this.initialNotificationsEnabled,
    this.initialCreatedBy,
  });

  @override
  State<ScheduleDetails> createState() => _ScheduleDetailsState();
}

class _ScheduleDetailsState extends State<ScheduleDetails> {
  late final TextEditingController _noteController;

  final List<String> _dayShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  final List<String> _dayFull = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  late List<bool> _selectedDays;
  late bool _notificationsEnabled;
  late String _createdBy;

  bool get _hasInitialCreatedBy =>
      widget.initialCreatedBy != null &&
          widget.initialCreatedBy!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _noteController = TextEditingController(text: widget.initialNote ?? '');

    _selectedDays = List.generate(7, (index) {
      return widget.initialSelectedDays?.contains(_dayFull[index]) ?? false;
    });

    _notificationsEnabled = widget.initialNotificationsEnabled ?? true;
    _createdBy = _hasInitialCreatedBy
        ? widget.initialCreatedBy!.trim()
        : 'Loading...';

    if (!_hasInitialCreatedBy) {
      _loadCurrentUser();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitChanged();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        if (!mounted) return;
        setState(() {
          _createdBy = 'No user';
        });
        _emitChanged();
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!mounted) return;

      if (!doc.exists || doc.data() == null) {
        setState(() {
          _createdBy = firebaseUser.email ?? 'Unknown user';
        });
        _emitChanged();
        return;
      }

      final userModel = UserModel.fromMap(doc.data()!, doc.id);

      final firstName = userModel.firstName.trim();
      final lastName = userModel.lastName.trim();
      final fullName = '$firstName $lastName'.trim();

      setState(() {
        _createdBy = fullName.isNotEmpty
            ? fullName
            : (userModel.email.isNotEmpty ? userModel.email : 'Unknown user');
      });

      _emitChanged();
    } catch (e) {
      debugPrint('Error loading current user: $e');

      if (!mounted) return;
      setState(() {
        _createdBy = 'Unknown user';
      });
      _emitChanged();
    }
  }

  void _emitChanged() {
    final selected = <String>[];

    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selected.add(_dayFull[i]);
      }
    }

    widget.onChanged?.call(
      ScheduleDetailsValue(
        selectedDays: selected,
        note: _noteController.text.trim(),
        notificationsEnabled: _notificationsEnabled,
        createdBy: _createdBy,
      ),
    );
  }

  bool get _isAllSelected => _selectedDays.every((day) => day);

  String get _selectedDaysText {
    if (_isAllSelected) return 'Everyday';

    final selected = <String>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selected.add(_dayFull[i]);
      }
    }

    if (selected.isEmpty) return 'No days selected';
    return selected.join(', ');
  }

  void _toggleDay(int index) {
    setState(() {
      _selectedDays[index] = !_selectedDays[index];
    });
    _emitChanged();
  }

  void _toggleAll() {
    setState(() {
      final shouldSelectAll = !_isAllSelected;
      _selectedDays = List.generate(7, (_) => shouldSelectAll);
    });
    _emitChanged();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryText = Color(0xFF0F172A);
    const Color secondaryText = Color(0xFF64748B);
    const Color accent = Color(0xFF38BDF8);
    const Color cardColor = Colors.white;
    const Color innerCardColor = Color(0xFFF8FAFC);
    const Color borderColor = Color(0xFFE2E8F0);
    const Color chipBg = Color(0xFFF8FAFC);
    const Color inputBg = Color(0xFFFFFFFF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: accent,
              ),
              SizedBox(width: 8),
              Text(
                'Schedule details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _selectedDaysText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Select days',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDayChip(
                  label: 'All',
                  selected: _isAllSelected,
                  onTap: _toggleAll,
                  isAll: true,
                ),
                const SizedBox(width: 8),
                ...List.generate(_dayShort.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildDayChip(
                      label: _dayShort[index],
                      selected: _selectedDays[index],
                      onTap: () => _toggleDay(index),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: innerCardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoBlock(
                  icon: Icons.person_outline_rounded,
                  label: 'Scheduled by',
                  value: _createdBy,
                ),
                const SizedBox(height: 16),
                _buildNoteBlock(
                  controller: _noteController,
                  hintText: 'Add note',
                  fillColor: inputBg,
                  borderColor: borderColor,
                  focusColor: accent,
                ),
                const SizedBox(height: 16),
                _buildSwitchBlock(
                  icon: Icons.notifications_none_rounded,
                  title: 'Allow notifications',
                  subtitle: 'Get alerts related to this schedule',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _emitChanged();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isAll = false,
  }) {
    const Color accent = Color(0xFF38BDF8);
    const Color chipBg = Color(0xFFF8FAFC);
    const Color borderColor = Color(0xFFE2E8F0);
    const Color selectedText = Colors.white;
    const Color unselectedText = Color(0xFF334155);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isAll ? 14 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? accent : chipBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : borderColor,
            width: 1.2,
          ),
          boxShadow: selected
              ? const [
            BoxShadow(
              color: Color(0x1A38BDF8),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? selectedText : unselectedText,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBlock({
    required IconData icon,
    required String label,
    required String value,
  }) {
    const Color primaryText = Color(0xFF0F172A);
    const Color secondaryText = Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 2),
            Icon(icon, size: 18, color: secondaryText),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildNoteBlock({
    required TextEditingController controller,
    required String hintText,
    required Color fillColor,
    required Color borderColor,
    required Color focusColor,
  }) {
    const Color primaryText = Color(0xFF0F172A);
    const Color secondaryText = Color(0xFF64748B);
    const Color hintColor = Color(0xFF94A3B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            SizedBox(width: 2),
            Icon(Icons.edit_note_rounded, size: 18, color: secondaryText),
            SizedBox(width: 8),
            Text(
              'Note',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          onChanged: (_) => _emitChanged(),
          textAlign: TextAlign.left,
          maxLines: 2,
          minLines: 1,
          style: const TextStyle(
            color: primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: hintColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: focusColor, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchBlock({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    const Color primaryText = Color(0xFF0F172A);
    const Color secondaryText = Color(0xFF64748B);
    const Color accent = Color(0xFF38BDF8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: secondaryText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.92,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD7E0E7),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}