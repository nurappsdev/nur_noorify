import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: const [
          _PolicySection(
            title: 'What We Collect',
            body:
                'This app may use location, notification preference, and offline Quran cache data to provide core Islamic app features.',
          ),
          _PolicySection(
            title: 'Location',
            body:
                'Location is used for prayer, Sehri, and Iftar times. If location is off or denied, fallback timing (Baitul Mukarram, Dhaka) is used.',
          ),
          _PolicySection(
            title: 'Notifications',
            body:
                'When enabled, notifications are used for prayer-related reminders such as Sehri and Iftar alerts.',
          ),
          _PolicySection(
            title: 'Offline Storage',
            body:
                'Quran text and downloaded audio can be saved on device for offline access. You can clear cache anytime from Settings.',
          ),
          _PolicySection(
            title: 'Data Sharing',
            body:
                'We do not sell your personal data. Prayer-time API calls are used only to fetch required Islamic timing content.',
          ),
          _PolicySection(
            title: 'Your Control',
            body:
                'You can change location mode, notification options, and clear cached data in app settings.',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFFE1E8EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            Text(
              body,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
