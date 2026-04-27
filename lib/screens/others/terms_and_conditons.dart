import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = _termsSections;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _TermsTopBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                itemCount: sections.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) return const _TermsHeader();

                  if (index == sections.length + 1) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Last Updated: April 2026',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8A8A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  final section = sections[index - 1];
                  return _TermsSectionCard(section: section);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsTopBar extends StatelessWidget {
  const _TermsTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 28),
            ),
          ),
          const Text(
            'Terms & Conditions',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TermsHeader extends StatelessWidget {
  const _TermsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18, top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lundri Terms & Conditions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'These Terms govern your use of the Lundri app. By using Lundri, you agree to these terms.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSectionCard extends StatelessWidget {
  final TermsSection section;

  const _TermsSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          ...section.paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                p,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF444444),
                ),
              ),
            ),
          ),

          if (section.bullets.isNotEmpty)
            ...section.bullets.map(
              (b) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.circle, size: 6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(b, style: const TextStyle(fontSize: 15)),
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

class TermsSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const TermsSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

const List<TermsSection> _termsSections = [
  TermsSection(
    title: '1. Using Lundri',
    paragraphs: [
      'You agree to use Lundri responsibly and provide accurate information.',
    ],
  ),
  TermsSection(
    title: '2. Orders & Services',
    bullets: [
      'Laundry partners handle washing and ironing.',
      'Riders handle pickup and delivery.',
      'Service times may vary.',
    ],
  ),
  TermsSection(
    title: '3. Payments',
    bullets: [
      'All payments must be completed before delivery.',
      'Prices may change based on actual weight.',
    ],
  ),
  TermsSection(
    title: '4. Cancellations',
    paragraphs: ['Orders can be cancelled before processing begins.'],
  ),
  TermsSection(
    title: '5. Liability',
    paragraphs: [
      'Lundri is not responsible for damage caused by incorrect care instructions.',
    ],
  ),
  TermsSection(
    title: '6. Account Termination',
    paragraphs: ['We may suspend or delete accounts that misuse the platform.'],
  ),
];
