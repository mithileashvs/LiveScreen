import 'package:flutter/material.dart';
import '../admin/models/theatre_configuration.dart';
import '../admin/models/theatre_snack.dart';
import '../admin/models/movie_content.dart';
import '../admin/services/snack_repository.dart';
import '../theme/customer_theme.dart';
import 'customer_payment_screen.dart';

/// Concessions and Snacks Selection Screen for LiveScreen Customers.
///
/// Features:
/// - Strictly dynamically loaded per theatre via [snackRepository.getSnacksForTheatre].
/// - Displays real theatre-isolated snacks (`theatre_id = selectedTheatre.id`).
/// - Renders concession image thumbnail if available, or category icon fallback.
/// - Clean empty state when the theatre has no snacks configured.
/// - Cart sidebar calculating Ticket Fare, Snacks Total, and Grand Total.
/// - Quick "Skip" to bypass concessions and proceed directly to payment.
class SnacksScreen extends StatefulWidget {
  final TheatreConfiguration theatre;
  final String? showId;
  final MovieContent? movie;
  final List<String> selectedSeats;
  final double ticketFare;
  final String date;
  final String time;
  final List<TheatreSnack>? initialSnacks;

  const SnacksScreen({
    super.key,
    required this.theatre,
    this.showId,
    this.movie,
    required this.selectedSeats,
    required this.ticketFare,
    required this.date,
    required this.time,
    this.initialSnacks,
  });

  @override
  State<SnacksScreen> createState() => _SnacksScreenState();
}

class _SnacksScreenState extends State<SnacksScreen> {
  List<TheatreSnack> _snacks = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSnacks != null) {
      _snacks = widget.initialSnacks!;
      _isLoading = false;
    } else {
      _loadSnacks();
    }
  }

  Future<void> _loadSnacks() async {
    try {
      final items = await snackRepository.getSnacksForTheatre(
        widget.theatre.id,
        onlyAvailable: true,
      );
      if (mounted) {
        setState(() {
          _snacks = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _snacks = [];
          _isLoading = false;
        });
      }
    }
  }

  List<String> get _categories {
    final catSet = <String>{'All'};
    for (final s in _snacks) {
      if (s.category.isNotEmpty) catSet.add(s.category);
    }
    return catSet.toList();
  }

  List<TheatreSnack> get _filteredSnacks {
    return _snacks.where((item) {
      if (_selectedCategory != 'All' &&
          item.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return item.name.toLowerCase().contains(q) ||
            item.description.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  void _addSnack(String id) {
    setState(() {
      _cart[id] = (_cart[id] ?? 0) + 1;
    });
  }

  void _removeSnack(String id) {
    setState(() {
      final current = _cart[id] ?? 0;
      if (current <= 1) {
        _cart.remove(id);
      } else {
        _cart[id] = current - 1;
      }
    });
  }

  void _clearSnack(String id) {
    setState(() => _cart.remove(id));
  }

  double get _snackTotal {
    double total = 0;
    for (final entry in _cart.entries) {
      final item = _snacks.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => TheatreSnack(id: entry.key, theatreId: widget.theatre.id, name: '', price: 0),
      );
      total += item.price * entry.value;
    }
    return total;
  }

  int get _snackCount {
    int count = 0;
    for (final v in _cart.values) {
      count += v;
    }
    return count;
  }

  void _proceedToPayment() {
    final selectedSnacksList = <Map<String, dynamic>>[];
    for (final entry in _cart.entries) {
      final item = _snacks.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => TheatreSnack(id: entry.key, theatreId: widget.theatre.id, name: '', price: 0),
      );
      selectedSnacksList.add({
        'name': item.name,
        'quantity': entry.value,
        'unitPrice': item.price,
        'totalPrice': item.price * entry.value,
      });
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerPaymentScreen(
          theatre: widget.theatre,
          showId: widget.showId,
          movie: widget.movie,
          selectedSeats: widget.selectedSeats,
          ticketFare: widget.ticketFare,
          selectedSnacks: selectedSnacksList,
          snackTotal: _snackTotal,
          date: widget.date,
          time: widget.time,
        ),
      ),
    );
  }

  void _skip() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerPaymentScreen(
          theatre: widget.theatre,
          showId: widget.showId,
          movie: widget.movie,
          selectedSeats: widget.selectedSeats,
          ticketFare: widget.ticketFare,
          selectedSnacks: const [],
          snackTotal: 0,
          date: widget.date,
          time: widget.time,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movieTitle = widget.movie?.title.isNotEmpty == true ? widget.movie!.title : 'Cinema Feature';
    final theatreName = widget.theatre.basicInfo.name;

    return Scaffold(
      backgroundColor: CustomerColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movieTitle,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: CustomerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$theatreName | ${widget.date} | ${widget.time}',
              style: const TextStyle(
                fontSize: 11.5,
                color: CustomerColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextButton(
              onPressed: _skip,
              style: TextButton.styleFrom(
                backgroundColor: CustomerColors.gold,
                foregroundColor: CustomerColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Skip'),
            ),
          ),
        ],
        backgroundColor: CustomerColors.surface,
        foregroundColor: CustomerColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: CustomerColors.borderSubtle, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CustomerColors.gold))
          : _snacks.isEmpty
              ? _buildEmptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 960;

                    final snacksPane = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Heading: "Grab a Bite!"
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Grab a ',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: CustomerColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Bite!',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: CustomerColors.gold,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Concessions available at ${widget.theatre.basicInfo.name}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: CustomerColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Search Field
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: CustomerColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CustomerColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 18, color: CustomerColors.textMuted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  onChanged: (q) => setState(() => _searchQuery = q.trim()),
                                  style: const TextStyle(fontSize: 13, color: CustomerColors.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'Search for snacks, combos, beverages...',
                                    hintStyle: TextStyle(fontSize: 13, color: CustomerColors.textMuted),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Category Pills
                        if (_categories.length > 1)
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _categories.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                final isSelected = cat == _selectedCategory;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedCategory = cat),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? CustomerColors.burgundy : CustomerColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? CustomerColors.gold : CustomerColors.borderGoldSubtle,
                                        width: isSelected ? 1.2 : 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected ? CustomerColors.textPrimary : CustomerColors.textSecondary,
                                        fontSize: 12.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Concession Cards Grid
                        LayoutBuilder(
                          builder: (context, c) {
                            const minWidth = 270.0;
                            final crossAxisCount = (c.maxWidth / (minWidth + 14)).floor().clamp(1, 3);
                            final cardWidth = (c.maxWidth - (crossAxisCount - 1) * 14) / crossAxisCount;

                            return Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                for (final snack in _filteredSnacks)
                                  _buildSnackCard(snack, cardWidth),
                              ],
                            );
                          },
                        ),
                      ],
                    );

                    final cartPane = _buildCartPane();

                    if (isDesktop) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 65, child: snacksPane),
                            const SizedBox(width: 24),
                            SizedBox(width: 380, child: cartPane),
                          ],
                        ),
                      );
                    } else {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            snacksPane,
                            const SizedBox(height: 32),
                            cartPane,
                          ],
                        ),
                      );
                    }
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: CustomerColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CustomerColors.borderSubtle),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CustomerColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: CustomerColors.borderGold),
              ),
              child: const Icon(
                Icons.fastfood_outlined,
                size: 32,
                color: CustomerColors.gold,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Snacks Available at This Theatre',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CustomerColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.theatre.basicInfo.name} has not configured online snacks yet.\nYou can proceed directly to ticket payment.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CustomerColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _skip,
              icon: const Text('Proceed to Payment'),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomerColors.gold,
                foregroundColor: CustomerColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnackCard(TheatreSnack snack, double width) {
    final qty = _cart[snack.id] ?? 0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomerColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Concession Image / Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: CustomerColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: CustomerColors.borderSubtle),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: snack.imageUrl != null && snack.imageUrl!.trim().isNotEmpty
                  ? Image.network(
                      snack.imageUrl!.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(snack.categoryIcon, color: CustomerColors.gold, size: 28),
                      ),
                    )
                  : Center(
                      child: Icon(snack.categoryIcon, color: CustomerColors.gold, size: 28),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Details + Add button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  snack.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: CustomerColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  snack.description.isNotEmpty ? snack.description : snack.category,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CustomerColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${snack.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.gold,
                      ),
                    ),
                    if (qty == 0)
                      ElevatedButton.icon(
                        onPressed: () => _addSnack(snack.id),
                        icon: const Icon(Icons.add, size: 13),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: CustomerColors.burgundy,
                          side: const BorderSide(color: CustomerColors.gold, width: 0.9),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: const Size(54, 26),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: CustomerColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: CustomerColors.gold, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 13, color: CustomerColors.textPrimary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              onPressed: () => _removeSnack(snack.id),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                color: CustomerColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 13, color: CustomerColors.textPrimary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                              onPressed: () => _addSnack(snack.id),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPane() {
    final totalAmount = widget.ticketFare + _snackTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CustomerColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerColors.borderGold, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Cart',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: CustomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          // Ticket Fare Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Ticket(s) Fare (${widget.selectedSeats.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CustomerColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${widget.ticketFare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CustomerColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Selected Seats Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final seat in widget.selectedSeats)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CustomerColors.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CustomerColors.borderSubtle),
                  ),
                  child: Text(
                    seat,
                    style: const TextStyle(
                      color: CustomerColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: CustomerColors.borderSubtle, height: 1),
          ),

          // Snacks List in Cart
          Text(
            'Snacks ($_snackCount)',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CustomerColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          if (_cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No snacks selected yet',
                style: TextStyle(
                  color: CustomerColors.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else ...[
            for (final entry in _cart.entries) ...[
              Builder(
                builder: (context) {
                  final item = _snacks.firstWhere(
                    (s) => s.id == entry.key,
                    orElse: () => TheatreSnack(id: entry.key, theatreId: widget.theatre.id, name: '', price: 0),
                  );
                  final qty = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: CustomerColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₹${item.price.toInt()} × $qty',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: CustomerColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Qty controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 12, color: CustomerColors.textPrimary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              onPressed: () => _removeSnack(item.id),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                color: CustomerColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 12, color: CustomerColors.textPrimary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              onPressed: () => _addSnack(item.id),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: CustomerColors.textMuted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                              onPressed: () => _clearSnack(item.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: CustomerColors.borderSubtle, height: 1),
          ),

          // Total Breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text('Tickets Fare', style: TextStyle(color: CustomerColors.textSecondary, fontSize: 12.5))),
              const SizedBox(width: 8),
              Text('₹${widget.ticketFare.toStringAsFixed(2)}', style: const TextStyle(color: CustomerColors.textPrimary, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(child: Text('Snacks Total', style: TextStyle(color: CustomerColors.textSecondary, fontSize: 12.5))),
              const SizedBox(width: 8),
              Text('₹${_snackTotal.toStringAsFixed(2)}', style: const TextStyle(color: CustomerColors.textPrimary, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CustomerColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '₹${totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CustomerColors.gold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Proceed to Payment Button (Reference Image 4)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: CustomerColors.gold,
                foregroundColor: CustomerColors.background,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Proceed to Payment'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
