import 'package:flutter/material.dart';
import '../theme/platform_admin_theme.dart';

/// Master Platform Admin Help & Support Page.
/// Explains the 8 platform operations workflows, FAQ, and governance guidelines.
class PlatformAdminHelpScreen extends StatefulWidget {
  const PlatformAdminHelpScreen({super.key});

  @override
  State<PlatformAdminHelpScreen> createState() => _PlatformAdminHelpScreenState();
}

class _PlatformAdminHelpScreenState extends State<PlatformAdminHelpScreen> {
  String? _expandedTopicId;

  final List<Map<String, String>> _topics = const [
    {
      'id': 'theatres',
      'title': 'Theatre Management',
      'icon': 'domain',
      'description':
          'Review venue configurations submitted by cinema operators. Verifying a theatre unlocks showtime scheduling, 3D seat mapping, and public ticketing.',
      'details':
          'When an operator registers a theatre venue, it appears in "Pending" status. Platform Admins can inspect venue room dimensions, screen curves, seat arrangements, and spatial audio speakers. Approving changes status to "Verified". Rejections require a documented justification stamped in the audit trail.',
    },
    {
      'id': 'producers',
      'title': 'Producer Management',
      'icon': 'groups',
      'description':
          'Verify studio and producer accounts before they can distribute content across LiveScreen venues.',
      'details':
          'Producers must undergo account verification before movie submissions can be approved. Platform Admins review organization profiles and contact details. Once verified, producers gain full distribution catalogue rights.',
    },
    {
      'id': 'movies',
      'title': 'Movie & Content Approval',
      'icon': 'movie',
      'description':
          'Review submitted film metadata, standard trailers, and immersive WebGL trailer assets before publishing.',
      'details':
          'Every movie undergoes two stages: Approval (verifying metadata, rating, duration, and trailer media) followed by Publishing. Only published movies become available for theatre admins to schedule onto real screens and for customers to book.',
    },
    {
      'id': 'verifications',
      'title': 'Verifications & Ownership',
      'icon': 'verified',
      'description':
          'Central hub for vetting venues, producer credentials, and theatre ownership authorizations.',
      'details':
          'Separates venue verification from operator ownership. A theatre operator must be authorized by Platform Admin before they can edit or schedule shows for a specific cinema venue.',
    },
    {
      'id': 'bookings',
      'title': 'Platform Bookings',
      'icon': 'confirmation_number',
      'description':
          'Live oversight of customer seat reservations, ticket confirmation codes, and transactional records.',
      'details':
          'Monitors reservation volume and seat lock states. SQL unique constraints prevent double booking across synchronized shows. Platform Admins have read-only audit visibility over platform-wide orders.',
    },
    {
      'id': 'users',
      'title': 'User Management & Roles',
      'icon': 'people',
      'description':
          'Comprehensive directory of registered accounts categorized by role (Customer, Theatre Admin, Producer, Platform Admin).',
      'details':
          'LiveScreen enforces strict role-based access control (RBAC). Platform Admin is the highest privilege tier with universal read/write permissions enforced by Supabase database policies.',
    },
    {
      'id': 'analytics',
      'title': 'Platform Analytics',
      'icon': 'bar_chart',
      'description':
          'Aggregated platform metrics covering catalogue volume, active published showtimes, and theatre capacity.',
      'details':
          'Metrics are derived directly from live database tables without synthetic projections. Use the analytics module to track operational health and growth across regions.',
    },
    {
      'id': 'audit_logs',
      'title': 'Audit Logs',
      'icon': 'receipt_long',
      'description':
          'Immutable record of all verification transitions, approval timestamps, reviewer identities, and stated reasons.',
      'details':
          'Every status update triggers a database-level audit stamp recording who reviewed the entity, previous state, new state, and review justification notes. This log cannot be altered or removed.',
    },
  ];

  final List<Map<String, String>> _faqs = const [
    {
      'q': 'How does a movie become available for customer booking?',
      'a':
          'A producer first submits the film title and media assets. The Platform Admin reviews and approves it, then clicks "Publish". Once published, verified Theatre Admins can schedule shows for that movie in their auditoriums.',
    },
    {
      'q': 'What happens when a theatre verification is rejected?',
      'a':
          'The Platform Admin must provide an explanation in the prompt. The theatre status becomes "rejected", the reason is saved in review_reason, and the entry is permanently recorded in the verification audit log.',
    },
    {
      'q': 'Can a theatre operator schedule shows before venue verification?',
      'a':
          'No. Database RLS policies and screen logic require both the theatre venue to be verified and the operator to have verified ownership authorization before shows can be created.',
    },
    {
      'q': 'How are duplicate seat bookings prevented?',
      'a':
          'The Supabase PostgreSQL database employs partial unique indexes on (theatre_id, show_id, seat_id). If two users attempt to purchase the exact same seat simultaneously, the database rejects the duplicate transaction with error code 23505.',
    },
  ];

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'domain':
        return Icons.domain_outlined;
      case 'groups':
        return Icons.groups_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'verified':
        return Icons.verified_user_outlined;
      case 'confirmation_number':
        return Icons.confirmation_number_outlined;
      case 'people':
        return Icons.people_outline_rounded;
      case 'bar_chart':
        return Icons.bar_chart_rounded;
      case 'receipt_long':
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAdminScaffold(
      activeKey: 'dashboard',
      activeSecondaryKey: 'help',
      pageTitle: 'Help & Support',
      pageSubtitle: 'Operational documentation, verification workflows, and platform administration guide.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Help Center Hero Card
          _buildHeroCard(),
          const SizedBox(height: 24),

          // 2. Operational Workflows Section Header
          const Text(
            'Operational Workflows',
            style: TextStyle(
              color: PlatformAdminColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select a domain to inspect platform governance rules and procedures.',
            style: TextStyle(color: PlatformAdminColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Topics Accordion Grid
          Column(
            children: _topics.map((t) => _buildTopicTile(t)).toList(),
          ),
          const SizedBox(height: 28),

          // 3. Platform FAQ Section
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: PlatformAdminColors.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Key answers regarding LiveScreen architecture, policies, and workflows.',
            style: TextStyle(color: PlatformAdminColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Column(
            children: _faqs.map((f) => _buildFaqTile(f)).toList(),
          ),
          const SizedBox(height: 24),

          // 4. Support Desk State
          _buildSupportDeskCard(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlatformAdminColors.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF14120C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PlatformAdminColors.gold, width: 1.0),
            ),
            child: const Icon(Icons.help_center_outlined, color: PlatformAdminColors.gold, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Platform Admin Operations Center',
                  style: TextStyle(
                    color: PlatformAdminColors.textWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'As a Platform Administrator, you govern the entire LiveScreen lifecycle. Every verification transition, film publication, and operator authorization maintains the integrity of the customer ticketing experience.',
                  style: TextStyle(color: PlatformAdminColors.textMuted, fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTile(Map<String, String> topic) {
    final id = topic['id']!;
    final isExpanded = _expandedTopicId == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: PlatformAdminColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isExpanded ? PlatformAdminColors.gold : PlatformAdminColors.borderDark,
            width: isExpanded ? 1.0 : 0.9,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
          key: Key(id),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (exp) {
            setState(() {
              _expandedTopicId = exp ? id : null;
            });
          },
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF14120C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x44D4AF37), width: 0.8),
            ),
            child: Icon(_getIconData(topic['icon']!), color: PlatformAdminColors.gold, size: 18),
          ),
          title: Text(
            topic['title']!,
            style: const TextStyle(
              color: PlatformAdminColors.textWhite,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            topic['description']!,
            style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12),
            maxLines: isExpanded ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Icon(
            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            color: PlatformAdminColors.gold,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(68, 0, 20, 16),
              child: Text(
                topic['details']!,
                style: const TextStyle(
                  color: PlatformAdminColors.textMuted,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildFaqTile(Map<String, String> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: PlatformAdminColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: PlatformAdminColors.borderDark, width: 0.9),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: ThemeData(dividerColor: Colors.transparent),
          child: ExpansionTile(
          title: Text(
            faq['q']!,
            style: const TextStyle(
              color: PlatformAdminColors.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.add, color: PlatformAdminColors.gold, size: 18),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                faq['a']!,
                style: const TextStyle(
                  color: PlatformAdminColors.textMuted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSupportDeskCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlatformAdminColors.borderDark, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x288F1025),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: PlatformAdminColors.burgundyAccent, width: 0.8),
            ),
            child: const Icon(Icons.contact_support_outlined, color: Color(0xFFFCA5A5), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Support Desk Information',
                  style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'Support contact is not configured externally. All platform administration escalations are handled internally via operations governance.',
                  style: TextStyle(color: PlatformAdminColors.textDim, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
