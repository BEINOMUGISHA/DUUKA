import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  int _activeTab = 0; // 0 = Sign In, 1 = Register, 2 = Instant Demo

  final TextEditingController _phoneController = TextEditingController(text: '0772123456');
  final TextEditingController _pinController = TextEditingController(text: '1234');
  final TextEditingController _businessNameController = TextEditingController(text: 'Kisekka Agro & Hardware');
  final TextEditingController _ownerNameController = TextEditingController(text: 'Ssempijja Robert');
  final TextEditingController _tinController = TextEditingController(text: '1004928374');

  bool _obscurePin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _tinController.dispose();
    super.dispose();
  }

  void _loadDemoAccount({
    required String phone,
    required String pin,
    required String businessName,
    required String ownerName,
  }) {
    setState(() {
      _phoneController.text = phone;
      _pinController.text = pin;
      _businessNameController.text = businessName;
      _ownerNameController.text = ownerName;
      _activeTab = 0;
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('Loaded $ownerName ($businessName) credentials'),
      ),
    );
  }

  void _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    if (phone.isEmpty || phone.length < 9) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a valid Ugandan phone number (e.g. 0772123456)';
      });
      return;
    }

    if (pin.length != 4) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter a 4-digit security PIN';
      });
      return;
    }

    try {
      if (_activeTab == 1) {
        final bizName = _businessNameController.text.trim();
        final ownerName = _ownerNameController.text.trim();

        if (bizName.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please enter your Business / Shop name';
          });
          return;
        }

        await ref.read(authProvider.notifier).registerBusiness(
          businessName: bizName,
          ownerName: ownerName.isNotEmpty ? ownerName : 'Shop Owner',
          phone: phone,
          pin: pin,
          tin: _tinController.text.trim().isNotEmpty ? _tinController.text.trim() : null,
          deviceId: 'device-sme-001',
        );
      } else {
        await ref.read(authProvider.notifier).login(
          phone: phone,
          pin: pin,
          deviceId: 'device-sme-001',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentication Error: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF031A12), // Deep obsidian forest
              Color(0xFF0A3426),
              Color(0xFF062319),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? (size.width - 500) / 2 : 20,
                vertical: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Brand Logo & Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGold.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/duka_logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'DUKA',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO UG',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Uganda SME & Retail Operating System',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Glassmorphic Main Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 35,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Segmented Tab Switcher
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _buildTabItem(0, 'Sign In'),
                              _buildTabItem(1, 'Register Shop'),
                              _buildTabItem(2, '⚡ Quick Demo'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Error Banner if present
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: AppColors.danger, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // TAB 2: INSTANT DEMO ACCOUNTS
                        if (_activeTab == 2) ...[
                          const Text(
                            '1-Tap Demo Testing Accounts',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Select a preconfigured role to instantly explore all DUKA and UgaPOS capabilities:',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 14),

                          _buildDemoAccountCard(
                            role: 'Shop Owner / Admin',
                            name: 'Ssempijja Robert',
                            shop: 'Kisekka Agro & Hardware',
                            phone: '0772123456',
                            pin: '1234',
                            icon: Icons.admin_panel_settings_rounded,
                            badgeColor: AppColors.primaryForest,
                          ),
                          const SizedBox(height: 8),
                          _buildDemoAccountCard(
                            role: 'Branch Manager (Nakawa)',
                            name: 'Grace Namubiru',
                            shop: 'DUKA Branch 2 - Nakawa Market',
                            phone: '0788334455',
                            pin: '1234',
                            icon: Icons.storefront_rounded,
                            badgeColor: const Color(0xFF0284C7),
                          ),
                          const SizedBox(height: 8),
                          _buildDemoAccountCard(
                            role: 'Front Cashier (POS Till)',
                            name: 'Denis Kato',
                            shop: 'DUKA Main Store - Till 1',
                            phone: '0701998877',
                            pin: '1234',
                            icon: Icons.point_of_sale_rounded,
                            badgeColor: const Color(0xFFD97706),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.bolt_rounded),
                              label: const Text('Login to Selected Demo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            ),
                          ),
                        ] else ...[
                          // TAB 0 & 1: STANDARD FORM
                          if (_activeTab == 1) ...[
                            TextField(
                              controller: _businessNameController,
                              decoration: const InputDecoration(
                                labelText: 'Business / Shop Name *',
                                hintText: 'e.g. Mukono Agro Wholesalers',
                                prefixIcon: Icon(Icons.storefront_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _ownerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Owner / Manager Full Name *',
                                hintText: 'e.g. Mugisha Patrick',
                                prefixIcon: Icon(Icons.person_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _tinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'URA Tax TIN (Optional)',
                                hintText: 'e.g. 1004928374',
                                prefixIcon: Icon(Icons.account_balance_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Phone Input with Uganda Flag Prefix
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Uganda Phone Number *',
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🇺🇬', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 4),
                                    Text('+256', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                                    SizedBox(width: 6),
                                    Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 4-Digit Security PIN
                          TextField(
                            controller: _pinController,
                            obscureText: _obscurePin,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '4-Digit Security PIN *',
                              hintText: '••••',
                              counterText: '',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Submit Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _activeTab == 1 ? 'Register Business' : 'Open My DUKA POS',
                                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Offline & Security Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSecurityPill(Icons.wifi_off_rounded, 'Offline-First Local DB'),
                      const SizedBox(width: 10),
                      _buildSecurityPill(Icons.verified_user_rounded, 'URA EFRIS Compliant'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          _activeTab = index;
          _errorMessage = null;
        }),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? AppColors.primaryForest : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccountCard({
    required String role,
    required String name,
    required String shop,
    required String phone,
    required String pin,
    required IconData icon,
    required Color badgeColor,
  }) {
    final isSelected = _phoneController.text == phone;

    return InkWell(
      onTap: () => _loadDemoAccount(
        phone: phone,
        pin: pin,
        businessName: shop,
        ownerName: name,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? badgeColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? badgeColor : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: badgeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(role, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: badgeColor)),
                      const Spacer(),
                      Text('PIN: $pin', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(shop, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.goldLight, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
