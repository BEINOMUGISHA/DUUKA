import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_formatter.dart';

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

// ─── Purchase Order Data Model ───────────────────────────────────────────────
class PurchaseOrderItemData {
  final String productId;
  final String productName;
  final double quantityOrdered;
  final double quantityReceived;
  final double costPerUnit;
  final double total;

  const PurchaseOrderItemData({
    required this.productId,
    required this.productName,
    required this.quantityOrdered,
    required this.quantityReceived,
    required this.costPerUnit,
    required this.total,
  });

  factory PurchaseOrderItemData.fromJson(Map<String, dynamic> j) =>
      PurchaseOrderItemData(
        productId: j['productId'] as String,
        productName: j['productName'] as String,
        quantityOrdered: ((j['quantityOrdered'] as num?) ?? 0).toDouble(),
        quantityReceived: ((j['quantityReceived'] as num?) ?? 0).toDouble(),
        costPerUnit: ((j['costPerUnit'] as num?) ?? 0).toDouble(),
        total: ((j['total'] as num?) ?? 0).toDouble(),
      );
}

class PurchaseOrderData {
  final String id;
  final String supplierId;
  final String supplierName;
  final String poNumber;
  final String status; // 'ordered' | 'partially_received' | 'received' | 'cancelled'
  final List<PurchaseOrderItemData> items;
  final double subtotal;
  final double totalAmount;
  final double amountPaid;
  final double balance;
  final String? paymentMethod;
  final String? notes;
  final int orderedAt;
  final int? receivedAt;

  const PurchaseOrderData({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.poNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
    this.paymentMethod,
    this.notes,
    required this.orderedAt,
    this.receivedAt,
  });

  factory PurchaseOrderData.fromJson(Map<String, dynamic> j) => PurchaseOrderData(
        id: j['_id'] as String,
        supplierId: j['supplierId'] as String,
        supplierName: j['supplierName'] as String? ?? 'Supplier',
        poNumber: j['poNumber'] as String? ?? 'PO-2026-0000',
        status: j['status'] as String? ?? 'ordered',
        items: ((j['items'] as List<dynamic>?) ?? [])
            .map((e) => PurchaseOrderItemData.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        subtotal: ((j['subtotal'] as num?) ?? 0).toDouble(),
        totalAmount: ((j['totalAmount'] as num?) ?? 0).toDouble(),
        amountPaid: ((j['amountPaid'] as num?) ?? 0).toDouble(),
        balance: ((j['balance'] as num?) ?? 0).toDouble(),
        paymentMethod: j['paymentMethod'] as String?,
        notes: j['notes'] as String?,
        orderedAt: (j['orderedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
        receivedAt: (j['receivedAt'] as num?)?.toInt(),
      );
}

// ─── Suppliers & Purchase Orders Screen ──────────────────────────────────────
class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  String _poFilter = 'all';
  bool _loading = false;
  List<SupplierData> _suppliers = [];
  List<PurchaseOrderData> _purchaseOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadSuppliers(), _loadPurchaseOrders()]);
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

  Future<void> _loadPurchaseOrders() async {
    final session = ref.read(authProvider);
    if (session == null) return;
    try {
      final convex = ref.read(convexClientProvider);
      final result = await convex.query('suppliers:listPurchaseOrders', {
        'businessId': session.businessId,
        'userId': session.userId,
      });
      if (result != null && result is List) {
        setState(() {
          _purchaseOrders = result
              .map((e) => PurchaseOrderData.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        });
      }
    } catch (_) {}
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
                      decoration: const InputDecoration(
                        labelText: 'Contact Person',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
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
                      _loadData();
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

  /// ─── Create Purchase Order Interactive Dialog ──────────────────────────────
  void _showCreatePO(SupplierData supplier) {
    final products = ref.read(productsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesCtrl = TextEditingController();
    String paymentMethod = 'cash';

    // List of item line drafts
    final List<Map<String, dynamic>> poDraftItems = [];

    // Helper to add item to draft
    void addItem(LocalProductData product, double qty, double cost) {
      final existingIndex = poDraftItems.indexWhere((it) => it['productId'] == product.id);
      if (existingIndex >= 0) {
        poDraftItems[existingIndex]['quantityOrdered'] += qty;
        poDraftItems[existingIndex]['costPerUnit'] = cost;
      } else {
        poDraftItems.add({
          'productId': product.id,
          'productName': product.name,
          'unit': product.unit,
          'quantityOrdered': qty,
          'costPerUnit': cost,
        });
      }
    }

    if (products.isNotEmpty) {
      addItem(products.first, 10, products.first.costPrice);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final totalPoAmount = poDraftItems.fold<double>(
            0,
            (sum, it) => sum + (it['quantityOrdered'] as double) * (it['costPerUnit'] as double),
          );

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 18,
              right: 18,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📄 Create Purchase Order',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Supplier: ${supplier.name}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primaryForest, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 6),

                  // Order items list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Line Items',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (products.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text('Add Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setSheetState(() {
                              addItem(products.first, 5, products.first.costPrice);
                            });
                          },
                        ),
                    ],
                  ),

                  ...poDraftItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final lineTotal = (item['quantityOrdered'] as double) * (item['costPerUnit'] as double);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: item['productId'] as String,
                                  isExpanded: true,
                                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  items: products
                                      .map((p) => DropdownMenuItem(
                                            value: p.id,
                                            child: Text(p.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                          ))
                                      .toList(),
                                  onChanged: (newId) {
                                    if (newId != null) {
                                      final selectedProd = products.firstWhere((p) => p.id == newId);
                                      setSheetState(() {
                                        item['productId'] = selectedProd.id;
                                        item['productName'] = selectedProd.name;
                                        item['unit'] = selectedProd.unit;
                                        item['costPerUnit'] = selectedProd.costPrice;
                                      });
                                    }
                                  },
                                ),
                              ),
                              if (poDraftItems.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger, size: 20),
                                  onPressed: () => setSheetState(() => poDraftItems.removeAt(index)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: (item['quantityOrdered'] as double).toInt().toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Qty (${item['unit'] ?? 'pcs'})',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  onChanged: (val) {
                                    final q = double.tryParse(val) ?? 1;
                                    setSheetState(() => item['quantityOrdered'] = q);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: (item['costPerUnit'] as double).toInt().toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Cost/Unit (UGX)',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                  onChanged: (val) {
                                    final c = double.tryParse(val) ?? 0;
                                    setSheetState(() => item['costPerUnit'] = c);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                CurrencyFormatter.format(lineTotal),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.primaryForest),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Planned Payment Method:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: paymentMethod,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'mtn_momo', child: Text('MTN MoMo', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'airtel_money', child: Text('Airtel Money', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'bank', child: Text('Bank Transfer', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) => setSheetState(() => paymentMethod = v ?? 'cash'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Order Notes / Delivery Instructions (Optional)', isDense: true),
                  ),
                  const SizedBox(height: 14),

                  // Total & Submit
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryForest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Estimated PO Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          CurrencyFormatter.format(totalPoAmount),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primaryForest),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Generate & Issue Purchase Order', style: TextStyle(fontWeight: FontWeight.w900)),
                      onPressed: poDraftItems.isEmpty || totalPoAmount <= 0
                          ? null
                          : () async {
                              final session = ref.read(authProvider);
                              if (session == null) return;
                              Navigator.pop(ctx);

                              try {
                                final convex = ref.read(convexClientProvider);
                                final res = await convex.mutation('suppliers:createPurchaseOrder', {
                                  'businessId': session.businessId,
                                  'userId': session.userId,
                                  'supplierId': supplier.id,
                                  'items': poDraftItems
                                      .map((it) => {
                                            'productId': it['productId'],
                                            'productName': it['productName'],
                                            'quantityOrdered': it['quantityOrdered'],
                                            'costPerUnit': it['costPerUnit'],
                                          })
                                      .toList(),
                                  'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                                  'paymentMethod': paymentMethod,
                                  'deviceId': session.deviceId,
                                });

                                _loadData();
                                _tabController.animateTo(1); // Switch to POs tab

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ ${res['poNumber']} generated successfully (${CurrencyFormatter.format(totalPoAmount)})'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error creating PO: $e'), backgroundColor: AppColors.danger),
                                  );
                                }
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

  /// ─── Receive Goods (GRN) Dialog ────────────────────────────────────────────
  void _showReceiveGoodsDialog(PurchaseOrderData po) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> receivedDraft = po.items.map((it) {
      final remaining = (it.quantityOrdered - it.quantityReceived).clamp(0.0, double.infinity);
      return {
        'productId': it.productId,
        'productName': it.productName,
        'quantityOrdered': it.quantityOrdered,
        'quantityAlreadyReceived': it.quantityReceived,
        'quantityReceivingNow': remaining,
        'costPerUnit': it.costPerUnit,
      };
    }).toList();

    final paidCtrl = TextEditingController(text: po.balance.toInt().toString());
    String paymentMethod = po.paymentMethod ?? 'cash';
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final receivingValue = receivedDraft.fold<double>(
            0,
            (sum, it) => sum + (it['quantityReceivingNow'] as double) * (it['costPerUnit'] as double),
          );

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 18,
              right: 18,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📦 Receive Goods (GRN) - ${po.poNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          Text('Supplier: ${po.supplierName}', style: const TextStyle(fontSize: 12, color: AppColors.primaryForest, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  const Text('Verify Received Quantities to Auto-Restock Inventory:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  ...receivedDraft.map((it) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it['productName'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(
                                  'Ordered: ${(it['quantityOrdered'] as double).toInt()} | Prev Recv: ${(it['quantityAlreadyReceived'] as double).toInt()}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: (it['quantityReceivingNow'] as double).toInt().toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Recv Now', isDense: true),
                              onChanged: (val) {
                                final q = double.tryParse(val) ?? 0;
                                setSheetState(() => it['quantityReceivingNow'] = q);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: paidCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Amount Paid Now (UGX)', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: paymentMethod,
                          decoration: const InputDecoration(labelText: 'Payment Method', isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(value: 'mtn_momo', child: Text('MTN MoMo')),
                            DropdownMenuItem(value: 'airtel_money', child: Text('Airtel')),
                            DropdownMenuItem(value: 'bank', child: Text('Bank')),
                          ],
                          onChanged: (v) => setSheetState(() => paymentMethod = v ?? 'cash'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'GRN Delivery Notes / Invoice Ref', isDense: true),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.inventory_2_rounded),
                      label: const Text('Confirm GRN & Auto-Restock', style: TextStyle(fontWeight: FontWeight.w900)),
                      onPressed: () async {
                        final session = ref.read(authProvider);
                        if (session == null) return;
                        final amountPaid = double.tryParse(paidCtrl.text.trim()) ?? 0;
                        Navigator.pop(ctx);

                        try {
                          final convex = ref.read(convexClientProvider);
                          await convex.mutation('suppliers:receivePurchaseOrder', {
                            'businessId': session.businessId,
                            'userId': session.userId,
                            'poId': po.id,
                            'receivedItems': receivedDraft
                                .map((it) => {
                                      'productId': it['productId'],
                                      'quantityReceived': it['quantityReceivingNow'],
                                      'costPerUnit': it['costPerUnit'],
                                    })
                                .toList(),
                            'amountPaid': amountPaid,
                            'paymentMethod': paymentMethod,
                            'notes': notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                            'deviceId': session.deviceId,
                          });

                          // Auto-restock in local DB
                          for (final it in receivedDraft) {
                            final q = it['quantityReceivingNow'] as double;
                            if (q > 0) {
                              ref.read(productsProvider.notifier).restockProduct(
                                    productId: it['productId'] as String,
                                    businessId: session.businessId,
                                    qtyReceived: q,
                                    costPerUnit: it['costPerUnit'] as double,
                                    supplierName: po.supplierName,
                                    notes: 'GRN ${po.poNumber}',
                                  );
                            }
                          }

                          _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Goods received and inventory restocked for ${po.poNumber}'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error receiving goods: $e'), backgroundColor: AppColors.danger),
                            );
                          }
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
          color: hasAP ? AppColors.warning.withAlpha(180) : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: hasAP ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryForest.withValues(alpha: 0.15),
          child: Text(
            supplier.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: AppColors.primaryForest,
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
            if (supplier.phone != null) Text(PhoneFormatter.formatDisplay(supplier.phone!), style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                _statChip('Purchased: ${CurrencyFormatter.format(supplier.totalPurchased)}', AppColors.success),
                if (hasAP) ...[
                  const SizedBox(width: 6),
                  _statChip('Payable: ${CurrencyFormatter.format(supplier.outstandingPayable)}', AppColors.danger),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) {
            if (val == 'edit') _showAddEditSupplier(supplier);
            if (val == 'create_po') _showCreatePO(supplier);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'create_po',
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart_rounded, size: 18, color: AppColors.primaryForest),
                  SizedBox(width: 8),
                  Text('Create Purchase Order'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Edit Supplier'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOrderCard(PurchaseOrderData po) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFullyReceived = po.status == 'received';
    final dateStr = DateTime.fromMillisecondsSinceEpoch(po.orderedAt).toString().substring(0, 10);

    Color statusColor = AppColors.primaryForest;
    if (po.status == 'ordered') statusColor = Colors.blue;
    if (po.status == 'partially_received') statusColor = Colors.orange;
    if (po.status == 'received') statusColor = AppColors.success;
    if (po.status == 'cancelled') statusColor = AppColors.danger;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      color: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(po.poNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        po.status.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Supplier: ${po.supplierName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '${po.items.length} item(s) · Total: ${CurrencyFormatter.format(po.totalAmount)} · Bal: ${CurrencyFormatter.format(po.balance)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isFullyReceived && po.status != 'cancelled')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.inventory_2_outlined, size: 15),
                    label: const Text('Receive Goods (GRN)'),
                    onPressed: () => _showReceiveGoodsDialog(po),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAP = _suppliers.fold<double>(0, (s, sup) => s + sup.outstandingPayable);
    final totalPurchases = _suppliers.fold<double>(0, (s, sup) => s + sup.totalPurchased);

    final filteredSuppliers = _suppliers
        .where((s) => s.name.toLowerCase().contains(_search.toLowerCase()) || (s.phone?.contains(_search) ?? false))
        .toList();

    final filteredPOs = _purchaseOrders.where((po) {
      if (_poFilter == 'ordered') return po.status == 'ordered';
      if (_poFilter == 'partially_received') return po.status == 'partially_received';
      if (_poFilter == 'received') return po.status == 'received';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Suppliers & Procurement'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Suppliers (${_suppliers.length})'),
            Tab(text: 'Purchase Orders (${_purchaseOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Suppliers ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard('Total AP (Payable)', CurrencyFormatter.format(totalAP), Icons.account_balance_wallet_outlined, AppColors.danger, isDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _summaryCard('Total Purchased', CurrencyFormatter.format(totalPurchases), Icons.shopping_bag_outlined, AppColors.success, isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search suppliers by name or phone...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) => setState(() => _search = val),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (filteredSuppliers.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(_search.isEmpty ? 'No suppliers yet.\nTap + to add your first supplier.' : 'No suppliers match "$_search"'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _buildSupplierCard(filteredSuppliers[i]),
                        childCount: filteredSuppliers.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Tab 2: Purchase Orders ────────────────────────────────────
          RefreshIndicator(
            onRefresh: _loadData,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['all', 'ordered', 'partially_received', 'received'].map((f) {
                        final isSelected = _poFilter == f;
                        final label = f == 'all' ? 'All POs' : f.toUpperCase().replaceAll('_', ' ');
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
                            selected: isSelected,
                            selectedColor: AppColors.primaryForest,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMain : AppColors.textMain)),
                            onSelected: (_) => setState(() => _poFilter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredPOs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 54, color: isDark ? Colors.white24 : Colors.black12),
                              const SizedBox(height: 10),
                              const Text('No purchase orders found', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_shopping_cart_rounded),
                                label: const Text('Create PO via Supplier Tab'),
                                onPressed: () => _tabController.animateTo(0),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 80),
                          itemCount: filteredPOs.length,
                          itemBuilder: (_, i) => _buildPurchaseOrderCard(filteredPOs[i]),
                        ),
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

  Widget _summaryCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
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
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
