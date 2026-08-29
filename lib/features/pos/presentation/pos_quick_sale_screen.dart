import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/uganda_presets.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/spinning_wheel_picker.dart';
import 'receipt_share_screen.dart';
import '../../payments/presentation/receive_payment_sheet.dart';

class PosItem {
  final String id;
  final String name;
  final String category;
  final String icon;
  final double costPrice;
  final double sellPrice;
  final double currentStock;
  final String unit;
  final bool isTaxable;

  const PosItem({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.costPrice,
    required this.sellPrice,
    required this.currentStock,
    required this.unit,
    this.isTaxable = true,
  });
}

class CartItem {
  final PosItem product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.sellPrice * quantity;
  double get taxAmount => product.isTaxable ? subtotal * (0.18 / 1.18) : 0.0;
}

class PosQuickSaleScreen extends ConsumerStatefulWidget {
  const PosQuickSaleScreen({super.key});

  @override
  ConsumerState<PosQuickSaleScreen> createState() => _PosQuickSaleScreenState();
}

class _PosQuickSaleScreenState extends ConsumerState<PosQuickSaleScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Map<String, CartItem> _cart = {};

  double get _cartTotal => _cart.values.fold(0, (sum, item) => sum + item.subtotal);
  int get _cartItemCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(PosItem product) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_cart.containsKey(product.id)) {
        _cart[product.id]!.quantity++;
      } else {
        _cart[product.id] = CartItem(product: product, quantity: 1);
      }
    });
  }

  void _decrementCart(PosItem product) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_cart.containsKey(product.id)) {
        if (_cart[product.id]!.quantity > 1) {
          _cart[product.id]!.quantity--;
        } else {
          _cart.remove(product.id);
        }
      }
    });
  }

  void _showCheckoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutBottomSheet(
        cartItems: _cart.values.toList(),
        totalAmount: _cartTotal,
        onCheckoutComplete: () {
          setState(() {
            _cart.clear();
          });
        },
      ),
    );
  }

  /// Opens a 3D spinning wheel to let the user pick an exact quantity (1–50).
  void _showQtyWheelPicker(PosItem product) {
    final currentQty = _cart[product.id]?.quantity ?? 1;
    final items = List.generate(
      50,
      (i) => WheelPickerItem<int>(
        value: i + 1,
        title: '${i + 1}',
        subtitle: product.unit,
        trailing: CurrencyFormatter.format(product.sellPrice * (i + 1)),
        color: AppColors.primaryForest,
      ),
    );
    int selectedQty = currentQty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Set quantity',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryForest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '× $selectedQty ${product.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryForest,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SpinningWheelPicker<int>(
                items: items,
                initialIndex: currentQty - 1,
                height: 240,
                itemExtent: 60,
                onItemSelected: (index) {
                  setModalState(() => selectedQty = index + 1);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (selectedQty <= 0) {
                        _cart.remove(product.id);
                      } else {
                        _cart[product.id] = CartItem(product: product, quantity: selectedQty);
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    'Confirm ${selectedQty}× ${product.unit}  •  ${CurrencyFormatter.format(product.sellPrice * selectedQty)}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbProducts = ref.watch(productsProvider);
    final posProducts = dbProducts.map((p) {
      String icon = '📦';
      if (p.category == 'Agro') icon = '🌾';
      else if (p.category == 'Seeds') icon = '🌱';
      else if (p.category == 'Chemicals') icon = '🧪';
      else if (p.category == 'Hardware') icon = '🧱';
      else if (p.category == 'Equipment') icon = '⚙️';

      return PosItem(
        id: p.id,
        name: p.name,
        category: p.category,
        icon: icon,
        costPrice: p.costPrice,
        sellPrice: p.sellPrice,
        currentStock: p.currentStock,
        unit: p.unit,
        isTaxable: p.isTaxable,
      );
    }).toList();

    final filteredProducts = posProducts.where((p) {
      final matchesCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    final categories = [
      {'name': 'All', 'icon': '✨'},
      {'name': 'Agro', 'icon': '🌾'},
      {'name': 'Seeds', 'icon': '🌱'},
      {'name': 'Chemicals', 'icon': '🧪'},
      {'name': 'Hardware', 'icon': '🧱'},
      {'name': 'Equipment', 'icon': '⚙️'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(ref.tr('pos_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: ref.tr('scan_barcode'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ref.tr('scan_barcode'))),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern Search & Category Scroll
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: ref.tr('search_products_hint'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primaryForest),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final name = cat['name']!;
                      final isSelected = _selectedCategory == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Text(cat['icon']!, style: const TextStyle(fontSize: 13)),
                          label: Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textMain,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryForest,
                          backgroundColor: AppColors.surfaceMuted,
                          side: BorderSide(
                            color: isSelected ? AppColors.primaryForest : AppColors.borderLight,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          onSelected: (_) => setState(() => _selectedCategory = name),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // PRODUCT CARDS GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, index) {
                final prod = filteredProducts[index];
                final cartQty = _cart[prod.id]?.quantity ?? 0;
                final isLowStock = prod.currentStock <= 5;

                return InkWell(
                  onTap: () => _addToCart(prod),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: cartQty > 0 ? AppColors.primaryEmerald.withValues(alpha: 0.6) : AppColors.borderLight,
                        width: cartQty > 0 ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cartQty > 0
                              ? AppColors.primaryEmerald.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top category badge & stock badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(prod.icon, style: const TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                  Text(
                                    prod.category,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isLowStock ? Colors.red.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isLowStock ? Colors.red.shade300 : Colors.green.shade200),
                              ),
                              child: Text(
                                '${prod.currentStock.toInt()} ${prod.unit}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isLowStock ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Product Name
                        Expanded(
                          child: Text(
                            prod.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.25),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Price
                        Text(
                          CurrencyFormatter.format(prod.sellPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryForest,
                            fontSize: 14,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Add / Quantity Stepper
                        if (cartQty > 0)
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryForest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () => _decrementCart(prod),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.remove_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                                // Long-press to open spinning wheel quantity picker
                                GestureDetector(
                                  onLongPress: () => _showQtyWheelPicker(prod),
                                  child: Tooltip(
                                    message: 'Hold to set exact quantity',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      child: Text(
                                        '$cartQty',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _addToCart(prod),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 34,
                            child: OutlinedButton.icon(
                              onPressed: () => _addToCart(prod),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(ref.tr('add'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryForest,
                                side: const BorderSide(color: AppColors.primaryForest, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.zero,
                              ),
                            ),
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

      // FLOATING CART PILL (Elevated & Pulsing on Add)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _cart.isNotEmpty
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryForest.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/bag_icon.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
                    ),
                  ).animate(key: ValueKey(_cartItemCount)).scale(duration: 200.ms, curve: Curves.easeOutBack),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ref.tr('total_payable'),
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        CurrencyFormatter.format(_cartTotal),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showCheckoutSheet,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black),
                    label: Text(
                      ref.tr('checkout_btn'),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emeraldNeon,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.5, end: 0, duration: 250.ms).fadeIn()
          : null,
    );
  }
}

// CHECKOUT BOTTOM SHEET (Ugandan Shortcuts, MoMo & Credit Styling)
class _CheckoutBottomSheet extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final VoidCallback onCheckoutComplete;

  const _CheckoutBottomSheet({
    required this.cartItems,
    required this.totalAmount,
    required this.onCheckoutComplete,
  });

  @override
  ConsumerState<_CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends ConsumerState<_CheckoutBottomSheet> {
  String _paymentMethod = UgandaPresets.paymentMtnMomo;
  final TextEditingController _momoRefController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();
  bool _isCreditSale = false;

  @override
  void initState() {
    super.initState();
    _paidAmountController.text = widget.totalAmount.toInt().toString();
  }

  @override
  void dispose() {
    _momoRefController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _quickSetPaid(double amount) {
    setState(() {
      _paidAmountController.text = amount.toInt().toString();
    });
  }

  void _processPayment() {
    final paid = double.tryParse(_paidAmountController.text) ?? (_isCreditSale ? 0.0 : widget.totalAmount);
    final due = widget.totalAmount - paid;

    final session = ref.read(authProvider);
    final syncEngine = ref.read(syncEngineProvider);

    final dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
    final saleNumber = 'SL-$dateStr-${1000 + (widget.totalAmount.toInt() % 8999)}';
    final fiscalCode = session?.isEfrisEnrolled == true ? 'FC-${const Uuid().v4().substring(0, 8).toUpperCase()}' : null;

    final saleId = 'sl_${DateTime.now().millisecondsSinceEpoch}';
    final salePayload = {
      'id': saleId,
      'offlineId': saleId,
      'saleNumber': saleNumber,
      'customerId': _customerNameController.text.isNotEmpty ? 'cust_walkin' : null,
      'customerName': _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Walk-in Customer',
      'customerPhone': _customerPhoneController.text,
      'items': widget.cartItems.map((ci) => {
        'productId': ci.product.id,
        'productName': ci.product.name,
        'quantity': ci.quantity,
        'unitPrice': ci.product.sellPrice,
        'subtotal': ci.subtotal,
        'costPrice': ci.product.costPrice,
        'taxAmount': ci.taxAmount,
      }).toList(),
      'subtotalAmount': widget.totalAmount / 1.18,
      'taxAmount': widget.totalAmount - (widget.totalAmount / 1.18),
      'discountAmount': 0.0,
      'totalAmount': widget.totalAmount,
      'paidAmount': paid,
      'dueAmount': due,
      'paymentMethod': _isCreditSale ? 'credit' : _paymentMethod,
      'momoReference': _momoRefController.text,
      'isCredit': _isCreditSale || due > 0,
      'dueDate': _isCreditSale ? DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch : null,
    };

    // Save to persistent database
    final localSale = LocalSaleData(
      id: saleId,
      businessId: session?.businessId ?? 'biz_default',
      saleNumber: saleNumber,
      customerId: _customerNameController.text.isNotEmpty ? 'cust_walkin' : null,
      customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Walk-in Customer',
      customerPhone: _customerPhoneController.text,
      itemsJson: jsonEncode(salePayload['items']),
      subtotalAmount: widget.totalAmount / 1.18,
      taxAmount: widget.totalAmount - (widget.totalAmount / 1.18),
      discountAmount: 0.0,
      totalAmount: widget.totalAmount,
      paidAmount: paid,
      dueAmount: due,
      paymentStatus: due <= 0 ? 'paid' : (paid > 0 ? 'partial' : 'unpaid'),
      paymentMethod: _isCreditSale ? 'credit' : _paymentMethod,
      momoReference: _momoRefController.text,
      isCredit: _isCreditSale || due > 0,
      dueDate: _isCreditSale ? DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch : null,
      efrisFiscalCode: fiscalCode,
      deviceId: session?.deviceId ?? 'device-001',
      localTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    ref.read(salesProvider.notifier).recordSale(localSale);

    // Decrement stock in database
    for (final ci in widget.cartItems) {
      ref.read(databaseProvider).updateProductStock(ci.product.id, -ci.quantity.toDouble());
    }

    // Record credit debtor if credit sale or partial payment
    if (_isCreditSale || due > 0) {
      final custName = _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Credit Customer';
      final custPhone = _customerPhoneController.text.isNotEmpty ? _customerPhoneController.text : '0700000000';
      final debtor = LocalDebtorData(
        id: 'd_${DateTime.now().millisecondsSinceEpoch}',
        businessId: session?.businessId ?? 'biz_default',
        name: custName,
        phone: custPhone,
        balanceOwed: due,
        creditLimit: 500000,
        lastSaleDate: DateTime.now().millisecondsSinceEpoch,
      );
      ref.read(debtorsProvider.notifier).addDebtor(debtor);
    }

    // Enqueue to offline sync queue
    syncEngine?.enqueueMutation(
      entityType: 'sale',
      action: 'create',
      payload: salePayload,
    );

    widget.onCheckoutComplete();
    Navigator.pop(context);

    // Open Shareable Thermal Receipt Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ReceiptShareScreen(
          saleNumber: saleNumber,
          customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : 'Walk-in Customer',
          customerPhone: _customerPhoneController.text,
          totalAmount: widget.totalAmount,
          paidAmount: paid,
          dueAmount: due,
          paymentMethod: _isCreditSale ? 'credit' : _paymentMethod,
          momoReference: _momoRefController.text,
          fiscalCode: fiscalCode,
          items: widget.cartItems,
        ),
      ),
    );
  }

  /// Opens a 3D spinning wheel to pick the payment method.
  void _showPaymentWheelPicker() {
    final paymentItems = [
      WheelPickerItem<String>(
        value: UgandaPresets.paymentMtnMomo,
        title: 'MTN MoMo',
        subtitle: 'Mobile Money · Uganda',
        icon: Icons.phone_android_rounded,
        color: AppColors.mtnYellow,
      ),
      WheelPickerItem<String>(
        value: UgandaPresets.paymentAirtelMoney,
        title: 'Airtel Money',
        subtitle: 'Mobile Money · Uganda',
        icon: Icons.send_to_mobile_rounded,
        color: AppColors.airtelRed,
      ),
      WheelPickerItem<String>(
        value: UgandaPresets.paymentCash,
        title: 'Cash',
        subtitle: 'Physical UGX',
        icon: Icons.payments_rounded,
        color: AppColors.cashGreen,
      ),
      WheelPickerItem<String>(
        value: UgandaPresets.paymentBank,
        title: 'Bank Transfer',
        subtitle: 'EFT / RTGS',
        icon: Icons.account_balance_rounded,
        color: AppColors.primaryForest,
      ),
    ];

    final currentIndex = paymentItems.indexWhere((item) => item.value == _paymentMethod);
    int selectedIndex = currentIndex >= 0 ? currentIndex : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurface
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Spin to select · tap Confirm to apply',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              SpinningWheelPicker<String>(
                items: paymentItems,
                initialIndex: selectedIndex,
                height: 260,
                itemExtent: 68,
                onItemSelected: (index) {
                  setModalState(() => selectedIndex = index);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _paymentMethod = paymentItems[selectedIndex].value;
                    });
                    Navigator.pop(ctx);
                  },
                  icon: Icon(paymentItems[selectedIndex].icon),
                  label: Text(
                    'Pay with ${paymentItems[selectedIndex].title}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paymentItems[selectedIndex].color,
                    foregroundColor: paymentItems[selectedIndex].value == UgandaPresets.paymentMtnMomo
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ref.tr('complete_sale'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ],
            ),
            const Divider(),

            // Total banner with POS cart illustration
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/pos_cart_illustration.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ref.tr('total_payable')}:',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          CurrencyFormatter.format(widget.totalAmount),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Credit Sale Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _isCreditSale ? AppColors.creditAmber.withValues(alpha: 0.12) : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _isCreditSale ? AppColors.creditAmber : AppColors.borderLight),
              ),
              child: SwitchListTile(
                title: Text(ref.tr('sell_on_credit'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: Text(ref.tr('add_to_debtor_book'), style: const TextStyle(fontSize: 12)),
                value: _isCreditSale,
                activeThumbColor: AppColors.creditAmber,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _isCreditSale = val;
                    if (val) {
                      _paidAmountController.text = '0';
                    } else {
                      _paidAmountController.text = widget.totalAmount.toInt().toString();
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 14),

            // Customer details if Credit Sale
            if (_isCreditSale) ...[
              TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: '${ref.tr('customer_name')} *',
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _customerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: '${ref.tr('customer_phone')} *',
                  prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _paidAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: ref.tr('initial_deposit'),
                  prefixIcon: const Icon(Icons.money_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (!_isCreditSale) ...[
              Text(ref.tr('select_payment_method'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 8),

              // Payment options with distinct visual branding
              Row(
                children: [
                  _buildPaymentCard(
                    label: 'MTN MoMo',
                    value: UgandaPresets.paymentMtnMomo,
                    color: AppColors.mtnYellow,
                    textColor: Colors.black,
                    icon: Icons.phone_android_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentCard(
                    label: 'Airtel Money',
                    value: UgandaPresets.paymentAirtelMoney,
                    color: AppColors.airtelRed,
                    textColor: Colors.white,
                    icon: Icons.send_to_mobile_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildPaymentCard(
                    label: ref.tr('pay_cash'),
                    value: UgandaPresets.paymentCash,
                    color: AppColors.cashGreen,
                    textColor: Colors.white,
                    icon: Icons.payments_rounded,
                  ),
                ],
              ),

              // Wheel picker shortcut
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showPaymentWheelPicker,
                  icon: const Text('🎡', style: TextStyle(fontSize: 14)),
                  label: const Text(
                    'Pick via Wheel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryForest,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: StadiumBorder(
                      side: BorderSide(color: AppColors.primaryForest.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Quick UGX shortcut chips
              Row(
                children: [
                  _buildQuickMoneyChip('Exact', widget.totalAmount),
                  const SizedBox(width: 6),
                  _buildQuickMoneyChip('+5k', widget.totalAmount + 5000),
                  const SizedBox(width: 6),
                  _buildQuickMoneyChip('+10k', widget.totalAmount + 10000),
                  const SizedBox(width: 6),
                  _buildQuickMoneyChip('+50k', widget.totalAmount + 50000),
                ],
              ),
              const SizedBox(height: 12),

              if (_paymentMethod == UgandaPresets.paymentMtnMomo || _paymentMethod == UgandaPresets.paymentAirtelMoney) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => ReceivePaymentSheet(
                          amount: widget.totalAmount,
                          initialPhone: _customerPhoneController.text,
                          customerName: _customerNameController.text,
                          onPaymentSuccess: (refId, method) {
                            setState(() {
                              _momoRefController.text = refId;
                            });
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_to_mobile_rounded, size: 18),
                    label: Text(
                      'Push ${_paymentMethod == UgandaPresets.paymentMtnMomo ? 'MTN MoMo' : 'Airtel'} PIN Prompt',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _momoRefController,
                  decoration: InputDecoration(
                    labelText: ref.tr('momo_ref_label'),
                    hintText: 'e.g. 2489012389',
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                    suffixIcon: TextButton(
                      onPressed: () {
                        setState(() {
                          _momoRefController.text = 'TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
                        });
                      },
                      child: Text(ref.tr('generate_ref'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _processPayment,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  _isCreditSale ? ref.tr('confirm_credit_sale') : ref.tr('complete_sale_receipt'),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMoneyChip(String label, double amount) {
    return Expanded(
      child: InkWell(
        onTap: () => _quickSetPaid(amount),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryForest),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard({
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.borderLight,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? textColor : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? textColor : AppColors.textMain,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
