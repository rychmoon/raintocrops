import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const List<_TermItem> _terms = [
    _TermItem(
      icon: Icons.phone_iphone_rounded,
      title: 'Use of the App',
      content:
      'RainToCrops is designed to help users monitor and manage irrigation-related features. You agree to use the app responsibly and only for its intended purpose.',
    ),
    _TermItem(
      icon: Icons.verified_user_outlined,
      title: 'Accounts and Device Access',
      content:
      'Users are responsible for keeping their account secure. Device access, ownership, and viewing permissions may depend on successful pairing and assigned user roles.',
    ),
    _TermItem(
      icon: Icons.hub_outlined,
      title: 'Device Pairing',
      content:
      'Connected devices may be linked to specific user accounts. Some features may only be available after a device is successfully paired and recognized by the system.',
    ),
    _TermItem(
      icon: Icons.lock_outline_rounded,
      title: 'Data and Privacy',
      content:
      'The app may store account information, device identifiers, and usage data to support features such as monitoring, notifications, and device management.',
    ),
    _TermItem(
      icon: Icons.warning_amber_rounded,
      title: 'Service Limitations',
      content:
      'We aim to provide a reliable experience, but we cannot guarantee uninterrupted service, exact sensor accuracy, or the prevention of crop, hardware, or connectivity issues.',
    ),
    _TermItem(
      icon: Icons.update_rounded,
      title: 'Changes to Terms',
      content:
      'These terms may be updated over time. Continued use of the app after updates means you accept the latest version of these terms.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor =
    isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);
    final titleColor =
    isDark ? Colors.white : const Color(0xFF111827);
    final bodyColor =
    isDark ? const Color(0xFFCBD5E1) : const Color(0xFF6B7280);
    final subColor =
    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final infoBg =
    isDark ? const Color(0xFF0B2545) : const Color(0xFFEFF6FF);
    final infoBorder =
    isDark ? const Color(0xFF1D4ED8) : const Color(0xFFBFDBFE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgColor,
        centerTitle: true,
        iconTheme: IconThemeData(color: titleColor),
        title: Text(
          'Terms & Conditions',
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: infoBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: infoBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: isDark
                              ? const Color(0xFFBFDBFE)
                              : Colors.lightBlue.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Simple guidelines for using RainToCrops',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Please review the basic terms for account usage, device access, privacy, and service limitations when using the app.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.65,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: subColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last updated: March 2026',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ..._terms.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _TermCard(
                  item: item,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  titleColor: titleColor,
                  bodyColor: bodyColor,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'For informational purposes only.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: subColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermItem {
  final IconData icon;
  final String title;
  final String content;

  const _TermItem({
    required this.icon,
    required this.title,
    required this.content,
  });
}

class _TermCard extends StatelessWidget {
  final _TermItem item;
  final Color cardColor;
  final Color borderColor;
  final Color titleColor;
  final Color bodyColor;
  final bool isDark;

  const _TermCard({
    required this.item,
    required this.cardColor,
    required this.borderColor,
    required this.titleColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0x0A000000),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF172554)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              color: isDark
                  ? const Color(0xFF93C5FD)
                  : Colors.lightBlue.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 13.8,
                    height: 1.7,
                    color: bodyColor,
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