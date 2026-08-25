import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../network/convex_client.dart';
import '../sync/sync_engine.dart';
import '../localization/translations.dart';

// User & Business Session Model
class UserSession {
  final String userId;
  final String businessId;
  final String fullName;
  final String phone;
  final String role; // "owner", "manager", "staff"
  final List<String> permissions;
  final String businessName;
  final String currency;
  final String subscriptionTier;
  final bool isEfrisEnrolled;
  final String deviceId;

  const UserSession({
    required this.userId,
    required this.businessId,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.permissions,
    required this.businessName,
    required this.currency,
    required this.subscriptionTier,
    required this.isEfrisEnrolled,
    required this.deviceId,
  });

  bool get isOwner => role == 'owner';
  bool get canViewReports => isOwner || permissions.contains('can_view_reports');
  bool get canViewCostPrice => isOwner || permissions.contains('can_view_cost_price');
  bool get canVoidSale => isOwner || permissions.contains('can_void_sale');
  bool get canApproveCredit => isOwner || permissions.contains('can_approve_credit');
}

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Convex Client Provider
final convexClientProvider = Provider<ConvexClient>((ref) {
  // Default development URL or configured backend
  return ConvexClient(deploymentUrl: 'https://energetic-starling-420.convex.cloud');
});

// Auth State Notifier
class AuthNotifier extends StateNotifier<UserSession?> {
  final ConvexClient convexClient;
  final AppDatabase db;

  AuthNotifier(this.convexClient, this.db) : super(null) {
    _loadDemoSession();
  }

  void _loadDemoSession() {
    // Initial default session for instant preview/testing
    state = const UserSession(
      userId: 'usr_ug_demo_01',
      businessId: 'biz_ug_kisekka_01',
      fullName: 'Ssempijja Robert',
      phone: '+256772123456',
      role: 'owner',
      permissions: ['can_manage_business', 'can_view_reports', 'can_view_cost_price', 'can_void_sale', 'can_approve_credit'],
      businessName: 'Kisekka Agro & Hardware Ltd',
      currency: 'UGX',
      subscriptionTier: 'pro',
      isEfrisEnrolled: true,
      deviceId: 'device-sme-ug-001',
    );
  }

  Future<void> login({required String phone, required String pin, required String deviceId}) async {
    try {
      final res = await convexClient.mutation('auth:loginWithPhoneAndPin', {
        'phone': phone,
        'pin': pin,
        'deviceId': deviceId,
      });

      state = UserSession(
        userId: res['userId'] as String,
        businessId: res['businessId'] as String,
        fullName: res['fullName'] as String,
        phone: res['phone'] as String,
        role: res['role'] as String,
        permissions: (res['permissions'] as List<dynamic>).map((e) => e.toString()).toList(),
        businessName: res['businessName'] as String,
        currency: res['currency'] as String? ?? 'UGX',
        subscriptionTier: res['subscriptionTier'] as String? ?? 'free',
        isEfrisEnrolled: res['isEfrisEnrolled'] as bool? ?? false,
        deviceId: deviceId,
      );
    } catch (e) {
      if (kDebugMode) print('Login failed: $e');
      rethrow;
    }
  }

  void logout() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserSession?>((ref) {
  final client = ref.watch(convexClientProvider);
  final db = ref.watch(databaseProvider);
  return AuthNotifier(client, db);
});

// Sync Engine Provider
final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final session = ref.watch(authProvider);
  if (session == null) return null;

  final db = ref.watch(databaseProvider);
  final client = ref.watch(convexClientProvider);

  final engine = SyncEngine(
    db: db,
    convexClient: client,
    businessId: session.businessId,
    userId: session.userId,
    deviceId: session.deviceId,
  );

  ref.onDispose(() => engine.dispose());
  return engine;
});

// Language Provider ('en' as default, 'lg' for Luganda as 2nd main, 'rn' for Runyankole)
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en');

  void setLanguage(String lang) {
    state = lang;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

// Translation Extension on WidgetRef
extension TranslationRef on WidgetRef {
  String tr(String key) {
    final lang = watch(languageProvider);
    return AppTranslations.tr(key, lang);
  }
}

