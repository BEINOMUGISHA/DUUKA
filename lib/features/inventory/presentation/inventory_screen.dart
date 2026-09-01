import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  void _showAddEditProductDialog([LocalProductData? existing]) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? 'Agro');
    final costCtrl = TextEditingController(text: existing != null ? existing.costPrice.toInt().toString() : '');
    final sellCtrl = TextEditingController(text: existing != null ? existing.sellPrice.toInt().toString() : '');
    final wholesaleCtrl = TextEditingController(text: existing?.wholesalePrice != null ? existing!.wholesalePrice!.toInt().toString() : '');
    final stockCtrl = TextEditingController(text: existing != null ? existing.currentStock.toInt().toString() : '');
    final minStockCtrl = TextEditingController(text: existing != null ? existing.minStockLevel.toInt().toString() : '5');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'pcs');
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
                  Text(
                    isEditing ? 'Edit Product' : ref.tr('add_new_product'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                    child: DropdownButtonFormField<String>(
                      initialValue: ['Agro', 'Seeds', 'Chemicals', 'Hardware', 'Equipment', 'General'].contains(catCtrl.text)
                          ? catCtrl.text
                          : 'Agro',
                      decoration: InputDecoration(labelText: '${ref.tr('category')} *'),
                      items: ['Agro', 'Seeds', 'Chemicals', 'Hardware', 'Equipment', 'General']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) catCtrl.text = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: ['pcs', 'bag', 'pkt', 'bottle', 'kg', 'tin'].contains(unitCtrl.text)
                          ? unitCtrl.text
                          : 'pcs',
                      decoration: InputDecoration(labelText: '${ref.tr('unit')} *'),
                      items: ['pcs', 'bag', 'pkt', 'bottle', 'kg', 'tin']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) unitCtrl.text = val;
                      },
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
                      decoration: InputDecoration(labelText: '${ref.tr('cost_price')} (UGX) *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: sellCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${ref.tr('selling_price')} (UGX) *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: wholesaleCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Wholesale / Bulk Price (UGX) [Optional]',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${ref.tr('current_stock')} *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: minStockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${ref.tr('min_stock_alert')} *'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final cat = catCtrl.text.trim();
                    final cost = double.tryParse(costCtrl.text.trim()) ?? 0;
                    final sell = double.tryParse(sellCtrl.text.trim()) ?? 0;
                    final wholesale = double.tryParse(wholesaleCtrl.text.trim());
                    final stock = double.tryParse(stockCtrl.text.trim()) ?? 0;
                    final minStock = double.tryParse(minStockCtrl.text.trim()) ?? 5;
                    final unit = unitCtrl.text.trim();
                    final session = ref.read(authProvider);

                    if (name.isEmpty || sell <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid product name and selling price')),
                      );
                      return;
                    }

                    if (isEditing) {
                      final updated = existing.copyWith(
                        name: name,
                        category: cat,
                        costPrice: cost,
                        sellPrice: sell,
                        wholesalePrice: wholesale,
                        currentStock: stock,
                        minStockLevel: minStock,
                        unit: unit,
                      );
                      ref.read(productsProvider.notifier).editProduct(updated);
                    } else {
                      final newProd = LocalProductData(
                        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                        businessId: session?.businessId ?? 'biz_default',
                        name: name,
                        category: cat,
                        costPrice: cost,
                        sellPrice: sell,
                        wholesalePrice: wholesale,
                        currentStock: stock,
                        minStockLevel: minStock,
                        unit: unit,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      );
                      ref.read(productsProvider.notifier).addProduct(newProd);
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Product updated' : 'Product added successfully')),
                    );
                  },
                  child: Text(
                    isEditing ? ref.tr('update_product') : ref.tr('save_product'),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestockDialog(LocalProductData product) {
    final qtyCtrl = TextEditingController(text: '10');
    final costCtrl = TextEditingController(text: product.costPrice.toInt().toString());
    final supplierCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📦 Restock (Goods Received)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          product.name,
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryForest, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity Received (${product.unit}) *',
                        prefixIcon: const Icon(Icons.add_box_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cost / Unit (UGX) *',
                        prefixIcon: Icon(Icons.payments_rounded, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: supplierCtrl,
                decoration: const InputDecoration(
                  labelText: 'Supplier Name (Optional)',
                  prefixIcon: Icon(Icons.local_shipping_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Batch / Invoice Notes (Optional)',
                  prefixIcon: Icon(Icons.note_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                    final unitCost = double.tryParse(costCtrl.text.trim()) ?? product.costPrice;
                    final session = ref.read(authProvider);

                    if (qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid received quantity')),
                      );
                      return;
                    }

                    ref.read(productsProvider.notifier).restockProduct(
                          productId: product.id,
                          businessId: session?.businessId ?? 'biz_default',
                          qtyReceived: qty,
                          costPerUnit: unitCost,
                          supplierName: supplierCtrl.text.isNotEmpty ? supplierCtrl.text : null,
                          notes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                        );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restocked ${qty.toInt()} ${product.unit} of ${product.name}')),
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Confirm Restock',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteProduct(LocalProductData product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Product?'),
        content: Text('Are you sure you want to remove "${product.name}" from active inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              ref.read(productsProvider.notifier).archiveProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Archived ${product.name}')),
              );
            },
            child: const Text('Archive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final session = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = ['All', 'Agro', 'Seeds', 'Chemicals', 'Hardware', 'Equipment', 'General'];

    final filtered = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    final totalStockValue = products.fold<double>(0, (sum, p) => sum + (p.currentStock * p.sellPrice));
    final totalCostValue = products.fold<double>(0, (sum, p) => sum + (p.currentStock * p.costPrice));
    final lowStockCount = products.where((p) => p.currentStock <= p.minStockLevel).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ref.tr('inventory_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded),
            tooltip: 'Add Product',
            onPressed: () => _showAddEditProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // STOCK VALUATION CARD
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryForest.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.tr('stock_valuation'),
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(totalStockValue),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (session?.canViewCostPrice == true)
                            Text(
                              'Cost: ${CurrencyFormatter.format(totalCostValue)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          if (session?.canViewCostPrice == true) const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: lowStockCount > 0 ? AppColors.danger : Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$lowStockCount Low Stock',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/inventory_illustration.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: '${ref.tr('search')} products...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryForest,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMain : AppColors.textMain)),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Product List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          products.isEmpty ? 'No products in inventory yet' : 'No matching products found',
                          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                        if (products.isEmpty) const SizedBox(height: 12),
                        if (products.isEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditProductDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Your First Product'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final product = filtered[index];
                      final isLowStock = product.currentStock <= product.minStockLevel;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showAddEditProductDialog(product),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceMuted,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              product.category,
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              product.name,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            'Sell: ${CurrencyFormatter.format(product.sellPrice)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primaryForest,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (product.wholesalePrice != null) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE0F2FE),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'WS: ${CurrencyFormatter.format(product.wholesalePrice!)}',
                                                style: const TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
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
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.danger),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            if (product.currentStock > 0) {
                                              ref.read(databaseProvider).updateProductStock(product.id, -1);
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 4),
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
                                              fontWeight: FontWeight.w900,
                                              fontSize: 12,
                                              color: isLowStock ? AppColors.danger : AppColors.success,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primaryForest),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            ref.read(databaseProvider).updateProductStock(product.id, 1);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => _showRestockDialog(product),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryForest.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.add_shopping_cart_rounded, size: 12, color: AppColors.primaryForest),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Restock',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryForest),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: () => _confirmDeleteProduct(product),
                                          child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditProductDialog(),
        backgroundColor: AppColors.primaryForest,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          ref.tr('add_product'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
