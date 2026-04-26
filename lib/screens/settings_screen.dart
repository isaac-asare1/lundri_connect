// import 'package:flutter/material.dart';

// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({super.key});

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   bool _notifications = true;
//   bool _smsNotifications = true;
//   bool _emailAlerts = false;
//   bool _darkMode = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Settings')),
//       body: ListView(
//         padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
//         children: [
//           const Text(
//             'Notifications',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 8),
//           Card(
//             child: Column(
//               children: [
//                 SwitchListTile(
//                   value: _notifications,
//                   onChanged: (value) {
//                     setState(() {
//                       _notifications = value;
//                     });
//                   },
//                   title: const Text('Push Notifications'),
//                 ),
//                 SwitchListTile(
//                   value: _smsNotifications,
//                   onChanged: (value) {
//                     setState(() {
//                       _smsNotifications = value;
//                     });
//                   },
//                   title: const Text('SMS Alerts'),
//                 ),
//                 SwitchListTile(
//                   value: _emailAlerts,
//                   onChanged: (value) {
//                     setState(() {
//                       _emailAlerts = value;
//                     });
//                   },
//                   title: const Text('Email Alerts'),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 18),
//           const Text(
//             'Appearance',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//           ),
//           const SizedBox(height: 8),
//           Card(
//             child: SwitchListTile(
//               value: _darkMode,
//               onChanged: (value) {
//                 setState(() {
//                   _darkMode = value;
//                 });
//               },
//               title: const Text('Dark Mode'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:lundri_connect/core/routes/route_names.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = fb_auth.FirebaseAuth.instance;

  bool _notifications = true;
  bool _smsNotifications = true;
  bool _emailAlerts = false;
  final bool _darkMode = false;

  bool _loading = true;
  bool _saving = false;
  String _appVersion = '';

  String get _laundryId {
    final user = context.read<UserProvider>().currentUser;
    return user?.id ?? _auth.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _loadSettings() async {
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
      final settings = _asMap(data['settings']);
      final notifications = _asMap(settings['notifications']);

      _notifications = _readBool(
        notifications['notifications'],
        fallback: true,
      );
      _smsNotifications = _readBool(notifications['smsAlerts'], fallback: true);
      _emailAlerts = _readBool(notifications['emailAlerts'], fallback: false);
    } catch (e) {
      debugPrint('Load settings error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateNotificationSetting({
    required String field,
    required bool value,
  }) async {
    if (_laundryId.isEmpty) return;

    setState(() => _saving = true);

    try {
      await _firestore.collection('laundries').doc(_laundryId).set({
        'settings': {
          'notifications': {field: value},
        },
        'timestamps': {'updatedAt': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Update notification setting error: $e');
      if (!mounted) return;
      _showSnackBar('Could not update setting');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showDeleteAccountModal() async {
    final passwordController = TextEditingController();
    bool deleting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> deleteAccount() async {
              final user = _auth.currentUser;
              final email = user?.email;
              final password = passwordController.text.trim();

              if (user == null || email == null || email.isEmpty) {
                _showSnackBar('No signed-in account found');
                return;
              }

              if (password.isEmpty) {
                _showSnackBar('Enter your password to continue');
                return;
              }

              setModalState(() => deleting = true);

              try {
                final credential = fb_auth.EmailAuthProvider.credential(
                  email: email,
                  password: password,
                );

                await user.reauthenticateWithCredential(credential);

                final uid = user.uid;

                await _firestore.collection('laundries').doc(uid).delete();

                await _firestore
                    .collection('users')
                    .doc(uid)
                    .delete()
                    .catchError((_) {});

                await user.delete();

                if (!mounted) return;

                Navigator.of(sheetContext).pop();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              } on fb_auth.FirebaseAuthException catch (e) {
                debugPrint('Delete account auth error: ${e.code}');

                if (!mounted) return;

                String message = 'Could not delete account';

                if (e.code == 'wrong-password' ||
                    e.code == 'invalid-credential') {
                  message = 'Password is incorrect';
                } else if (e.code == 'requires-recent-login') {
                  message = 'Please log in again, then try deleting account';
                }

                _showSnackBar(message);
              } catch (e) {
                debugPrint('Delete account error: $e');
                if (!mounted) return;
                _showSnackBar('Could not delete account');
              } finally {
                if (mounted) setModalState(() => deleting = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E7EC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 58,
                      width: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE4E4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Color(0xFFD92D20),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Delete account?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will permanently delete your laundry profile and account. This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF667085),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: deleting
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: deleting ? null : deleteAccount,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: const Color(0xFFD92D20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              deleting ? 'Deleting...' : 'Delete',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                  value: _notifications,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() => _notifications = value);
                          _updateNotificationSetting(
                            field: 'notifications',
                            value: value,
                          );
                        },
                  title: const Text('Notifications'),
                ),
                SwitchListTile(
                  value: _smsNotifications,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() => _smsNotifications = value);
                          _updateNotificationSetting(
                            field: 'smsAlerts',
                            value: value,
                          );
                        },
                  title: const Text('SMS Alerts'),
                ),
                SwitchListTile(
                  value: _emailAlerts,
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() => _emailAlerts = value);
                          _updateNotificationSetting(
                            field: 'emailAlerts',
                            value: value,
                          );
                        },
                  title: const Text('Email Alerts'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'Legal',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Licence and Agreement'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.licenceAndAgreement,
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel),
                  title: const Text('Terms and Conditons'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.termsAndContions);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pushNamed(context, RouteNames.privacyPolicy);
                  },
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
              onChanged: null,
              title: const Text('Dark Mode'),
              subtitle: const Text('Not integrated yet'),
            ),
          ),

          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('App Version'),
              subtitle: Text(_appVersion.isEmpty ? 'Loading...' : _appVersion),
            ),
          ),

          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFD92D20),
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(
                  color: Color(0xFFD92D20),
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text('Permanently remove your account'),
              onTap: _showDeleteAccountModal,
            ),
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

  bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
