import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_button.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  bool _saving = false;

  final List<_DayConfig> _days = const [
    _DayConfig(label: 'Monday', key: 'mon'),
    _DayConfig(label: 'Tuesday', key: 'tue'),
    _DayConfig(label: 'Wednesday', key: 'wed'),
    _DayConfig(label: 'Thursday', key: 'thu'),
    _DayConfig(label: 'Friday', key: 'fri'),
    _DayConfig(label: 'Saturday', key: 'sat'),
    _DayConfig(label: 'Sunday', key: 'sun'),
  ];

  final Map<String, bool> _enabledDays = {};
  final Map<String, TimeOfDay> _openTimes = {};
  final Map<String, TimeOfDay> _closeTimes = {};

  String get _laundryId {
    final user = context.read<UserProvider>().currentUser;
    return user?.id ?? '';
  }

  @override
  void initState() {
    super.initState();
    _setDefaults();
    _loadWorkingHours();
  }

  void _setDefaults() {
    for (final day in _days) {
      _enabledDays[day.key] = day.key != 'sun';
      _openTimes[day.key] = const TimeOfDay(hour: 8, minute: 0);
      _closeTimes[day.key] = const TimeOfDay(hour: 18, minute: 0);
    }

    _openTimes['sat'] = const TimeOfDay(hour: 9, minute: 0);
    _closeTimes['sat'] = const TimeOfDay(hour: 16, minute: 0);
    _openTimes['sun'] = const TimeOfDay(hour: 9, minute: 0);
    _closeTimes['sun'] = const TimeOfDay(hour: 14, minute: 0);
  }

  Future<void> _loadWorkingHours() async {
    if (_laundryId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await _firestore
          .collection('laundries')
          .doc(_laundryId)
          .get();
      final data = doc.data() ?? {};
      final openingHours = _asMap(data['openingHours']);

      for (final day in _days) {
        final dayData = _asMap(openingHours[day.key]);

        _enabledDays[day.key] = _readBool(
          dayData['isOpen'],
          fallback: _enabledDays[day.key] ?? false,
        );

        _openTimes[day.key] = _parse24HourTime(
          _readString(dayData['open']),
          fallback: _openTimes[day.key] ?? const TimeOfDay(hour: 8, minute: 0),
        );

        _closeTimes[day.key] = _parse24HourTime(
          _readString(dayData['close']),
          fallback:
              _closeTimes[day.key] ?? const TimeOfDay(hour: 18, minute: 0),
        );
      }
    } catch (e) {
      debugPrint('Load working hours error: $e');
      _showSnackBar('Could not load working hours');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveWorkingHours() async {
    if (_laundryId.isEmpty || _saving) return;

    setState(() => _saving = true);

    try {
      final openingHours = <String, dynamic>{};

      for (final day in _days) {
        openingHours[day.key] = {
          'isOpen': _enabledDays[day.key] ?? false,
          'open': _format24Hour(_openTimes[day.key]!),
          'close': _format24Hour(_closeTimes[day.key]!),
        };
      }

      await _firestore.collection('laundries').doc(_laundryId).set({
        'openingHours': openingHours,
        'timestamps': {'updatedAt': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));

      if (!mounted) return;
      _showSnackBar('Working hours saved');
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Save working hours error: $e');
      _showSnackBar('Could not save working hours');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime({
    required String dayKey,
    required bool isOpeningTime,
  }) async {
    final initialTime = isOpeningTime
        ? _openTimes[dayKey]!
        : _closeTimes[dayKey]!;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    setState(() {
      if (isOpeningTime) {
        _openTimes[dayKey] = picked;
      } else {
        _closeTimes[dayKey] = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Working Hours')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const Text(
            'Set your weekly business availability',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          ..._days.map((day) {
            final isEnabled = _enabledDays[day.key] ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            day.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Switch(
                          value: isEnabled,
                          onChanged: _saving
                              ? null
                              : (value) {
                                  setState(() {
                                    _enabledDays[day.key] = value;
                                  });
                                },
                        ),
                      ],
                    ),
                    if (isEnabled) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeBox(
                              label: 'Open',
                              value: _formatDisplayTime(
                                context,
                                _openTimes[day.key]!,
                              ),
                              onTap: _saving
                                  ? null
                                  : () => _pickTime(
                                      dayKey: day.key,
                                      isOpeningTime: true,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimeBox(
                              label: 'Close',
                              value: _formatDisplayTime(
                                context,
                                _closeTimes[day.key]!,
                              ),
                              onTap: _saving
                                  ? null
                                  : () => _pickTime(
                                      dayKey: day.key,
                                      isOpeningTime: false,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          CustomButton(
            text: _saving ? 'Saving...' : 'Save Hours',
            onPressed: _saving ? null : _saveWorkingHours,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  TimeOfDay _parse24HourTime(String value, {required TimeOfDay fallback}) {
    final parts = value.split(':');
    if (parts.length != 2) return fallback;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return fallback;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return fallback;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _format24Hour(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDisplayTime(BuildContext context, TimeOfDay time) {
    return time.format(context);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _DayConfig {
  final String label;
  final String key;

  const _DayConfig({required this.label, required this.key});
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _TimeBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }
}
