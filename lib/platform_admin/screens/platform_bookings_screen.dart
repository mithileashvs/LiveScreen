import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/models/booking_model.dart';
import '../theme/platform_admin_theme.dart';
import '../widgets/review_widgets.dart';

/// Platform-wide Bookings Overview Screen for Platform Admin.
/// Lists customer bookings across all cinema theatres with search, status filters, and booking detail inspection.
class PlatformBookingsScreen extends StatefulWidget {
  const PlatformBookingsScreen({super.key});

  @override
  State<PlatformBookingsScreen> createState() => _PlatformBookingsScreenState();
}

class _PlatformBookingsScreenState extends State<PlatformBookingsScreen> {
  bool _loading = true;
  List<BookingModel> _bookings = [];
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  SupabaseClient? _getSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      final client = _getSupabaseClient();
      if (client != null) {
        PostgrestFilterBuilder<PostgrestList> query = client
            .from('bookings')
            .select();

        final rows = await query.order('created_at', ascending: false).limit(100);
        _bookings = rows.map((r) => BookingModel.fromRow(r)).toList();
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  List<BookingModel> get _filteredBookings {
    return _bookings.where((b) {
      if (_statusFilter != 'all' && b.status.toLowerCase() != _statusFilter.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = b.id.toLowerCase().contains(q);
        final matchesTheatre = b.theatreId.toLowerCase().contains(q);
        final matchesSeat = b.seatId.toLowerCase().contains(q);
        final matchesUser = b.userId.toLowerCase().contains(q);
        if (!matchesId && !matchesTheatre && !matchesSeat && !matchesUser) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showBookingDetails(BookingModel booking) {
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
            Icon(Icons.confirmation_number_outlined, color: PlatformAdminColors.gold, size: 20),
            SizedBox(width: 10),
            Text('Booking Record', style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Booking ID', booking.id),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Customer User ID', booking.userId),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Theatre ID', booking.theatreId),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Show ID', booking.showId ?? 'General Admission'),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Reserved Seat', booking.seatId),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Status', booking.status.toUpperCase()),
            const Divider(color: PlatformAdminColors.borderDark, height: 18),
            _buildDetailRow('Timestamp', _formatDateTime(booking.createdAt)),
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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredBookings;

    return PlatformAdminScaffold(
      activeKey: 'bookings',
      pageTitle: 'Platform Bookings',
      pageSubtitle: 'Real-time transaction ledger across all LiveScreen cinema venues and showtimes.',
      onSearchChanged: (q) => setState(() => _searchQuery = q.trim()),
      searchPlaceholder: 'Search booking ID, customer ID, or seat...',
      headerAction: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: PlatformAdminColors.gold,
          side: const BorderSide(color: PlatformAdminColors.gold, width: 0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: _loadBookings,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KPI Metric Bar
          Row(
            children: [
              Expanded(child: _buildMetricTile('Total Bookings', '${_bookings.length}', Icons.confirmation_number_outlined, true)),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  'Confirmed',
                  '${_bookings.where((b) => b.status.toLowerCase() == 'confirmed').length}',
                  Icons.check_circle_outline,
                  false,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricTile(
                  'Reserved Seats',
                  '${_bookings.map((b) => b.seatId).toSet().length}',
                  Icons.event_seat_outlined,
                  true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Filter Pills
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'All Bookings'),
                const SizedBox(width: 8),
                _buildFilterChip('confirmed', 'Confirmed'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('cancelled', 'Cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Bookings Table Container
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
                              Icon(Icons.confirmation_number_outlined, size: 40, color: PlatformAdminColors.gold),
                              SizedBox(height: 12),
                              Text('No bookings match your current criteria.', style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 15, fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text('Transactions booked by customers will automatically register here.', style: TextStyle(color: PlatformAdminColors.textDim, fontSize: 12.5)),
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
                                'Bookings Ledger',
                                style: TextStyle(color: PlatformAdminColors.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${list.length} records shown',
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
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF14120C),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0x33D4AF37), width: 0.8),
                                      ),
                                      child: const Icon(Icons.confirmation_number_outlined, size: 16, color: PlatformAdminColors.gold),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.id,
                                            style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 13.5, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'User: ${item.userId.length > 12 ? '${item.userId.substring(0, 12)}...' : item.userId}',
                                            style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Seat ${item.seatId}', style: const TextStyle(color: PlatformAdminColors.textWhite, fontSize: 13, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text(_formatDateTime(item.createdAt), style: const TextStyle(color: PlatformAdminColors.textDim, fontSize: 11.5)),
                                        ],
                                      ),
                                    ),
                                    StatusPill(status: item.status),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline_rounded, color: PlatformAdminColors.gold, size: 18),
                                      onPressed: () => _showBookingDetails(item),
                                      tooltip: 'Inspect Booking Record',
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
    final selected = _statusFilter == key;
    return InkWell(
      onTap: () => setState(() => _statusFilter = key),
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
