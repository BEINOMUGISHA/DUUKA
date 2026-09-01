import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';

class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- DIALOG: ADD/EDIT RAW MATERIAL ---
  void _showAddEditRawMaterialDialog([LocalRawMaterialData? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'kg');
    final stockCtrl = TextEditingController(text: existing != null ? existing.currentStock.toString() : '0');
    final minCtrl = TextEditingController(text: existing != null ? existing.minStockLevel.toString() : '10');
    final costCtrl = TextEditingController(text: existing != null ? existing.unitCost.toInt().toString() : '1000');
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
                    existing == null ? 'Add Raw Material' : 'Edit Raw Material',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Material Name (e.g. Grain, Premix, Bags) *'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: unitCtrl.text,
                      decoration: const InputDecoration(labelText: 'Unit of Measure'),
                      items: ['kg', 'ltr', 'bags', 'g', 'pcs', 'meters']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) unitCtrl.text = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unit Cost (UGX) *'),
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
                      decoration: const InputDecoration(labelText: 'Current Stock *'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min Alert Level *'),
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
                    final rm = LocalRawMaterialData(
                      id: existing?.id ?? 'rm_$now',
                      businessId: 'biz_default',
                      name: nameCtrl.text.trim(),
                      unit: unitCtrl.text.trim(),
                      currentStock: double.tryParse(stockCtrl.text) ?? 0,
                      minStockLevel: double.tryParse(minCtrl.text) ?? 5,
                      unitCost: double.tryParse(costCtrl.text) ?? 0,
                      updatedAt: now,
                    );
                    if (existing == null) {
                      await ref.read(rawMaterialsProvider.notifier).addRawMaterial(rm);
                    } else {
                      await ref.read(rawMaterialsProvider.notifier).updateRawMaterial(rm);
                    }
                    if (mounted) Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Save Material' : 'Update Material'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOG: CREATE RECIPE / FORMULA ---
  void _showAddRecipeDialog() {
    final nameCtrl = TextEditingController();
    final laborCtrl = TextEditingController(text: '5000');
    final outQtyCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    final products = ref.read(productsProvider);
    final rawMaterials = ref.read(rawMaterialsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add finished products to inventory first.')),
      );
      return;
    }

    String selectedProductId = products.first.id;
    String selectedProductName = products.first.name;

    // Selected ingredient list: Map of {rawMaterialId, rawMaterialName, quantity, unit}
    final List<Map<String, dynamic>> ingredients = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Calculate estimated unit cost
          double rawCost = 0.0;
          for (final ing in ingredients) {
            final rm = rawMaterials.firstWhere((r) => r.id == ing['rawMaterialId'], orElse: () => rawMaterials.first);
            rawCost += (rm.unitCost * (ing['quantity'] as double));
          }
          final labor = double.tryParse(laborCtrl.text) ?? 0;
          final outQty = double.tryParse(outQtyCtrl.text) ?? 1;
          final totalEstCost = rawCost + labor;
          final estCostPerUnit = outQty > 0 ? (totalEstCost / outQty) : 0;

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
                      const Text(
                        'New Production Formula',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Formula Name (e.g. 50kg Fertilizer Batch) *'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Finished Product Produced *'),
                    items: products
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedProductId = val;
                          selectedProductName = products.firstWhere((p) => p.id == val).name;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: outQtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Yield Output Qty *'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: laborCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Labor / Overhead (UGX)'),
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Raw Material Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Add Ingredient'),
                        onPressed: () {
                          if (rawMaterials.isEmpty) return;
                          setModalState(() {
                            ingredients.add({
                              'rawMaterialId': rawMaterials.first.id,
                              'rawMaterialName': rawMaterials.first.name,
                              'quantity': 1.0,
                              'unit': rawMaterials.first.unit,
                            });
                          });
                        },
                      ),
                    ],
                  ),
                  if (ingredients.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'No ingredients added yet. Tap "+ Add Ingredient" above.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ...ingredients.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final ing = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                initialValue: ing['rawMaterialId'] as String,
                                isExpanded: true,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                                items: rawMaterials
                                    .map((rm) => DropdownMenuItem(
                                          value: rm.id,
                                          child: Text('${rm.name} (${rm.unit})', style: const TextStyle(fontSize: 12)),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final rm = rawMaterials.firstWhere((r) => r.id == val);
                                    setModalState(() {
                                      ingredients[idx]['rawMaterialId'] = val;
                                      ingredients[idx]['rawMaterialName'] = rm.name;
                                      ingredients[idx]['unit'] = rm.unit;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: ing['quantity'].toString(),
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: ing['unit'],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                onChanged: (val) {
                                  final q = double.tryParse(val) ?? 1.0;
                                  setModalState(() {
                                    ingredients[idx]['quantity'] = q;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                              onPressed: () {
                                setModalState(() {
                                  ingredients.removeAt(idx);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  // Estimated Unit Cost Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryForest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryForest.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Est. Production Cost/Unit:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        Text(
                          CurrencyFormatter.format(estCostPerUnit),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryForest, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty || ingredients.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please name the recipe and add at least 1 ingredient')),
                          );
                          return;
                        }
                        final now = DateTime.now().millisecondsSinceEpoch;
                        final recipe = LocalRecipeData(
                          id: 'rec_$now',
                          businessId: 'biz_default',
                          name: nameCtrl.text.trim(),
                          outputProductId: selectedProductId,
                          outputProductName: selectedProductName,
                          outputQuantity: double.tryParse(outQtyCtrl.text) ?? 1,
                          ingredientsJson: jsonEncode(ingredients),
                          laborCost: double.tryParse(laborCtrl.text) ?? 0,
                          notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                          createdAt: now,
                        );
                        await ref.read(recipesProvider.notifier).addRecipe(recipe);
                        if (mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Save Formula'),
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

  // --- DIALOG: EXECUTE PRODUCTION BATCH ---
  void _showRecordBatchDialog() {
    final recipes = ref.read(recipesProvider);
    final countCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (recipes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a production formula first.')),
      );
      return;
    }

    String selectedRecipeId = recipes.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final recipe = recipes.firstWhere((r) => r.id == selectedRecipeId, orElse: () => recipes.first);
          final batches = double.tryParse(countCtrl.text) ?? 1.0;
          final totalProduced = recipe.outputQuantity * batches;

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
                      const Text(
                        'Run Production Batch',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRecipeId,
                    decoration: const InputDecoration(labelText: 'Select Formula'),
                    items: recipes
                        .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRecipeId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: countCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of Batches *',
                      prefixIcon: Icon(Icons.precision_manufacturing_rounded),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Batch Notes / Operator Name'),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚡ Production Action:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Will produce: ${totalProduced.toInt()} units of "${recipe.outputProductName}"\n'
                          '• Will automatically add stock to finished inventory\n'
                          '• Will deduct raw material ingredients automatically',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Execute & Update Stock', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final batchNum = double.tryParse(countCtrl.text) ?? 1.0;
                        await ref.read(productionBatchesProvider.notifier).recordBatch(
                              recipeId: selectedRecipeId,
                              batchesCount: batchNum,
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Successfully produced ${totalProduced.toInt()} units of ${recipe.outputProductName}')),
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
    final rawMaterials = ref.watch(rawMaterialsProvider);
    final recipes = ref.watch(recipesProvider);
    final batches = ref.watch(productionBatchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lowStockRawMaterials = rawMaterials.where((r) => r.currentStock <= r.minStockLevel).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Production & Manufacturing'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.emeraldNeon : AppColors.primaryForest,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          indicatorColor: isDark ? AppColors.emeraldNeon : AppColors.primaryForest,
          tabs: [
            Tab(text: 'Raw Materials (${rawMaterials.length})'),
            Tab(text: 'Formulas (${recipes.length})'),
            Tab(text: 'Batch Log (${batches.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: AppColors.accentGold),
            tooltip: 'Run Batch',
            onPressed: _showRecordBatchDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddEditRawMaterialDialog();
          } else if (_tabController.index == 1) {
            _showAddRecipeDialog();
          } else {
            _showRecordBatchDialog();
          }
        },
        backgroundColor: AppColors.primaryForest,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0
              ? 'Add Material'
              : _tabController.index == 1
                  ? 'New Formula'
                  : 'Run Batch',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: RAW MATERIALS ---
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (lowStockRawMaterials > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$lowStockRawMaterials raw materials are below minimum stock level!',
                        style: const TextStyle(color: Color(0xFF92400E), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              if (rawMaterials.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No raw materials added yet. Tap "+ Add Material" below.'),
                  ),
                )
              else
                ...rawMaterials.map((rm) {
                  final isLow = rm.currentStock <= rm.minStockLevel;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isLow ? const Color(0xFFFEE2E2) : AppColors.primaryForest.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.grain_rounded,
                              color: isLow ? AppColors.danger : AppColors.primaryForest,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rm.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cost: ${CurrencyFormatter.format(rm.unitCost)} / ${rm.unit}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isLow ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${rm.currentStock.toStringAsFixed(1)} ${rm.unit}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: isLow ? AppColors.danger : Colors.green.shade900,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, size: 20, color: AppColors.primaryForest),
                                    onPressed: () => ref.read(rawMaterialsProvider.notifier).adjustStock(rm.id, 10),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: '+10 Stock',
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                                    onPressed: () => _showAddEditRawMaterialDialog(rm),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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

          // --- TAB 2: FORMULAS / RECIPES ---
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (recipes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No formulas created yet. Tap "+ New Formula" below.'),
                  ),
                )
              else
                ...recipes.map((r) {
                  List<dynamic> ings = [];
                  try {
                    ings = jsonDecode(r.ingredientsJson) as List<dynamic>;
                  } catch (_) {}

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  r.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                onPressed: () => ref.read(recipesProvider.notifier).deleteRecipe(r.id),
                              ),
                            ],
                          ),
                          Text(
                            'Produces: ${r.outputQuantity.toInt()}x ${r.outputProductName}',
                            style: const TextStyle(color: AppColors.primaryForest, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          const Text('Ingredients Formula:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: ings.map((it) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${it['rawMaterialName']}: ${it['quantity']} ${it['unit']}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Labor Cost: ${CurrencyFormatter.format(r.laborCost)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryForest,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                                label: const Text('Produce Batch', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: _showRecordBatchDialog,
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

          // --- TAB 3: BATCH LOG ---
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (batches.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No production batches run yet. Tap "+ Run Batch" below.'),
                  ),
                )
              else
                ...batches.map((b) {
                  final date = DateTime.fromMillisecondsSinceEpoch(b.batchDate);
                  final dateStr = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFDCFCE7),
                        child: Icon(Icons.check_circle_rounded, color: AppColors.primaryForest),
                      ),
                      title: Text(
                        '${b.quantityProduced.toInt()}x ${b.outputProductName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Formula: ${b.recipeName}\n$dateStr',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(b.totalCost),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primaryForest),
                          ),
                          Text(
                            '${CurrencyFormatter.format(b.unitCost)}/unit',
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
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
