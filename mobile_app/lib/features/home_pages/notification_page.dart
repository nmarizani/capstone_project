import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, dynamic>> _notifications = const [
    {
      'level': 'critical',
      'title': 'Critical Range Patients',
      'patient': 'PT-2026-0046',
      'message': 'significant morphology shifts, immediate intervention required',
      'time': '1 min',
    },
    {
      'level': 'warning',
      'title': 'Warning Range Patients',
      'patient': 'PT-2026-0952',
      'message': 'damping detected, elevated hr, re-check in 15 minutes',
      'time': '5 min',
    },
    {
      'level': 'normal',
      'title': 'Normal Range Patients',
      'patient': 'PT-2026-0845',
      'message': 'stable waveform, clear dicrotic notch, hr 60-90 bpm',
      'time': '10 min',
    },
  ];

  Color _levelColor(String level) {
    switch (level) {
      case 'critical':
        return AppColors.danger;
      case 'warning':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_notifications.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _buildNotificationCard(_notifications[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final color = _levelColor(notif['level']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif['title'],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '1 pt - ${notif['patient']}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notif['message'],
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 13,
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