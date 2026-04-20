import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/custom_button.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  final Map<String, bool> _enabledDays = {
    'Monday': true,
    'Tuesday': true,
    'Wednesday': true,
    'Thursday': true,
    'Friday': true,
    'Saturday': true,
    'Sunday': false,
  };

  final Map<String, String> _openTimes = {
    'Monday': '08:00 AM',
    'Tuesday': '08:00 AM',
    'Wednesday': '08:00 AM',
    'Thursday': '08:00 AM',
    'Friday': '08:00 AM',
    'Saturday': '09:00 AM',
    'Sunday': '09:00 AM',
  };

  final Map<String, String> _closeTimes = {
    'Monday': '06:00 PM',
    'Tuesday': '06:00 PM',
    'Wednesday': '06:00 PM',
    'Thursday': '06:00 PM',
    'Friday': '06:00 PM',
    'Saturday': '04:00 PM',
    'Sunday': '02:00 PM',
  };

  @override
  Widget build(BuildContext context) {
    final days = _enabledDays.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Working Hours')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const Text(
            'Set your weekly business availability.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...days.map(
            (day) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch(
                          value: _enabledDays[day] ?? false,
                          onChanged: (value) {
                            setState(() {
                              _enabledDays[day] = value;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_enabledDays[day] ?? false) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeBox(
                              label: 'Open',
                              value: _openTimes[day] ?? '',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimeBox(
                              label: 'Close',
                              value: _closeTimes[day] ?? '',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Save Hours',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Working hours saved'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String value;

  const _TimeBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
