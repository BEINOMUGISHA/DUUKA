import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  void _submit() async {
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        final client = ref.read(convexClientProvider);
        await client.mutation('auth:registerBusinessAndOwner', {
          'businessName': _businessNameController.text,
          'ownerName': _ownerNameController.text,
          'phone': _phoneController.text,
          'pin': _pinController.text,
          'tin': _tinController.text.isNotEmpty ? _tinController.text : null,
          'currency': 'UGX',
        });
      }

      await ref.read(authProvider.notifier).login(
        phone: _phoneController.text,
        pin: _pinController.text,
        deviceId: 'device-sme-001',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication: $e')),
        );
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
              const SizedBox(height: 30),
              // Brand Hero with Gold Accent
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentGold.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    ref.tr('app_name'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ref.tr('app_tagline'),
                    style: TextStyle(fontSize: 13, color: AppColors.goldLight, fontWeight: FontWeight.w700),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              const SizedBox(height: 30),

              // Form Sheet Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp ? ref.tr('signup_subtitle') : ref.tr('signin_subtitle'),
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.3),
                    ),
                    const SizedBox(height: 20),

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
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryForest,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                _isSignUp ? ref.tr('create_business_btn') : ref.tr('signin_btn'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp ? ref.tr('switch_to_signin') : ref.tr('switch_to_signup'),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryForest, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
