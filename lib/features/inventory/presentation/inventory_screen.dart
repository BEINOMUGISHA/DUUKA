import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';

class InventoryProduct {
  final String id;
  String name;
  String category;
  double costPrice;
  double sellPrice;
  double currentStock;
  double minStockLevel;
  String unit;

  InventoryProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellPrice,
    required this.currentStock,
    required this.minStockLevel,
    required this.unit,
  });
}

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<InventoryProduct> _products = [
    InventoryProduct(id: 'p1', name: 'NPK 17:17:17 Fertilizer 50kg', category: 'Agro', costPrice: 150000, sellPrice: 185000, currentStock: 24, minStockLevel: 10, unit: 'bag'),
    InventoryProduct(id: 'p2', name: 'DAP Fertilizer 50kg', category: 'Agro', costPrice: 170000, sellPrice: 210000, currentStock: 18, minStockLevel: 10, unit: 'bag'),
    InventoryProduct(id: 'p3', name: 'Longe 5 Maize Seeds 2kg', category: 'Seeds', costPrice: 12000, sellPrice: 16000, currentStock: 4, minStockLevel: 15, unit: 'pkt'),
    InventoryProduct(id: 'p4', name: 'Bazooka Maize Seeds 2kg', category: 'Seeds', costPrice: 14000, sellPrice: 18500, currentStock: 30, minStockLevel: 10, unit: 'pkt'),
    InventoryProduct(id: 'p5', name: 'Roundup Weedkiller 1L', category: 'Chemicals', costPrice: 22000, sellPrice: 28000, currentStock: 3, minStockLevel: 10, unit: 'bottle'),
    InventoryProduct(id: 'p6', name: 'Dudu Acelamectin Pesticide 500ml', category: 'Chemicals', costPrice: 18000, sellPrice: 24000, currentStock: 15, minStockLevel: 5, unit: 'bottle'),
    InventoryProduct(id: 'p7', name: 'Tororo Cement 32.5R 50kg', category: 'Hardware', costPrice: 32000, sellPrice: 36000, currentStock: 80, minStockLevel: 20, unit: 'bag'),
    InventoryProduct(id: 'p8', name: 'Iron Sheets 28 Gauge 3m', category: 'Hardware', costPrice: 42000, sellPrice: 48500, currentStock: 60, minStockLevel: 15, unit: 'pc'),
    InventoryProduct(id: 'p9', name: 'Water Pump Knapsack 16L', category: 'Equipment', costPrice: 65000, sellPrice: 85000, currentStock: 8, minStockLevel: 5, unit: 'pc'),
  ];

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Agro');
    final costCtrl = TextEditingController();
    final sellCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final minStockCtrl = TextEditingController(text: '5');
    final unitCtrl = TextEditingController(text: 'pcs');

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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ref.tr('add_new_product'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: '${ref.tr('product_name')} *'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: catCtrl,
                      decoration: InputDecoration(labelText: '${ref.tr('category')} *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: InputDecoration(labelText: ref.tr('unit_label')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${ref.tr('cost_price')} *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: sellCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${ref.tr('sell_price')} *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${ref.tr('current_stock_qty')} *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: minStockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: ref.tr('min_stock_alert')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    setState(() {
                      _products.insert(
                        0,
                        InventoryProduct(
                          id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                          name: nameCtrl.text,
                          category: catCtrl.text,
                          costPrice: double.tryParse(costCtrl.text) ?? 0,
                          sellPrice: double.tryParse(sellCtrl.text) ?? 0,
                          currentStock: double.tryParse(stockCtrl.text) ?? 0,
                          minStockLevel: double.tryParse(minStockCtrl.text) ?? 5,
                          unit: unitCtrl.text,
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(ref.tr('save_product')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdjustStockDialog(InventoryProduct product) {
    final qtyCtrl = TextEditingController();
    String reason = 'restock';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${ref.tr('adjust_stock')}: ${product.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${ref.tr('current_stock_qty')}: ${product.currentStock.toInt()} ${product.unit}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: reason,
                decoration: InputDecoration(labelText: ref.tr('reason_adjustment')),
                items: [
                  DropdownMenuItem(value: 'restock', child: Text(ref.tr('adj_restock'))),
                  DropdownMenuItem(value: 'damage', child: Text(ref.tr('adj_damage'))),
                  DropdownMenuItem(value: 'loss', child: Text(ref.tr('adj_loss'))),
                  DropdownMenuItem(value: 'adjustment', child: Text(ref.tr('adj_audit'))),
                ],
                onChanged: (val) => setDialogState(() => reason = val ?? 'restock'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: reason == 'restock' ? ref.tr('qty_to_add') : ref.tr('qty_to_deduct'),
                  hintText: 'e.g. 10',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ref.tr('cancel'))),
            ElevatedButton(
              onPressed: () {
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) return;

                final delta = reason == 'restock' ? qty : -qty;
                setState(() {
                  product.currentStock = (product.currentStock + delta).clamp(0, 999999);
                });

                final syncEngine = ref.read(syncEngineProvider);
                syncEngine?.enqueueMutation(
                  entityType: 'stock_movement',
                  action: 'create',
                  payload: {
                    'productId': product.id,
                    'deltaQuantity': delta,
                    'reason': reason,
                  },
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${ref.tr('adjust_stock')} (${product.name}): Delta $delta')),
                );
              },
              child: Text(ref.tr('apply_delta')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authProvider);

    final filtered = _products.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final totalCostValuation = _products.fold<double>(0, (sum, p) => sum + (p.costPrice * p.currentStock));
    final totalRetailValuation = _products.fold<double>(0, (sum, p) => sum + (p.sellPrice * p.currentStock));

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('inventory_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: ref.tr('add_product'),
            onPressed: _showAddProductDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stock Valuation Header Card
          if (session?.canViewCostPrice == true)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ref.tr('stock_cost_val'), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatCompact(totalCostValuation),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 30, width: 1, color: AppColors.borderLight),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ref.tr('retail_potential'), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatCompact(totalRetailValuation),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primaryForest),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: '${ref.tr('search')}...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 8),

          // Product List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: filtered.length,
              itemBuilder: (ctx, index) {
                final product = filtered[index];
                final isLowStock = product.currentStock <= product.minStockLevel;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Sell: ${CurrencyFormatter.format(product.sellPrice)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryForest, fontSize: 12),
                            ),
                            if (session?.canViewCostPrice == true) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• Cost: ${CurrencyFormatter.format(product.costPrice)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isLowStock ? Colors.red.shade300 : Colors.green.shade300),
                          ),
                          child: Text(
                            '${product.currentStock.toInt()} ${product.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isLowStock ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _showAdjustStockDialog(product),
                          child: Text(ref.tr('adjust_stock'), style: const TextStyle(color: AppColors.primaryForest, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: AppColors.primaryForest,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(ref.tr('add_product'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
