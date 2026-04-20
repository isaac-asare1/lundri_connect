import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _smsNotifications = true;
  bool _emailAlerts = false;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                  title: const Text('Push Notifications'),
                ),
                SwitchListTile(
                  value: _smsNotifications,
                  onChanged: (value) {
                    setState(() {
                      _smsNotifications = value;
                    });
                  },
                  title: const Text('SMS Alerts'),
                ),
                SwitchListTile(
                  value: _emailAlerts,
                  onChanged: (value) {
                    setState(() {
                      _emailAlerts = value;
                    });
                  },
                  title: const Text('Email Alerts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              value: _darkMode,
              onChanged: (value) {
                setState(() {
                  _darkMode = value;
                });
              },
              title: const Text('Dark Mode'),
            ),
          ),
        ],
      ),
    );
  }
}
