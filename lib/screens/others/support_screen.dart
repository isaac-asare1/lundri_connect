import 'package:flutter/material.dart';
import 'package:lundri_connect/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import 'live_chat_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const String _supportEmail = 'support@lundri.com';
  static const String _supportPhone = '0591334447';

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Lundri Support Request'},
    );

    if (!await launchUrl(uri)) {
      _showSnackBar(context, 'Could not open email app');
    }
  }

  Future<void> _callSupport(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _supportPhone);

    if (!await launchUrl(uri)) {
      _showSnackBar(context, 'Could not open phone dialer');
    }
  }

  void _openLiveChat(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LiveChatScreen(role: role)),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().selectedRole;

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _SupportTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Live Chat',
            subtitle: 'Chat with the Lundri support team.',
            onTap: () => _openLiveChat(context, role),
          ),
          const SizedBox(height: 12),
          _SupportTile(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: _supportEmail,
            onTap: () => _openEmail(context),
          ),
          const SizedBox(height: 12),
          _SupportTile(
            icon: Icons.phone_outlined,
            title: 'Call Support',
            subtitle: _supportPhone,
            onTap: () => _callSupport(context),
          ),
          const SizedBox(height: 18),
          const Text(
            'FAQs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const _FaqTile(
            question: 'How do I receive new laundry orders?',
            answer:
                'Make sure your laundry is online, approved, accepting orders, and accepting auto assignments.',
          ),
          const SizedBox(height: 10),
          const _FaqTile(
            question: 'Why am I not receiving orders?',
            answer:
                'Check your business location, working hours, online status, and current order count.',
          ),
          const SizedBox(height: 10),
          const _FaqTile(
            question: 'Can I change my pricing?',
            answer:
                'Yes. Go to Service Pricing or Business Info to update your laundry prices.',
          ),
          const SizedBox(height: 10),
          const _FaqTile(
            question: 'Can I update my working hours?',
            answer:
                'Yes. Go to Working Hours and save your weekly availability.',
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.softPink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              height: 1.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
