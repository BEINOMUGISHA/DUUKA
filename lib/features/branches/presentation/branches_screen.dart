import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key});

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- DIALOG: ADD NEW BRANCH ---
  void _showAddBranchDialog() {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final mgrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
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
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                  const Text('Add Branch Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Branch Name (e.g. Jinja Outlet) *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Physical Location / Address *'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: mgrCtrl,
                      decoration: const InputDecoration(labelText: 'Branch Manager *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Manager Phone *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final now = DateTime.now().millisecondsSinceEpoch;
                    final branch = LocalBranchData(
                      id: 'br_${now}',
                      businessId: 'biz_default',
                      name: nameCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      managerName: mgrCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      isHeadquarters: false,
                      createdAt: now,
                    );
                    await ref.read(branchesProvider.notifier).addBranch(branch);
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Branch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOG: TRANSFER STOCK BETWEEN BRANCHES ---
  void _showStockTransferDialog() {
    final branches = ref.read(branchesProvider);
    final products = ref.read(productsProvider);
    final qtyCtrl = TextEditingController(text: '5');
    final notesCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (branches.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 branches to transfer stock')),
      );
      return;
    }
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available to transfer')),
      );
      return;
    }

    String fromBranchId = branches.first.id;
    String toBranchId = branches[1].id;
    String selectedProductId = products.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final prod = products.firstWhere((p) => p.id == selectedProductId, orElse: () => products.first);
          final fromBranch = branches.firstWhere((b) => b.id == fromBranchId, orElse: () => branches.first);
          final toBranch = branches.firstWhere((b) => b.id == toBranchId, orElse: () => branches[1]);

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                      const Text('Inter-Branch Stock Transfer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: fromBranchId,
                          decoration: const InputDecoration(labelText: 'From Branch'),
                          items: branches
                              .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => fromBranchId = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryForest),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: toBranchId,
                          decoration: const InputDecoration(labelText: 'To Branch'),
                          items: branches
                              .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => toBranchId = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Product to Transfer'),
                    items: products
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.name} (Avail: ${p.currentStock.toInt()} ${p.unit})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedProductId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Transfer Quantity *',
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(labelText: 'Waybill / Driver Notes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryForest,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text('Dispatch Stock Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final qty = double.tryParse(qtyCtrl.text) ?? 0;
                        if (qty <= 0) return;
                        if (fromBranchId == toBranchId) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Origin and destination branches must be different')),
                          );
                          return;
                        }

                        await ref.read(stockTransfersProvider.notifier).transferStock(
                              fromBranchId: fromBranchId,
                              fromBranchName: fromBranch.name,
                              toBranchId: toBranchId,
                              toBranchName: toBranch.name,
                              productId: selectedProductId,
                              productName: prod.name,
                              quantity: qty,
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            );

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Transferred ${qty.toInt()} units of ${prod.name} to ${toBranch.name}')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branches = ref.watch(branchesProvider);
    final transfers = ref.watch(stockTransfersProvider);
    final sales = ref.watch(salesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Multi-Branch Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.emeraldNeon : AppColors.primaryForest,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          indicatorColor: isDark ? AppColors.emeraldNeon : AppColors.primaryForest,
          tabs: [
            Tab(text: 'Locations (${branches.length})'),
            Tab(text: 'Stock Transfers (${transfers.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Add Branch',
            onPressed: _showAddBranchDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddBranchDialog();
          } else {
            _showStockTransferDialog();
          }
        },
        backgroundColor: AppColors.primaryForest,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Branch' : 'Transfer Stock',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: BRANCH LOCATIONS ---
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...branches.map((b) {
                // Calculate sales for this branch
                final branchSales = sales.where((s) => !s.isVoided && s.branchId == b.id).fold<double>(0, (sum, s) => sum + s.totalAmount);
                final isSelected = ref.watch(selectedBranchIdProvider) == b.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isSelected ? const BorderSide(color: AppColors.primaryForest, width: 2) : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: b.isHeadquarters ? const Color(0xFFDCFCE7) : const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    b.isHeadquarters ? Icons.domain_rounded : Icons.store_rounded,
                                    color: b.isHeadquarters ? AppColors.primaryForest : const Color(0xFF0284C7),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(b.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                        if (b.isHeadquarters) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentGold,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('HQ', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(b.location, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryForest.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Active', style: TextStyle(color: AppColors.primaryForest, fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Manager', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(b.managerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(PhoneFormatter.formatDisplay(b.phone), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total Branch Sales', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                Text(
                                  CurrencyFormatter.format(branchSales),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryForest, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          // --- TAB 2: STOCK TRANSFERS ---
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (transfers.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No stock transfers yet. Tap "+ Transfer Stock" below.'),
                  ),
                )
              else
                ...transfers.map((t) {
                  final date = DateTime.fromMillisecondsSinceEpoch(t.transferDate);
                  final dateStr = '${date.day}/${date.month}/${date.year}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F2FE),
                        child: Icon(Icons.sync_alt_rounded, color: Color(0xFF0284C7)),
                      ),
                      title: Text(
                        '${t.quantity.toInt()}x ${t.productName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        '${t.fromBranchName} ➔ ${t.toBranchName}\n$dateStr · Status: ${t.status.toUpperCase()}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Dispatched',
                          style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}
