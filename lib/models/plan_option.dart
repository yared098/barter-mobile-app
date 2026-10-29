class PlanOption {
  final String id;
  final String label;
  final String description;
  final String currency;
  final int price;
  final String tier;
  final String? badgeKey;
  final bool highlighted;

  // ── NEW numeric fields from backend ──
  final int dailyCap;
  final int? periodLimit;
  final int? periodDays;

  const PlanOption({
    required this.id,
    required this.label,
    required this.price,
    required this.currency,
    required this.description,
    required this.tier,
    this.badgeKey,
    this.highlighted = false,
    this.dailyCap = 2,
    this.periodLimit,
    this.periodDays,
  });

  factory PlanOption.fromJson(Map<String, dynamic> j) {
    return PlanOption(
      id: j['id'] as String,
      label: j['label'] as String? ?? j['id'] as String,
      price: (j['price'] as num).toInt(),
      currency: (j['currency'] as String?) ?? 'ETB',
      description: j['description'] as String? ?? '',
      tier: (j['tier'] as String?) ?? 'credit',
      badgeKey: j['badgeKey'] as String?,
      highlighted: j['highlighted'] == true,
      dailyCap: (j['dailyCap'] as num?)?.toInt() ?? 2,
      periodLimit: (j['periodLimit'] as num?)?.toInt(),
      periodDays: (j['periodDays'] as num?)?.toInt(),
    );
  }

  /// Offline fallback — matches backend `plans.ts` exactly.
  static const fallback = <PlanOption>[
    PlanOption(
      id: 'daily_pass',
      label: 'Daily Pass',
      price: 50,
      currency: 'ETB',
      description: '',
      tier: 'daily',
      dailyCap: 2,
      periodLimit: 2,
      periodDays: 1,
    ),
    PlanOption(
      id: 'credit_100',
      label: '100 Posts',
      price: 50,
      currency: 'ETB',
      description: '',
      tier: 'credit',
      dailyCap: 2,
      periodLimit: 100,
    ),
    PlanOption(
      id: 'credit_500',
      label: '500 Posts',
      price: 200,
      currency: 'ETB',
      description: '',
      tier: 'credit',
      dailyCap: 2,
      periodLimit: 500,
      badgeKey: 'save_20',
    ),
    PlanOption(
      id: 'credit_1000',
      label: '1000 Posts',
      price: 350,
      currency: 'ETB',
      description: '',
      tier: 'credit',
      dailyCap: 2,
      periodLimit: 1000,
      badgeKey: 'best_value',
      highlighted: true,
    ),
    PlanOption(
      id: 'pro_15d',
      label: 'PRO · 15 days',
      price: 129,
      currency: 'ETB',
      description: '',
      tier: 'pro',
      dailyCap: 2,
      periodLimit: 30,
      periodDays: 15,
    ),
    PlanOption(
      id: 'monthly_pro',
      label: 'PRO · 30 days',
      price: 199,
      currency: 'ETB',
      description: '',
      tier: 'pro',
      dailyCap: 2,
      periodLimit: 60,
      periodDays: 30,
    ),
    PlanOption(
      id: 'pro_6mo',
      label: 'PRO · 6 months',
      price: 999,
      currency: 'ETB',
      description: '',
      tier: 'pro',
      dailyCap: 2,
      periodLimit: 360,
      periodDays: 180,
      badgeKey: 'save_16',
    ),
    PlanOption(
      id: 'yearly_pro',
      label: 'PRO · 1 year',
      price: 1799,
      currency: 'ETB',
      description: '',
      tier: 'pro',
      dailyCap: 2,
      periodLimit: 720,
      periodDays: 365,
      badgeKey: 'save_25',
      highlighted: true,
    ),
  ];
}