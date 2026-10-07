import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/platform_admin_theme.dart';
import '../widgets/review_widgets.dart';

class _UserProfileItem {
  final String id;
  final String displayName;
  final String email;
  final String role;
  final String verificationStatus;
  final DateTime createdAt;

  _UserProfileItem({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.verificationStatus,
    required this.createdAt,
  });

  factory _UserProfileItem.fromRow(Map<String, dynamic> row) {
    return _UserProfileItem(
      id: row['id'] as String? ?? '',
      displayName: (row['display_name'] as String?)?.trim().isNotEmpty == true
          ? (row['display_name'] as String).trim()
          : 'LiveScreen User',
      email: row['email'] as String? ?? 'No email on record',
      role: row['role'] as String? ?? 'customer',
      verificationStatus: row['verification_status'] as String? ?? 'verified',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Platform-wide User Management Screen for Platform Admin.
/// Lists profiles across all roles (Customers, Theatre Admins, Producers, Platform Admins) with dark styling.
class PlatformUsersScreen extends StatefulWidget {
  const PlatformUsersScreen({super.key});

  @override
  State<PlatformUsersScreen> createState() => _PlatformUsersScreenState();
}

class _PlatformUsersScreenState extends State<PlatformUsersScreen> {
  bool _loading = true;
  List<_UserProfileItem> _users = [];
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final client = _getSupabaseClient();
      if (client != null) {
        final rows = await client
            .from('profiles')
            .select()
            .order('created_at', ascending: false)
            .limit(100);

        _users = rows.map((r) => _UserProfileItem.fromRow(r)).toList();
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<_UserProfileItem> get _filteredUsers {
    return _users.where((u) {
      if (_roleFilter != 'all' && u.role.toLowerCase() != _roleFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = u.displayName.toLowerCase().contains(q);
        final matchesEmail = u.email.toLowerCase().contains(q);
        final matchesId = u.id.toLowerCase().contains(q);
        if (!matchesName && !matchesEmail && !matchesId) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showUserDetails(_UserProfileItem user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PlatformAdminColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PlatformAdminColors.borderSubtle),
        ),
        title: Row(
          children: const [
            Icon(Icons.person_outline_rounded, color: PlatformAdminColors.gold, size: 20),
            SizedBox(width: 10),
            Text('User Profile Record', style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('User Identifier', user.id),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Full Name / Display', user.displayName),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Email Address', user.email),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Role Designation', _formatRoleLabel(user.role)),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Verification Status', user.verificationStatus.toUpperCase()),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Joined Date', _formatDateTime(user.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: PlatformAdminColors.gold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12.5)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(color: PlatformAdminColors.textWhite, fontWeight: FontWeight.w600, fontSize: 12.5),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'platform_admin':
        return 'Platform Admin';
      case 'theatre_admin':
        return 'Theatre Admin';
      case 'producer':
        return 'Producer';
      case 'customer':
      default:
        return 'Customer';
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'platform_admin':
        return PlatformAdminColors.gold;
      case 'theatre_admin':
        return const Color(0xFFFCA5A5);
      case 'producer':
        return const Color(0xFFE5B869);
      case 'customer':
      default:
        return PlatformAdminColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredUsers;

    final customerCount = _users.where((u) => u.role == 'customer').length;
    final theatreCount = _users.where((u) => u.role == 'theatre_admin').length;
    final producerCount = _users.where((u) => u.role == 'producer').length;
    final adminCount = _users.where((u) => u.role == 'platform_admin').length;

    return PlatformAdminScaffold(
      activeKey: 'users',
      pageTitle: 'Platform Users',
      pageSubtitle: 'Directory of registered customer, theatre operator, producer, and administrative accounts.',
      onSearchChanged: (q) => setState(() => _searchQuery = q.trim()),
      searchPlaceholder: 'Search name, email, or user ID...',
      headerAction: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlatformAdminColors.gold,
          side: const BorderSide(color: PlatformAdminColors.gold, width: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: _loadUsers,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Role Metrics Grid
          Row(
            children: [
              Expanded(child: _buildMetricTile('Total Accounts', '${_users.length}', Icons.people_outline_rounded, true)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricTile('Customers', '$customerCount', Icons.person_outline, false)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricTile('Theatre Admins', '$theatreCount', Icons.domain_outlined, true)),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricTile('Producers', '$producerCount', Icons.groups_outlined, false)),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Filter Pills
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'All Roles'),
                const SizedBox(width: 8),
                _buildFilterChip('customer', 'Customers ($customerCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('theatre_admin', 'Theatre Admins ($theatreCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('producer', 'Producers ($producerCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('platform_admin', 'Platform Admins ($adminCount)'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Users Table
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PlatformAdminColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: PlatformAdminColors.borderSubtle, width: 1.0),
            ),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: PlatformAdminColors.gold),
                    ),
                  )
                : list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.people_outline_rounded, size: 40, color: PlatformAdminColors.gold),
                              SizedBox(height: 12),
                              Text('No user accounts found matching this filter.', style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text('User registrations across LiveScreen will appear in this directory.', style: TextStyle(color: PlatformAdminColors.textDim, fontSize: 12.5)),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'User Directory',
                                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${list.length} accounts shown',
                                style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, _) => const Divider(color: PlatformAdminColors.borderDark, height: 1),
                            itemBuilder: (context, index) {
                              final item = list[index];
                              final initial = item.displayName.isNotEmpty ? item.displayName[0].toUpperCase() : 'U';

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF14120C),
                                        border: Border.all(color: _roleColor(item.role), width: 1),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initial,
                                          style: TextStyle(color: _roleColor(item.role), fontSize: 15, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.displayName,
                                            style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.email,
                                            style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF101016),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: _roleColor(item.role).withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        _formatRoleLabel(item.role),
                                        style: TextStyle(color: _roleColor(item.role), fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    StatusPill(status: item.verificationStatus),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline_rounded, color: PlatformAdminColors.gold, size: 18),
                                      onPressed: () => _showUserDetails(item),
                                      tooltip: 'View User Details',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final selected = _roleFilter == key;
    return InkWell(
      onTap: () => setState(() => _roleFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x288F1025) : const Color(0xFF0D0D12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? PlatformAdminColors.burgundyAccent : PlatformAdminColors.borderDark,
            width: 0.9,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? PlatformAdminColors.textWhite : PlatformAdminColors.textMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, bool isGold) {
    final borderColor = isGold ? const Color(0xFFB8941F) : const Color(0xFF8F1025);
    final iconColor = isGold ? PlatformAdminColors.gold : const Color(0xFFD51F46);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PlatformAdminColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF14120C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: PlatformAdminColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
