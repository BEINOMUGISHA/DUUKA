import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/currency_formatter.dart';

// ─── Supplier Data Model ─────────────────────────────────────────────────────
class SupplierData {
  final String id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? address;
  final String? tin;
  final double totalPurchased;
  final double outstandingPayable;
  final bool isActive;
  final String? notes;

  const SupplierData({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.address,
    this.tin,
    required this.totalPurchased,
    required this.outstandingPayable,
    required this.isActive,
    this.notes,
  });

  factory SupplierData.fromJson(Map<String, dynamic> j) => SupplierData(
        id: j['_id'] as String,
        name: j['name'] as String,
        contactName: j['contactName'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        address: j['address'] as String?,
        tin: j['tin'] as String?,
        totalPurchased: ((j['totalPurchased'] as num?) ?? 0).toDouble(),
        outstandingPayable: ((j['outstandingPayable'] as num?) ?? 0).toDouble(),
        isActive: j['isActive'] as bool? ?? true,
        notes: j['notes'] as String?,
      );
}

// ─── Suppliers Screen ────────────────────────────────────────────────────────
class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  bool _loading = false;
  List<SupplierData> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSuppliers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    final session = ref.read(authProvider);
    if (session == null) return;
    setState(() => _loading = true);
    try {
      final convex = ref.read(convexClientProvider);
      final result = await convex.query('suppliers:listSuppliers', {
        'businessId': session.businessId,
        'userId': session.userId,
        'includeInactive': false,
      });
      if (result != null && result is List) {
        setState(() {
          _suppliers = result
              .map((e) => SupplierData.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suppliers: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddEditSupplier([SupplierData? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final contactCtrl = TextEditingController(text: existing?.contactName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final tinCtrl = TextEditingController(text: existing?.tin ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    existing == null ? 'Add Supplier' : 'Edit Supplier',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Business / Supplier Name *',
                  prefixIcon: Icon(Icons.store_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: contactCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Person'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: tinCtrl,
                      decoration: const InputDecoration(labelText: 'TIN (URA)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Physical Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes / Terms'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    existing == null ? 'Save Supplier' : 'Update Supplier',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Supplier name is required')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final session = ref.read(authProvider);
                    if (session == null) return;
                    try {
                      final convex = ref.read(convexClientProvider);
                      await convex.mutation('suppliers:upsertSupplier', {
                        'businessId': session.businessId,
                        'userId': session.userId,
                        if (existing != null) 'supplierId': existing.id,
                        'name': name,
                        if (contactCtrl.text.isNotEmpty) 'contactName': contactCtrl.text.trim(),
                        if (phoneCtrl.text.isNotEmpty) 'phone': phoneCtrl.text.trim(),
                        if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text.trim(),
                        if (addressCtrl.text.isNotEmpty) 'address': addressCtrl.text.trim(),
                        if (tinCtrl.text.isNotEmpty) 'tin': tinCtrl.text.trim(),
                        if (notesCtrl.text.isNotEmpty) 'notes': notesCtrl.text.trim(),
                      });
                      _loadSuppliers();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Supplier ${existing == null ? 'added' : 'updated'} successfully')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePO(SupplierData supplier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Create Purchase Order for ${supplier.name} — select products from inventory'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSupplierCard(SupplierData supplier) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasAP = supplier.outstandingPayable > 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasAP
              ? AppColors.warning.withAlpha(180)
              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: hasAP ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withAlpha(30),
          child: Text(
            supplier.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          supplier.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.phone != null)
              Text(supplier.phone!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                _statChip(
                  'Purchased: ${CurrencyFormatter.format(supplier.totalPurchased)}',
                  AppColors.success,
                ),
                if (hasAP) ...[
                  const SizedBox(width: 6),
                  _statChip(
                    'Payable: ${CurrencyFormatter.format(supplier.outstandingPayable)}',
                    AppColors.warning,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            if (val == 'edit') _showAddEditSupplier(supplier);
            if (val == 'po') _showCreatePO(supplier);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'po', child: Text('📦 Create Purchase Order')),
            const PopupMenuItem(value: 'edit', child: Text('✏️ Edit Supplier')),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 0.5),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _suppliers.where((s) {
      final q = _search.toLowerCase();
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          (s.phone?.contains(q) ?? false) ||
          (s.contactName?.toLowerCase().contains(q) ?? false);
    }).toList();

    // AP summary
    final totalPayable = _suppliers.fold<double>(0, (s, e) => s + e.outstandingPayable);
    final totalPurchased = _suppliers.fold<double>(0, (s, e) => s + e.totalPurchased);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Suppliers & Purchases', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSuppliers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            onPressed: () => _showAddEditSupplier(),
            tooltip: 'Add Supplier',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Suppliers'),
            Tab(text: 'Purchase Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Suppliers ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: _loadSuppliers,
            child: CustomScrollView(
              slivers: [
                // Summary Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            'Total Purchased',
                            CurrencyFormatter.format(totalPurchased),
                            Icons.trending_up_rounded,
                            AppColors.success,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _summaryCard(
                            'Accounts Payable',
                            CurrencyFormatter.format(totalPayable),
                            Icons.account_balance_wallet_rounded,
                            totalPayable > 0 ? AppColors.warning : AppColors.success,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search suppliers…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                ),
                // List
                if (_loading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.storefront_outlined, size: 64,
                              color: isDark ? Colors.white24 : Colors.black12),
                          const SizedBox(height: 12),
                          Text(
                            _search.isEmpty
                                ? 'No suppliers yet.\nTap + to add your first supplier.'
                                : 'No suppliers match "$_search"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildSupplierCard(filtered[i]),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Tab 2: Purchase Orders ────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64,
                    color: isDark ? Colors.white24 : Colors.black12),
                const SizedBox(height: 12),
                Text(
                  'Purchase Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a supplier and tap\n"Create Purchase Order" to begin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Select Supplier First'),
                  onPressed: _suppliers.isEmpty
                      ? null
                      : () {
                          _tabController.animateTo(0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tap ⋮ on a supplier to create a PO')),
                          );
                        },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSupplier(),
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withAlpha(60),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
