import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/database/app_database.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  void _showAddEditCustomerDialog([LocalCustomerData? existing]) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing != null ? PhoneFormatter.formatDisplay(existing.phone) : '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final limitCtrl = TextEditingController(text: existing != null ? existing.creditLimit.toInt().toString() : '300000');
    final debtCtrl = TextEditingController(text: existing != null ? existing.currentDebt.toInt().toString() : '0');
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
                    isEditing ? 'Edit Customer' : 'Add New Customer',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Full Name *', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (e.g. 0772123456) *',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Location / Market Stall', prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: limitCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Credit Limit (UGX)'),
                    ),
                  ),
                  if (!isEditing) const SizedBox(width: 10),
                  if (!isEditing)
                    Expanded(
                      child: TextField(
                        controller: debtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Initial Debt (UGX)'),
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
                    final rawPhone = phoneCtrl.text.trim();
                    final limit = double.tryParse(limitCtrl.text.trim()) ?? 300000;
                    final initialDebt = double.tryParse(debtCtrl.text.trim()) ?? 0;
                    final session = ref.read(authProvider);

                    if (name.isEmpty || rawPhone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter customer name and valid phone number')),
                      );
                      return;
                    }

                    final normalizedPhone = PhoneFormatter.normalize(rawPhone);

                    if (isEditing) {
                      final updated = existing.copyWith(
                        name: name,
                        phone: normalizedPhone,
                        address: addressCtrl.text.trim(),
                        creditLimit: limit,
                      );
                      ref.read(customersProvider.notifier).updateCustomer(updated);
                    } else {
                      final newCust = LocalCustomerData(
                        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                        businessId: session?.businessId ?? 'biz_default',
                        name: name,
                        phone: normalizedPhone,
                        address: addressCtrl.text.trim(),
                        creditLimit: limit,
                        currentDebt: initialDebt,
                        createdAt: DateTime.now().millisecondsSinceEpoch,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      );
                      ref.read(customersProvider.notifier).addCustomer(newCust);
                    }

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Customer updated' : 'Customer added successfully')),
                    );
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Save Customer', style: const TextStyle(fontWeight: FontWeight.w900)),
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
    final customers = ref.watch(customersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = customers.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.phone.contains(_searchQuery) ||
          (c.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      if (!matchesSearch) return false;

      if (_selectedFilter == 'Debtors') return c.currentDebt > 0;
      return true;
    }).toList();

    final totalReceivables = customers.fold<double>(0, (sum, c) => sum + c.currentDebt);
    final debtorsCount = customers.where((c) => c.currentDebt > 0).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Customers & Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Customer',
            onPressed: () => _showAddEditCustomerDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Receivables Card
          Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Customer Debt', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalReceivables),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$debtorsCount with Debt',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by customer name or phone...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: ['All', 'Debtors'].map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600)),
                    selected: isSelected,
                    selectedColor: AppColors.primaryForest,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? AppColors.darkTextMain : AppColors.textMain)),
                    onSelected: (_) => setState(() => _selectedFilter = f),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 4),

          // Customer List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text(
                          customers.isEmpty ? 'No customers added yet' : 'No matching customers found',
                          style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final customer = filtered[index];
                      final hasDebt = customer.currentDebt > 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => CustomerDetailScreen(customer: customer),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: hasDebt ? Colors.amber.shade50 : AppColors.surfaceMuted,
                            child: Icon(
                              hasDebt ? Icons.account_balance_wallet_rounded : Icons.person_rounded,
                              color: hasDebt ? AppColors.creditAmber : AppColors.primaryForest,
                            ),
                          ),
                          title: Text(
                            customer.name,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                          subtitle: Text(
                            PhoneFormatter.formatDisplay(customer.phone),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                hasDebt ? CurrencyFormatter.format(customer.currentDebt) : 'UGX 0',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: hasDebt ? AppColors.danger : AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasDebt ? 'Balance Due' : 'Cleared',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: hasDebt ? AppColors.danger : AppColors.success,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCustomerDialog(),
        backgroundColor: AppColors.primaryForest,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Customer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }
}
