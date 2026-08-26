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
  bool _isSignUp = false;
  final TextEditingController _phoneController = TextEditingController(text: '0772123456');
  final TextEditingController _pinController = TextEditingController(text: '1234');
  final TextEditingController _businessNameController = TextEditingController(text: 'Kisekka Agro & Hardware');
  final TextEditingController _ownerNameController = TextEditingController(text: 'Ssempijja Robert');
  final TextEditingController _tinController = TextEditingController(text: '1004928374');

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
        _errorMessage = 'Please enter a valid Ugandan phone number (e.g. 0770000000)';
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
      if (_isSignUp) {
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
          _errorMessage = 'Authentication: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062319), // Deep luxury emerald background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Brand Hero with Gold Accent
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/duka_logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ref.tr('app_name'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 30,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ref.tr('app_tagline'),
                    style: const TextStyle(fontSize: 12, color: AppColors.goldLight, fontWeight: FontWeight.w700),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form Sheet Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSignUp ? ref.tr('signup_title') : ref.tr('signin_title'),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp ? ref.tr('signup_subtitle') : ref.tr('signin_subtitle'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    if (_isSignUp) ...[
                      TextField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: '${ref.tr('shop_name')} *',
                          prefixIcon: const Icon(Icons.store_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ownerNameController,
                        decoration: InputDecoration(
                          labelText: '${ref.tr('owner_name')} *',
                          prefixIcon: const Icon(Icons.person_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tinController,
                        decoration: InputDecoration(
                          labelText: ref.tr('tin_label'),
                          prefixIcon: const Icon(Icons.verified_rounded, size: 20),
                          hintText: 'e.g. 1004928374',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: '${ref.tr('phone_label')} *',
                        prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                        hintText: '0770000000',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: InputDecoration(
                        labelText: '${ref.tr('pin_label')} *',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _isSignUp ? ref.tr('create_business_btn') : ref.tr('signin_btn'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Demo 1-Tap Login
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(authProvider.notifier).loadDemoSession();
                        },
                        icon: const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.accentGold),
                        label: const Text(
                          '⚡ Quick Demo Access (Kisekka Agro)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primaryForest),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryForest, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isSignUp ? ref.tr('switch_to_signin') : ref.tr('switch_to_signup'),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryForest, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
