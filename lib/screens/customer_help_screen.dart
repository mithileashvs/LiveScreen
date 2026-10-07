import 'package:flutter/material.dart';
import '../theme/customer_theme.dart';

/// Customer Help & Support Screen.
/// Follows the LiveScreen customer design system:
/// Deep dark background (#08080A), metallic gold accents (#D4AF37),
/// subtle borders, and warm off-white typography.
class CustomerHelpScreen extends StatefulWidget {
  const CustomerHelpScreen({super.key});

  @override
  State<CustomerHelpScreen> createState() => _CustomerHelpScreenState();
}

class _CustomerHelpScreenState extends State<CustomerHelpScreen> {
  int? _expandedIndex;

  static const List<Map<String, String>> _faqs = [
    {
      'question': 'How does the interactive 3D venue view work?',
      'answer':
          'When selecting your seat, tap "Experience 3D Sightline". Our Unity-powered engine simulates the exact seat position, sightline to the cinema screen, and Dolby Atmos audio acoustics so you know precisely what your view will be before booking.',
    },
    {
      'question': 'Where do I find my booked tickets and QR code?',
      'answer':
          'All active and past bookings are instantly accessible in "My Bookings" in your navigation menu. Your digital ticket with admission QR code is also automatically sent via SMS and WhatsApp to your registered mobile number.',
    },
    {
      'question': 'Can I pre-order snacks and popcorn?',
      'answer':
          'Yes! During seat selection, proceed to "Grab a Bite" to choose from gourmet caramel popcorn, nachos, beverages, and combos. You can present your digital ticket QR code at the express counter on arrival.',
    },
    {
      'question': 'What is the ticket cancellation and refund policy?',
      'answer':
          'Cancellations are permitted up to 2 hours prior to the scheduled showtime, subject to the venue policy. Refunds are automatically processed back to your original payment method within 3 to 5 business days.',
    },
    {
      'question': 'What happens if my payment was deducted but booking is pending?',
      'answer':
          'If a banking network timeout occurs, any unconfirmed charges are refunded by your bank within 24 to 48 hours. You can also reach our 24/7 concierge hotline with your transaction ID for instant verification.',
    },
    {
      'question': 'Are wheelchair accessible seats and companion passes available?',
      'answer':
          'Yes, accessible companion seats are indicated with accessibility badges on the venue seat map. Our partner cinemas offer step-free access and dedicated wheelchair viewing bays.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CustomerColors.burgundy.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CustomerColors.borderBurgundySubtle),
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: CustomerColors.gold, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CustomerColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Assistance with 3D seat previews, bookings, tickets, and venues',
                      style: TextStyle(
                        fontSize: 13,
                        color: CustomerColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contact Channels
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                final cards = [
                  _buildContactCard(
                    icon: Icons.phone_in_talk_rounded,
                    title: '24/7 Guest Concierge',
                    detail: '+91 44 2841 9000',
                    actionLabel: 'Call Support',
                    onTap: () => _showContactSnackbar('Connecting to LiveScreen Concierge: +91 44 2841 9000'),
                  ),
                  _buildContactCard(
                    icon: Icons.mail_outline_rounded,
                    title: 'Email Assistance',
                    detail: 'support@livescreen.io',
                    actionLabel: 'Send Email',
                    onTap: () => _showContactSnackbar('Support email: support@livescreen.io'),
                  ),
                  _buildContactCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'WhatsApp Delivery',
                    detail: '+91 98400 12345',
                    actionLabel: 'Open Chat',
                    onTap: () => _showContactSnackbar('WhatsApp delivery support: +91 98400 12345'),
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        cards[i],
                        if (i < cards.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i < cards.length - 1) const SizedBox(width: 14),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // FAQ Section Header
            Row(
              children: const [
                Icon(Icons.quiz_outlined, size: 18, color: CustomerColors.gold),
                SizedBox(width: 8),
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: CustomerColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // FAQ List
            Container(
              decoration: BoxDecoration(
                color: CustomerColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CustomerColors.borderSubtle),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _faqs.length; i++) ...[
                    _buildFaqTile(i, _faqs[i]['question']!, _faqs[i]['answer']!),
                    if (i < _faqs.length - 1)
                      const Divider(color: CustomerColors.borderSubtle, height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bottom assistance banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CustomerColors.burgundyDark.withValues(alpha: 0.5),
                    CustomerColors.surfaceCard,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CustomerColors.borderBurgundySubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CustomerColors.burgundy.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: CustomerColors.gold, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Still have questions about your cinema visit?',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: CustomerColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Our customer success team is available 7 days a week from 9:00 AM to 11:00 PM IST.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: CustomerColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String detail,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CustomerColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CustomerColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: CustomerColors.gold, size: 18),
              ),
              const Spacer(),
              Text(
                actionLabel,
                style: const TextStyle(
                  color: CustomerColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: CustomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CustomerColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(int index, String question, String answer) {
    final isExpanded = _expandedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isExpanded ? FontWeight.w700 : FontWeight.w600,
                      color: isExpanded ? CustomerColors.gold : CustomerColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: CustomerColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Text(
                answer,
                style: const TextStyle(
                  fontSize: 13,
                  color: CustomerColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContactSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: CustomerColors.surfaceCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
