import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const bgColor = Color(0xFFF6F6F6);
  static const textColor = Color(0xFF111827);
  static const subtitleColor = Color(0xFF6B7280);
  static const mutedColor = Color(0xFF94A3B8);
  static const lineColor = Color(0xFFE5E7EB);
  static const accentColor = Color(0xFF2563EB);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    precacheImage(const AssetImage('assets/images/app_icon_v2.png'), context);

    precacheImage(
      const AssetImage('assets/images/tech_stack_img/flutter.png'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/tech_stack_img/espressif.png'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/tech_stack_img/mqtt.png'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/tech_stack_img/firebase.png'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/qcu_logo.webp'),
      context,
    );
  }

  TextStyle get _appBarTitle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: textColor,
  );

  TextStyle get _heroTitle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
    color: textColor,
  );

  TextStyle get _versionText => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: subtitleColor,
  );

  TextStyle get _bodyText => const TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    height: 1.7,
    letterSpacing: 0.1,
    color: subtitleColor,
  );

  TextStyle get _sectionLabel => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Color(0xFF475569),
  );

  TextStyle get _techTitle => const TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: textColor,
  );

  TextStyle get _tapHint => const TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: mutedColor,
  );

  TextStyle get _memberName => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: textColor,
  );

  TextStyle get _memberRole => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: subtitleColor,
  );

  TextStyle get _footerTitle => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    color: textColor,
  );

  TextStyle get _footerSubtitle => const TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: subtitleColor,
  );

  void _showTechDialog({
    required String title,
    required String imagePath,
    required String shortDescription,
    required String purpose,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 82,
                    height: 82,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF3F6FA),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(imagePath),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shortDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.55,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: lineColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Purpose in the System',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                purpose,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  height: 1.65,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final techItems = [
      (
      'Flutter',
      'assets/images/tech_stack_img/flutter.png',
      'Builds the mobile app interface',
      'Flutter is used to create the RainToCrops mobile application. It handles the user interface, navigation, and dashboard so users can monitor sensors, view system data, and control irrigation features smoothly.',
      Icons.phone_android_rounded,
      ),
      (
      'ESP32',
      'assets/images/tech_stack_img/espressif.png',
      'Controls the hardware and sensors',
      'ESP32 serves as the brain of the system. It reads data from sensors such as soil moisture, pH, water level, and rain monitoring components, then processes and sends that information to the app.',
      Icons.memory_rounded,
      ),
      (
      'MQTT',
      'assets/images/tech_stack_img/mqtt.png',
      'Transfers data in real time',
      'MQTT is the communication protocol between the ESP32 and the mobile app. It allows fast and lightweight real-time sending of sensor readings, notifications, and irrigation commands.',
      Icons.sync_alt_rounded,
      ),
      (
      'Firebase',
      'assets/images/tech_stack_img/firebase.png',
      'Stores cloud data and user records',
      'Firebase is used for authentication, cloud storage, and database functions. It keeps user accounts, device-linked information, saved data, and other records accessible and secure.',
      Icons.cloud_done_rounded,
      ),
    ];

    final members = [
      (
      'Samantha Grace R. Cesar',
      'Project Manager',
      'assets/images/about_img/sam.jpg',
      ),
      (
      'Richmond Angelo T. Homo',
      'Full Stack Developer',
      'assets/images/about_img/richmond.png',
      ),
      (
      'James M. Belarmino',
      'Associate Developer',
      'assets/images/about_img/james.jpg',
      ),
      (
      'Allyssa Ashley M. Bren',
      '',
      'assets/images/about_img/bren.jpg',
      ),
      (
      'Anna Jhana Marae Dapilos',
      'Documentation Specialist',
      'assets/images/about_img/janna.jpg',
      ),
      (
      'Jerome G. Faustino',
      'Documentation Lead',
      'assets/images/about_img/jerome.png',
      ),
      (
      'Candace Beatrix M. Gubat',
      'Documentation Associate',
      'assets/images/about_img/candace.jpg',
      ),
      (
      'Coleen Mae A. Javar',
      'Documentation Specialist',
      'assets/images/about_img/javar.png',
      ),
      (
      'Ryan Jules SJ. Ordiales',
      'Hardware Specialist',
      'assets/images/about_img/ryan.png',
      ),
      (
      'Christian Rosario',
      'Hardware Specialist',
      'assets/images/about_img/rosario.png',
      ),
      (
      'Jayvee A. Salinas',
      'Hardware Specialist',
      'assets/images/about_img/jayvee.png',
      ),
      (
      'Timmy E. Tolledo',
      'Programmer',
      'assets/images/about_img/timmy.png',
      ),
      (
      'Paulyarnan Milen F. Tornea',
      'Hardware Specialist',
      'assets/images/about_img/torne.png',
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: textColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('About', style: _appBarTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _card(
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF1F4F9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_icon_v2.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('RainToCrops', style: _heroTitle),
                const SizedBox(height: 6),
                Text('Version 1.0.0', style: _versionText),
                const SizedBox(height: 18),
                const Divider(color: lineColor, thickness: 1),
                const SizedBox(height: 14),
                Text(
                  'RainToCrops is a smart irrigation system that combines rainwater harvesting and modern technology to help CUAI farmers monitor, manage, and sustain their crops more efficiently.',
                  textAlign: TextAlign.center,
                  style: _bodyText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _card(
            child: Column(
              children: [
                _sectionTitle('TECHNOLOGIES USED'),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: techItems.map((tech) {
                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            _showTechDialog(
                              title: tech.$1,
                              imagePath: tech.$2,
                              shortDescription: tech.$3,
                              purpose: tech.$4,
                              icon: tech.$5,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFF1F4F9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(tech.$2),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tech.$1,
                                  textAlign: TextAlign.center,
                                  style: _techTitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to view',
                                  textAlign: TextAlign.center,
                                  style: _tapHint,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _card(
            child: Column(
              children: [
                _sectionTitle('OUR TEAM'),
                const SizedBox(height: 12),
                ...members.asMap().entries.map((entry) {
                  final index = entry.key;
                  final m = entry.value;
                  final hasRole = m.$2.trim().isNotEmpty;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        minVerticalPadding: 10,
                        leading: CircleAvatar(
                          radius: 23,
                          backgroundImage: AssetImage(m.$3),
                        ),
                        title: Text(m.$1, style: _memberName),
                        subtitle: hasRole
                            ? Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(m.$2, style: _memberRole),
                        )
                            : null,
                      ),
                      if (index != members.length - 1)
                        const Divider(
                          color: lineColor,
                          thickness: 1,
                          height: 10,
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _card(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: lineColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/qcu_logo.webp',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capstone Project • 2026',
                        style: _footerTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quezon City University',
                        style: _footerSubtitle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: lineColor, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: _sectionLabel),
        ),
        const Expanded(
          child: Divider(color: lineColor, thickness: 1),
        ),
      ],
    );
  }
}