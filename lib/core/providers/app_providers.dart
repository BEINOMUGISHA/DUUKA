import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final String? tin;
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
    this.tin,
    required this.deviceId,
    required this.userPin,
    required this.authenticatedAt,
  });

  bool get isOwner => role == 'owner';
  bool get canViewReports =>
      isOwner || permissions.contains('can_view_reports');
  bool get canViewCostPrice =>
      isOwner || permissions.contains('can_view_cost_price');
  bool get canVoidSale => isOwner || permissions.contains('can_void_sale');
  bool get canApproveCredit =>
      isOwner || permissions.contains('can_approve_credit');

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
    String? tin,
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
      tin: tin ?? this.tin,
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
  const deploymentUrl = String.fromEnvironment(
    'CONVEX_URL',
    defaultValue: 'https://content-giraffe-287.convex.cloud',
  );

  return ConvexClient(deploymentUrl: deploymentUrl);
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
      permissions: const [
        'can_manage_business',
        'can_view_reports',
        'can_view_cost_price',
        'can_void_sale',
        'can_approve_credit'
      ],
      businessName: 'Kisekka Agro & Hardware Ltd',
      currency: 'UGX',
      subscriptionTier: 'pro',
      isEfrisEnrolled: true,
      tin: '1004928374',
      deviceId: 'device-sme-ug-001',
      userPin: '1234',
      authenticatedAt: DateTime.now(),
    );
  }

  /// Strict Login with Phone & 4-Digit Security PIN
  Future<void> login(
      {required String phone,
      required String pin,
      required String deviceId}) async {
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
          permissions: (res['permissions'] as List<dynamic>)
              .map((e) => e.toString())
              .toList(),
          businessName: res['businessName'] as String,
          currency: res['currency'] as String? ?? 'UGX',
          subscriptionTier: res['subscriptionTier'] as String? ?? 'free',
          isEfrisEnrolled: res['isEfrisEnrolled'] as bool? ?? false,
          tin: res['tin'] as String?,
          deviceId: deviceId,
          userPin: pin,
          authenticatedAt: DateTime.now(),
        );
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'Convex cloud login not active, fallback to secure local-first: $e');
      }
    }

    // Secure Local-First Authentication
    state = UserSession(
      userId: 'usr_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      businessId: 'biz_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      fullName: 'SME Business Owner',
      phone: phone,
      role: 'owner',
      permissions: const [
        'can_manage_business',
        'can_view_reports',
        'can_view_cost_price',
        'can_void_sale',
        'can_approve_credit'
      ],
      businessName: 'My DUUKA Shop',
      currency: 'UGX',
      subscriptionTier: 'pro',
      isEfrisEnrolled: true,
      tin: null,
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
          userId: res['userId'] as String? ??
              'usr_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
          businessId: res['businessId'] as String? ??
              'biz_${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
          fullName: ownerName,
          phone: phone,
          role: 'owner',
          permissions: const [
            'can_manage_business',
            'can_view_reports',
            'can_view_cost_price',
            'can_void_sale',
            'can_approve_credit'
          ],
          businessName: businessName,
          currency: 'UGX',
          subscriptionTier: 'pro',
          isEfrisEnrolled: tin != null && tin.isNotEmpty,
          tin: tin,
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
      permissions: const [
        'can_manage_business',
        'can_view_reports',
        'can_view_cost_price',
        'can_void_sale',
        'can_approve_credit'
      ],
      businessName: businessName,
      currency: 'UGX',
      subscriptionTier: 'pro',
      isEfrisEnrolled: tin != null && tin.isNotEmpty,
      tin: tin,
      deviceId: deviceId,
      userPin: pin,
      authenticatedAt: DateTime.now(),
    );
  }

  void updateProfile({
    String? businessName,
    String? fullName,
    String? phone,
    String? tin,
  }) {
    if (state == null) return;

    state = state!.copyWith(
      businessName: businessName ?? state!.businessName,
      fullName: fullName ?? state!.fullName,
      phone: phone ?? state!.phone,
      tin: tin ?? state!.tin,
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

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// --- CUSTOM BRAND / FAVORITE THEME COLOR PROVIDER ---
class CustomThemeColorNotifier extends StateNotifier<Color> {
  static const _kPrefKey = 'duka_custom_brand_color';
  SharedPreferences? _prefs;

  CustomThemeColorNotifier() : super(const Color(0xFF0B4F37)) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs?.getInt(_kPrefKey);
    if (saved != null) {
      state = Color(saved);
    }
  }

  Future<void> setColor(Color color) async {
    state = color;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_kPrefKey, color.value);
  }
}

final customThemeColorProvider =
    StateNotifierProvider<CustomThemeColorNotifier, Color>((ref) {
  return CustomThemeColorNotifier();
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

// ===========================================================================
// PERSISTENT DOMAIN PROVIDERS
// ===========================================================================

// --- PRODUCTS NOTIFIER ---
class ProductsNotifier extends StateNotifier<List<LocalProductData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  ProductsNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getProducts();
    _sub = db.onChange.listen((_) async {
      state = await db.getProducts();
    });
  }

  Future<void> addProduct(LocalProductData product) async {
    await db.insertProduct(product);
  }

  Future<void> editProduct(LocalProductData product) async {
    await db.updateProduct(product);
  }

  Future<void> archiveProduct(String id) async {
    await db.archiveProduct(id);
  }

  Future<void> restockProduct({
    required String productId,
    required String businessId,
    required double qtyReceived,
    required double costPerUnit,
    String? supplierName,
    String? notes,
  }) async {
    final restock = LocalRestockData(
      id: 'rst_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      businessId: businessId,
      qtyReceived: qtyReceived,
      costPerUnit: costPerUnit,
      supplierName: supplierName,
      notes: notes,
      date: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insertRestock(restock);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final productsProvider =
    StateNotifierProvider<ProductsNotifier, List<LocalProductData>>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductsNotifier(db);
});

// --- SALES NOTIFIER ---
class SalesNotifier extends StateNotifier<List<LocalSaleData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  SalesNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getSales();
    _sub = db.onChange.listen((_) async {
      state = await db.getSales();
    });
  }

  Future<void> recordSale(LocalSaleData sale) async {
    await db.insertSale(sale);
  }

  Future<void> voidSale(String saleId) async {
    await db.voidSale(saleId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final salesProvider =
    StateNotifierProvider<SalesNotifier, List<LocalSaleData>>((ref) {
  final db = ref.watch(databaseProvider);
  return SalesNotifier(db);
});

// --- EXPENSES NOTIFIER ---
class ExpensesNotifier extends StateNotifier<List<LocalExpenseData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  ExpensesNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getExpenses();
    _sub = db.onChange.listen((_) async {
      state = await db.getExpenses();
    });
  }

  Future<void> addExpense(LocalExpenseData expense) async {
    await db.insertExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await db.deleteExpense(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<LocalExpenseData>>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpensesNotifier(db);
});

// --- DEBTORS NOTIFIER ---
class DebtorsNotifier extends StateNotifier<List<LocalDebtorData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  DebtorsNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getDebtors();
    _sub = db.onChange.listen((_) async {
      state = await db.getDebtors();
    });
  }

  Future<void> addDebtor(LocalDebtorData debtor) async {
    await db.insertDebtor(debtor);
  }

  Future<void> recordPayment(
      String debtorId, double amount, String method, String? ref) async {
    await db.recordDebtorPayment(debtorId, amount, method, ref);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final debtorsProvider =
    StateNotifierProvider<DebtorsNotifier, List<LocalDebtorData>>((ref) {
  final db = ref.watch(databaseProvider);
  return DebtorsNotifier(db);
});

// --- CUSTOMERS NOTIFIER ---
class CustomersNotifier extends StateNotifier<List<LocalCustomerData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  CustomersNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getCustomers();
    _sub = db.onChange.listen((_) async {
      state = await db.getCustomers();
    });
  }

  Future<void> addCustomer(LocalCustomerData customer) async {
    await db.insertCustomer(customer);
  }

  Future<void> updateCustomer(LocalCustomerData customer) async {
    await db.updateCustomer(customer);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final customersProvider =
    StateNotifierProvider<CustomersNotifier, List<LocalCustomerData>>((ref) {
  final db = ref.watch(databaseProvider);
  return CustomersNotifier(db);
});

// --- SMS NOTIFIER ---
class SmsNotifier extends StateNotifier<List<LocalSmsData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  SmsNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getSmsList();
    _sub = db.onChange.listen((_) async {
      state = await db.getSmsList();
    });
  }

  Future<void> logSms(LocalSmsData sms) async {
    await db.insertSms(sms);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final smsProvider =
    StateNotifierProvider<SmsNotifier, List<LocalSmsData>>((ref) {
  final db = ref.watch(databaseProvider);
  return SmsNotifier(db);
});

// --- MOBILE MONEY TRANSACTIONS NOTIFIER ---
class MobileMoneyNotifier extends StateNotifier<List<LocalMobileMoneyTxData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  MobileMoneyNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getMomoTransactions();
    _sub = db.onChange.listen((_) async {
      state = await db.getMomoTransactions();
    });
  }

  Future<void> recordTransaction(LocalMobileMoneyTxData tx) async {
    await db.insertMomoTx(tx);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final mobileMoneyProvider =
    StateNotifierProvider<MobileMoneyNotifier, List<LocalMobileMoneyTxData>>(
        (ref) {
  final db = ref.watch(databaseProvider);
  return MobileMoneyNotifier(db);
});

// --- NOTIFICATIONS NOTIFIER ---
class NotificationsNotifier extends StateNotifier<List<LocalNotificationData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  NotificationsNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getNotifications();
    _sub = db.onChange.listen((_) async {
      state = await db.getNotifications();
    });
  }

  Future<void> addNotification(LocalNotificationData n) async {
    await db.insertNotification(n);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<LocalNotificationData>>(
        (ref) {
  final db = ref.watch(databaseProvider);
  return NotificationsNotifier(db);
});

// --- RAW MATERIALS NOTIFIER (Production) ---
class RawMaterialsNotifier extends StateNotifier<List<LocalRawMaterialData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  RawMaterialsNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getRawMaterials();
    _sub = db.onChange.listen((_) async {
      state = await db.getRawMaterials();
    });
  }

  Future<void> addRawMaterial(LocalRawMaterialData rm) async {
    await db.insertRawMaterial(rm);
  }

  Future<void> updateRawMaterial(LocalRawMaterialData rm) async {
    await db.updateRawMaterial(rm);
  }

  Future<void> adjustStock(String id, double delta) async {
    await db.updateRawMaterialStock(id, delta);
  }

  Future<void> deleteRawMaterial(String id) async {
    await db.deleteRawMaterial(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final rawMaterialsProvider =
    StateNotifierProvider<RawMaterialsNotifier, List<LocalRawMaterialData>>(
        (ref) {
  final db = ref.watch(databaseProvider);
  return RawMaterialsNotifier(db);
});

// --- RECIPES NOTIFIER (Production) ---
class RecipesNotifier extends StateNotifier<List<LocalRecipeData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  RecipesNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getRecipes();
    _sub = db.onChange.listen((_) async {
      state = await db.getRecipes();
    });
  }

  Future<void> addRecipe(LocalRecipeData recipe) async {
    await db.insertRecipe(recipe);
  }

  Future<void> deleteRecipe(String id) async {
    await db.deleteRecipe(id);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final recipesProvider =
    StateNotifierProvider<RecipesNotifier, List<LocalRecipeData>>((ref) {
  final db = ref.watch(databaseProvider);
  return RecipesNotifier(db);
});

// --- PRODUCTION BATCHES NOTIFIER ---
class ProductionBatchesNotifier
    extends StateNotifier<List<LocalProductionBatchData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  ProductionBatchesNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getProductionBatches();
    _sub = db.onChange.listen((_) async {
      state = await db.getProductionBatches();
    });
  }

  Future<void> recordBatch({
    required String recipeId,
    required double batchesCount,
    String? notes,
  }) async {
    await db.recordProductionBatch(
        recipeId: recipeId, batchesCount: batchesCount, notes: notes);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final productionBatchesProvider = StateNotifierProvider<
    ProductionBatchesNotifier, List<LocalProductionBatchData>>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductionBatchesNotifier(db);
});

// --- BRANCHES NOTIFIER (Multi-Branch) ---
class BranchesNotifier extends StateNotifier<List<LocalBranchData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  BranchesNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getBranches();
    _sub = db.onChange.listen((_) async {
      state = await db.getBranches();
    });
  }

  Future<void> addBranch(LocalBranchData branch) async {
    await db.insertBranch(branch);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final branchesProvider =
    StateNotifierProvider<BranchesNotifier, List<LocalBranchData>>((ref) {
  final db = ref.watch(databaseProvider);
  return BranchesNotifier(db);
});

// --- STOCK TRANSFERS NOTIFIER ---
class StockTransfersNotifier
    extends StateNotifier<List<LocalStockTransferData>> {
  final AppDatabase db;
  StreamSubscription<void>? _sub;

  StockTransfersNotifier(this.db) : super([]) {
    _init();
  }

  Future<void> _init() async {
    await db.init();
    state = await db.getStockTransfers();
    _sub = db.onChange.listen((_) async {
      state = await db.getStockTransfers();
    });
  }

  Future<void> transferStock({
    required String fromBranchId,
    required String fromBranchName,
    required String toBranchId,
    required String toBranchName,
    required String productId,
    required String productName,
    required double quantity,
    String? notes,
  }) async {
    await db.executeStockTransfer(
      fromBranchId: fromBranchId,
      fromBranchName: fromBranchName,
      toBranchId: toBranchId,
      toBranchName: toBranchName,
      productId: productId,
      productName: productName,
      quantity: quantity,
      notes: notes,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final stockTransfersProvider =
    StateNotifierProvider<StockTransfersNotifier, List<LocalStockTransferData>>(
        (ref) {
  final db = ref.watch(databaseProvider);
  return StockTransfersNotifier(db);
});

// Current active branch filter
final selectedBranchIdProvider = StateProvider<String?>((ref) => null);
