import 'package:flutter/material.dart';
import '../../shared/widgets/admin/admin_sidebar.dart';
import '../../shared/widgets/admin/admin_top_bar.dart';
import '../../shared/widgets/admin/theatre_switcher.dart';
import '../../shared/platform/image_upload_stub.dart'
    if (dart.library.html) '../../shared/platform/image_upload_web.dart';
import '../models/theatre_configuration.dart';
import '../models/theatre_snack.dart';
import '../services/selected_theatre.dart';
import '../services/theatre_repository.dart';
import '../services/snack_repository.dart';
import 'admin_dashboard_screen.dart';
import 'theatre_list_screen.dart';
import 'theatre_screens_screen.dart';
import 'theatre_shows_screen.dart';
import 'theatre_bookings_screen.dart';
import 'theatre_analytics_screen.dart';

/// Redesigned 'Snacks & Concessions' Screen for Theatre Admin.
/// Implements the master dark cinematic design language (Black, Gold & Burgundy).
class TheatreSnacksScreen extends StatefulWidget {
  const TheatreSnacksScreen({super.key});

  @override
  State<TheatreSnacksScreen> createState() => _TheatreSnacksScreenState();
}

class _TheatreSnacksScreenState extends State<TheatreSnacksScreen> {
  List<TheatreConfiguration> _theatres = [];
  TheatreConfiguration? _theatre;
  List<TheatreSnack> _snacks = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Popcorn',
    'Combos',
    'Snacks',
    'Beverages',
    'Desserts',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final theatres = await theatreRepository.getMyTheatres();
      final currentTheatre = selectedTheatreContext.resolve(theatres);

      List<TheatreSnack> snacks = [];
      if (currentTheatre != null) {
        snacks = await snackRepository.getSnacksForTheatre(currentTheatre.id);
      }

      if (mounted) {
        setState(() {
          _theatres = theatres;
          _theatre = currentTheatre;
          _snacks = snacks;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTheatreSwitched(TheatreConfiguration theatre) {
    selectedTheatreContext.select(theatre.id);
    _loadData();
  }

  void _navigateTo(String key) {
    if (key == 'dashboard') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (key == 'my_theatre') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreListScreen()),
      );
    } else if (key == 'screens') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreScreensScreen()),
      );
    } else if (key == 'shows') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreShowsScreen()),
      );
    } else if (key == 'snacks') {
      // already here
    } else if (key == 'bookings') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreBookingsScreen()),
      );
    } else if (key == 'analytics') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TheatreAnalyticsScreen()),
      );
    }
  }

  List<TheatreSnack> get _filteredSnacks {
    if (_selectedCategory == 'All') return _snacks;
    return _snacks.where((s) => s.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
  }

  Future<void> _toggleAvailability(TheatreSnack snack, bool isAvailable) async {
    try {
      await snackRepository.toggleAvailability(snack.id, snack.theatreId, isAvailable);
      setState(() {
        final index = _snacks.indexWhere((s) => s.id == snack.id);
        if (index != -1) {
          _snacks[index] = _snacks[index].copyWith(isAvailable: isAvailable);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update availability: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteSnack(TheatreSnack snack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111116),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEF4444)),
        ),
        title: const Text('Delete Concession Item?', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to remove "${snack.name}" from ${_theatre?.basicInfo.name ?? "this theatre"}?',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await snackRepository.deleteSnack(snack.id, snack.theatreId);
        setState(() {
          _snacks.removeWhere((s) => s.id == snack.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${snack.name}"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete snack: $e')),
          );
        }
      }
    }
  }

  Future<void> _openSnackDialog([TheatreSnack? existing]) async {
    if (_theatre == null) return;

    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final priceController = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    final imageController = TextEditingController(text: existing?.imageUrl ?? '');
    String category = existing?.category ?? 'Popcorn';
    bool isAvailable = existing?.isAvailable ?? true;
    bool isUploading = false;
    String? uploadError;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111116),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0x66D4AF37)),
              ),
              title: Text(
                existing == null ? 'Add Concession Item' : 'Edit Concession Item',
                style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theatre: ${_theatre!.basicInfo.name}',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      const Text('Item Name *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Color(0xFFF7F5F0)),
                        decoration: InputDecoration(
                          hintText: 'e.g. Jumbo Caramel Popcorn',
                          hintStyle: const TextStyle(color: Color(0xFF71717A)),
                          filled: true,
                          fillColor: const Color(0xFF1A1A22),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Category & Price
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Category', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A22),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF2E2E38)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: category,
                                      dropdownColor: const Color(0xFF14141A),
                                      style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'Popcorn', child: Text('Popcorn')),
                                        DropdownMenuItem(value: 'Combos', child: Text('Combos')),
                                        DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                                        DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                                        DropdownMenuItem(value: 'Desserts', child: Text('Desserts')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setDialogState(() => category = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Price (₹) *', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Color(0xFFF7F5F0)),
                                  decoration: InputDecoration(
                                    prefixText: '₹ ',
                                    prefixStyle: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w700),
                                    filled: true,
                                    fillColor: const Color(0xFF1A1A22),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description
                      const Text('Description', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        style: const TextStyle(color: Color(0xFFF7F5F0)),
                        decoration: InputDecoration(
                          hintText: 'Flavor details, serving size, etc.',
                          hintStyle: const TextStyle(color: Color(0xFF71717A)),
                          filled: true,
                          fillColor: const Color(0xFF1A1A22),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Image Upload / URL
                      const Text('Item Image', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: imageController,
                              style: const TextStyle(color: Color(0xFFF7F5F0), fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Image URL or upload below',
                                hintStyle: const TextStyle(color: Color(0xFF71717A)),
                                filled: true,
                                fillColor: const Color(0xFF1A1A22),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2E2E38))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isUploading = true;
                                      uploadError = null;
                                    });
                                    final res = await pickAndUploadSnackImage(theatreId: _theatre!.id);
                                    setDialogState(() {
                                      isUploading = false;
                                      if (res != null && res.isSuccess) {
                                        imageController.text = res.storageUrl!;
                                      } else if (res?.errorMessage != null) {
                                        uploadError = res!.errorMessage;
                                      }
                                    });
                                  },
                            icon: isUploading
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Icon(Icons.cloud_upload_outlined, size: 16),
                            label: Text(isUploading ? 'Uploading...' : 'Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      if (uploadError != null) ...[
                        const SizedBox(height: 4),
                        Text(uploadError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11)),
                      ],
                      const SizedBox(height: 14),

                      // Availability toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available for Customers', style: TextStyle(color: Color(0xFFF7F5F0), fontSize: 13.5)),
                        subtitle: const Text('Turn off if temporarily out of stock', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        value: isAvailable,
                        activeThumbColor: const Color(0xFFD4AF37),
                        onChanged: (val) => setDialogState(() => isAvailable = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an item name')),
                      );
                      return;
                    }
                    if (price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid price')),
                      );
                      return;
                    }

                    final snackItem = TheatreSnack(
                      id: existing?.id ?? '',
                      theatreId: _theatre!.id,
                      name: name,
                      category: category,
                      price: price,
                      description: descController.text.trim(),
                      imageUrl: imageController.text.trim().isNotEmpty ? imageController.text.trim() : null,
                      isAvailable: isAvailable,
                    );

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(dialogCtx);

                    try {
                      if (existing == null) {
                        final created = await snackRepository.createSnack(snackItem);
                        if (mounted) setState(() => _snacks.add(created));
                      } else {
                        await snackRepository.updateSnack(snackItem);
                        if (mounted) {
                          setState(() {
                            final idx = _snacks.indexWhere((s) => s.id == existing.id);
                            if (idx != -1) _snacks[idx] = snackItem;
                          });
                        }
                      }
                      navigator.pop();
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to save snack: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                  child: Text(
                    existing == null ? 'Add Item' : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    const navItems = [
      AdminNavItemData(key: 'dashboard', label: 'Dashboard', icon: Icons.dashboard_rounded),
      AdminNavItemData(key: 'my_theatre', label: 'My Theatre', icon: Icons.theaters_outlined),
      AdminNavItemData(key: 'screens', label: 'Screens', icon: Icons.tv_rounded),
      AdminNavItemData(key: 'shows', label: 'Shows', icon: Icons.calendar_today_outlined),
      AdminNavItemData(key: 'bookings', label: 'Bookings', icon: Icons.confirmation_number_outlined),
      AdminNavItemData(key: 'analytics', label: 'Analytics', icon: Icons.bar_chart_rounded),
    ];

    final sidebar = AdminSidebar(
      activeKey: 'snacks',
      mainNavItems: navItems,
      onSelectKey: _navigateTo,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      drawer: isDesktop ? null : Drawer(backgroundColor: const Color(0xFF070709), child: sidebar),
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  searchPlaceholder: 'Search snacks, beverages, combos...',
                  showDrawerButton: !isDesktop,
                  onProfileTap: () => _navigateTo('my_theatre'),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                      : _theatre == null
                          ? const Center(
                              child: Text('No active theatre found. Please create or claim a theatre.',
                                  style: TextStyle(color: Color(0xFF9CA3AF))),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Snacks & Concessions',
                                              style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFFFFFFF),
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Configure and price food & beverages for ${_theatre!.basicInfo.name}',
                                              style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_theatres.isNotEmpty)
                                            TheatreSwitcher(
                                              theatres: _theatres,
                                              selectedId: _theatre?.id,
                                              onChanged: _onTheatreSwitched,
                                            ),
                                          const SizedBox(width: 14),
                                          ElevatedButton.icon(
                                            onPressed: () => _openSnackDialog(),
                                            icon: const Icon(Icons.add_rounded, size: 18),
                                            label: const Text('Add Concession', style: TextStyle(fontWeight: FontWeight.w700)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFD4AF37),
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Category Filter Bar
                                  SizedBox(
                                    height: 38,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _categories.length,
                                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                                      itemBuilder: (context, index) {
                                        final cat = _categories[index];
                                        final isSelected = cat == _selectedCategory;
                                        return FilterChip(
                                          label: Text(cat),
                                          selected: isSelected,
                                          onSelected: (_) => setState(() => _selectedCategory = cat),
                                          backgroundColor: const Color(0xFF14141A),
                                          selectedColor: const Color(0xFF6E071A),
                                          labelStyle: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFFEDEAE2),
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            fontSize: 12.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(19),
                                            side: BorderSide(
                                              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF22222A),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Snack Cards Grid
                                  if (_filteredSnacks.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F0F12),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFF1E1E26)),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(Icons.fastfood_outlined, size: 48, color: Color(0xFFD4AF37)),
                                          const SizedBox(height: 16),
                                          Text(
                                            _selectedCategory == 'All'
                                                ? 'No snacks configured for ${_theatre!.basicInfo.name} yet.'
                                                : 'No items in "$_selectedCategory" category.',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFFFF)),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Add items to your menu to offer concessions to customers during ticket booking.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                          ),
                                          const SizedBox(height: 20),
                                          OutlinedButton.icon(
                                            onPressed: () => _openSnackDialog(),
                                            icon: const Icon(Icons.add, size: 16),
                                            label: const Text('Add First Snack'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFFD4AF37),
                                              side: const BorderSide(color: Color(0xFFD4AF37)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final crossAxisCount = (constraints.maxWidth / 320).floor().clamp(1, 4);
                                        return GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: _filteredSnacks.length,
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: 16,
                                            crossAxisSpacing: 16,
                                            childAspectRatio: 1.35,
                                          ),
                                          itemBuilder: (context, index) {
                                            final snack = _filteredSnacks[index];
                                            return _buildSnackCard(snack);
                                          },
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnackCard(TheatreSnack snack) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: snack.isAvailable ? const Color(0xFF1E1E26) : const Color(0x661E1E26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail / Icon Squircle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C180E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x44D4AF37)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: snack.imageUrl != null && snack.imageUrl!.trim().isNotEmpty
                      ? Image.network(
                          snack.imageUrl!.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(snack.categoryIcon, color: const Color(0xFFD4AF37), size: 26),
                        )
                      : Icon(snack.categoryIcon, color: const Color(0xFFD4AF37), size: 26),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snack.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: snack.isAvailable ? const Color(0xFFFFFFFF) : const Color(0xFF71717A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C180E),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0x44D4AF37), width: 0.6),
                      ),
                      child: Text(
                        snack.category.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${snack.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            snack.description.isNotEmpty ? snack.description : 'No description provided.',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          const Divider(color: Color(0xFF1E1E26), height: 1),
          const SizedBox(height: 8),

          // Card Footer: Availability Switch & Actions
          Row(
            children: [
              Text(
                snack.isAvailable ? 'Available' : 'Unavailable',
                style: TextStyle(
                  color: snack.isAvailable ? const Color(0xFF10B981) : const Color(0xFF71717A),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: snack.isAvailable,
                  activeThumbColor: const Color(0xFFD4AF37),
                  activeTrackColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  onChanged: (val) => _toggleAvailability(snack, val),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
                tooltip: 'Edit',
                onPressed: () => _openSnackDialog(snack),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                tooltip: 'Delete',
                onPressed: () => _confirmDeleteSnack(snack),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
