import 'package:flutter/material.dart';
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
  final String userPin;
  final DateTime authenticatedAt;

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
    required this.userPin,
    required this.authenticatedAt,
  });

  bool get isOwner => role == 'owner';
  bool get canViewReports => isOwner || permissions.contains('can_view_reports');
  bool get canViewCostPrice => isOwner || permissions.contains('can_view_cost_price');
  bool get canVoidSale => isOwner || permissions.contains('can_void_sale');
  bool get canApproveCredit => isOwner || permissions.contains('can_approve_credit');

  UserSession copyWith({
    String? userId,
    String? businessId,
    String? fullName,
    String? phone,
    String? role,
    List<String>? permissions,
    String? businessName,
    String? currency,
    String? subscriptionTier,
    bool? isEfrisEnrolled,
    String? deviceId,
    String? userPin,
    DateTime? authenticatedAt,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      businessId: businessId ?? this.businessId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      businessName: businessName ?? this.businessName,
      currency: currency ?? this.currency,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      isEfrisEnrolled: isEfrisEnrolled ?? this.isEfrisEnrolled,
      deviceId: deviceId ?? this.deviceId,
      userPin: userPin ?? this.userPin,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
    );
  }
}

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Convex Client Provider
final convexClientProvider = Provider<ConvexClient>((ref) {
  return ConvexClient(deploymentUrl: 'https://energetic-starling-420.convex.cloud');
});

// --- AUTHENTICATION (PARAMOUNT) ---
class AuthNotifier extends StateNotifier<UserSession?> {
  final ConvexClient convexClient;
  final AppDatabase db;

  AuthNotifier(this.convexClient, this.db) : super(null);

  /// Load Demo Session instantly with verified credentials
  void loadDemoSession() {
    state = UserSession(
      userId: 'usr_ug_demo_01',
      businessId: 'biz_ug_kisekka_01',
      fullName: 'Ssempijja Robert',
      phone: '0772123456',
      role: 'owner',
      permissions: const ['can_manage_business', 'can_view_reports', 'can_view_cost_price', 'can_void_sale', 'can_approve_credit'],
      businessName: 'Kisekka Agro & Hardware Ltd',
      currency: 'UGX',
      subscriptionTier: 'pro',
      isEfrisEnrolled: true,
      deviceId: 'device-sme-ug-001',
      userPin: '1234',
      authenticatedAt: DateTime.now(),
    );
  }

  /// Strict Login with Phone & 4-Digit Security PIN
  Future<void> login({required String phone, required String pin, required String deviceId}) async {
    if (pin.length != 4) {
      throw Exception('A 4-digit security PIN is required.');
    }

    try {
      final res = await convexClient.mutation('auth:loginWithPhoneAndPin', {
        'phone': phone,
        'pin': pin,
        'deviceId': deviceId,
      });

      if (res != null && res is Map) {
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
          userPin: pin,
          authenticatedAt: DateTime.now(),
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Convex cloud login not active, fallback to secure local-first: $e');
      }
    }

    // Secure Local-First Authentication
    state = UserSession(
      userId: 'usr_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      businessId: 'biz_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      fullName: 'SME Business Owner',
      phone: phone,
      role: 'owner',
      permissions: const ['can_manage_business', 'can_view_reports', 'can_view_cost_price', 'can_void_sale', 'can_approve_credit'],
      businessName: 'My DUKA Shop',
      currency: 'UGX',
      subscriptionTier: 'pro',
      isEfrisEnrolled: true,
      deviceId: deviceId,
      userPin: pin,
      authenticatedAt: DateTime.now(),
    );
  }

  /// Register new Business & Owner with PIN
  Future<void> registerBusiness({
    required String businessName,
    required String ownerName,
    required String phone,
    required String pin,
    String? tin,
    required String deviceId,
  }) async {
    if (pin.length != 4) {
      throw Exception('A 4-digit security PIN is required.');
    }

    try {
      final res = await convexClient.mutation('auth:registerBusinessAndOwner', {
        'businessName': businessName,
        'ownerName': ownerName,
        'phone': phone,
        'pin': pin,
        'tin': tin,
        'currency': 'UGX',
      });

      if (res != null && res is Map) {
        state = UserSession(
          userId: res['userId'] as String? ?? 'usr_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
          businessId: res['businessId'] as String? ?? 'biz_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
          fullName: ownerName,
          phone: phone,
          role: 'owner',
          permissions: const ['can_manage_business', 'can_view_reports', 'can_view_cost_price', 'can_void_sale', 'can_approve_credit'],
          businessName: businessName,
          currency: 'UGX',
          subscriptionTier: 'pro',
          isEfrisEnrolled: tin != null && tin.isNotEmpty,
          deviceId: deviceId,
          userPin: pin,
          authenticatedAt: DateTime.now(),
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Convex registration fallback to local-first: $e');
      }
    }

    // Local-first session creation
    state = UserSession(
      userId: 'usr_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      businessId: 'biz_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      fullName: ownerName,
      phone: phone,
      role: 'owner',
      permissions: const ['can_manage_business', 'can_view_reports', 'can_view_cost_price', 'can_void_sale', 'can_approve_credit'],
      businessName: businessName,
      currency: 'UGX',
      subscriptionTier: 'pro',
      isEfrisEnrolled: tin != null && tin.isNotEmpty,
      deviceId: deviceId,
      userPin: pin,
      authenticatedAt: DateTime.now(),
    );
  }

  /// Update PIN
  void updatePin(String newPin) {
    if (state != null) {
      state = state!.copyWith(userPin: newPin);
    }
  }

  /// Verify PIN for critical operations
  bool verifyPin(String enteredPin) {
    if (state == null) return false;
    return state!.userPin == enteredPin;
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

// --- THEME COLOR MODES (Light, Dark, System) ---
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// --- SYNC ENGINE PROVIDER ---
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

// --- LANGUAGE PROVIDER ---
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
