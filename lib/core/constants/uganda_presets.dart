class UgandaExpenseCategory {
  final String id;
  final String labelEn;
  final String labelLg; // Luganda
  final String labelRn; // Runyankole
  final String icon;

  const UgandaExpenseCategory({
    required this.id,
    required this.labelEn,
    required this.labelLg,
    required this.labelRn,
    required this.icon,
  });
}

class UgandaPresets {
  static const String defaultCurrency = 'UGX';

  static const List<UgandaExpenseCategory> expenseCategories = [
    UgandaExpenseCategory(
      id: 'transport',
      labelEn: 'Transport (Boda/Taxi/Fuel)',
      labelLg: 'Entambula (Boda/Takisi)',
      labelRn: 'Entambura (Boda/Taxi)',
      icon: 'motorcycle',
    ),
    UgandaExpenseCategory(
      id: 'market_rent',
      labelEn: 'Market Rent / Dues (KCCA/Dues)',
      labelLg: 'Panyiiti / Emisolo gya katale',
      labelRn: 'Ekishanyiro / Obushohoro bwobutare',
      icon: 'store',
    ),
    UgandaExpenseCategory(
      id: 'airtime_data',
      labelEn: 'Airtime & Internet / Data',
      labelLg: 'Kkaadi y\'essimu / Yintaneeti',
      labelRn: 'Kadi y\'esimu / Intaneti',
      icon: 'phone',
    ),
    UgandaExpenseCategory(
      id: 'salaries_wages',
      labelEn: 'Staff Wages / Daily Pay',
      labelLg: 'Empeera y\'abakozi',
      labelRn: 'Empeera y\'abakozi',
      icon: 'people',
    ),
    UgandaExpenseCategory(
      id: 'stock_purchase',
      labelEn: 'Restock / Purchase Goods',
      labelLg: 'Okugula eby\'amaguzi (Sttoka)',
      labelRn: 'Kugura eby\'obutuzi',
      icon: 'inventory',
    ),
    UgandaExpenseCategory(
      id: 'food_lunch',
      labelEn: 'Staff Meals & Refreshments',
      labelLg: 'Emmere y\'abakozi / Ekyemisana',
      labelRn: 'Ebyokurya by\'abakozi',
      icon: 'restaurant',
    ),
    UgandaExpenseCategory(
      id: 'utilities',
      labelEn: 'Umeme (Power) & NWSC (Water)',
      labelLg: 'Amasannyalaze (Umeme) / Amazzi',
      labelRn: 'Amasanyarazi / Amaizi',
      icon: 'bolt',
    ),
    UgandaExpenseCategory(
      id: 'packaging_bags',
      labelEn: 'Kaveera / Packaging Bags & Boxes',
      labelLg: 'Obuveera n\'obukutiya',
      labelRn: 'Obuveera n\'ebishate',
      icon: 'shopping_bag',
    ),
    UgandaExpenseCategory(
      id: 'other',
      labelEn: 'Other Expense',
      labelLg: 'Ebirala',
      labelRn: 'Ebindi',
      icon: 'more_horiz',
    ),
  ];

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentMtnMomo = 'mtn_momo';
  static const String paymentAirtelMoney = 'airtel_money';
  static const String paymentBank = 'bank';
  static const String paymentCredit = 'credit';

  static String getPaymentLabel(String method, [String lang = 'en']) {
    switch (method) {
      case paymentCash:
        return lang == 'lg' ? 'Sente enkalu (Cash)' : lang == 'rn' ? "Esendi ez'enkaro" : 'Cash';
      case paymentMtnMomo:
        return 'MTN MoMo';
      case paymentAirtelMoney:
        return 'Airtel Money';
      case paymentBank:
        return 'Bank Transfer';
      case paymentCredit:
        return lang == 'lg' ? 'Ebbanja (Credit)' : lang == 'rn' ? 'Omwenda (Credit)' : 'Credit (Unpaid)';
      default:
        return method;
    }
  }
}
