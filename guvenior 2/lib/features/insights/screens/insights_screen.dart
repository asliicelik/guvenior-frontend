import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/utils/currency_format.dart';
import '../../expense/services/expense_service.dart';
import '../../expense/models/expense_model.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with TickerProviderStateMixin {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  final Map<int, String> _categories = {
    1: 'Yemek',
    2: 'Ulaşım',
    3: 'Kira',
    4: 'Alışveriş',
    5: 'Eğlence',
    6: 'Faturalar',
    7: 'Eğitim',
    8: 'Diğer',
  };

  final Map<int, Color> _categoryColors = {
    1: Color(0xFFFF9F43),
    2: Color(0xFF54A0FF),
    3: Color(0xFF00E5A0),
    4: Color(0xFFFF6B9D),
    5: Color(0xFFA29BFE),
    6: Color(0xFFFFB085),
    7: Color(0xFF85C9FF),
    8: Color(0xFFB2BEC3),
  };

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final expenses = await ExpenseService.getExpenses();
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
      _cardController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Gece alışveriş saati analizi (21:00 - 04:00)
  Map<int, double> get _nightShoppingData {
    final data = <int, double>{};
    for (var i = 0; i < 24; i++) data[i] = 0;
    for (final e in _expenses) {
      data[e.spentAt.hour] = (data[e.spentAt.hour] ?? 0) + e.amount;
    }
    return data;
  }

  // Kategori bazlı harcama
  Map<int, double> get _categoryTotals {
    final totals = <int, double>{};
    for (final e in _expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  double get _totalExpense => _expenses.fold(0, (s, e) => s + e.amount);

  // Gece harcama oranı
  double get _nightSpendingRatio {
    if (_expenses.isEmpty) return 0;
    final nightTotal = _expenses
        .where((e) => e.spentAt.hour >= 21 || e.spentAt.hour <= 4)
        .fold(0.0, (s, e) => s + e.amount);
    return _totalExpense > 0 ? nightTotal / _totalExpense : 0;
  }

  // Impulse resilience skoru (gece harcama azsa yüksek)
  int get _impulseScore =>
      (100 - (_nightSpendingRatio * 100)).clamp(0, 100).toInt();

  Color get _impulseColor {
    if (_impulseScore >= 70) return const Color(0xFF00E5A0);
    if (_impulseScore >= 40) return AppColors.peach;
    return AppColors.moodStressed;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.5, -1),
              end: Alignment(1 - t * 0.5, 1),
              colors: [
                Color.lerp(
                  const Color(0xFF0D1117),
                  const Color(0xFF1A1225),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF111827),
                  const Color(0xFF0D1A2E),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFF0D1117),
                  const Color(0xFF1A1225),
                  t,
                )!,
              ],
            ),
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.scale(
                scale: 1 + _bgController.value * 0.2,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.sky.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.peach),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.peach,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildImpulseCard(),
                          const SizedBox(height: 16),
                          _buildNightShoppingCard(),
                          const SizedBox(height: 16),
                          _buildCategoryBreakdown(),
                          const SizedBox(height: 16),
                          _buildNudgeCard(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 30 * (1 - _cardAnimation.value)),
        child: Opacity(opacity: _cardAnimation.value, child: child),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finansal Hikâyen 📊',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Harcama davranışlarını anlamana yardımcı oluyoruz.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpulseCard() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 40 * (1 - _cardAnimation.value)),
        child: Opacity(opacity: _cardAnimation.value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _impulseColor.withOpacity(0.8),
              _impulseColor.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _impulseColor.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IMPULSE REZİLYANS SKORU',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+%$_impulseScore',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _impulseScore >= 70
                        ? 'Harika!'
                        : _impulseScore >= 40
                        ? 'Gelişiyor'
                        : 'Dikkat!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _impulseScore >= 70
                  ? 'Dürtüsel harcamalara karşı güçlü duruyorsun! 💪'
                  : _impulseScore >= 40
                  ? 'Gece harcamalarına biraz dikkat et.'
                  : 'Gece alışverişlerin bütçeni etkiliyor.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNightShoppingCard() {
    final nightData = _nightShoppingData;
    final maxVal = nightData.values.isEmpty
        ? 1.0
        : nightData.values.reduce((a, b) => a > b ? a : b);
    final nightHours = [20, 21, 22, 23, 0, 1, 2, 3, 4];

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 50 * (1 - _cardAnimation.value)),
        child: Opacity(opacity: _cardAnimation.value, child: child),
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gece Alışveriş Sıklığı',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.moodStressed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'GECE SAATLERİ',
                    style: TextStyle(
                      color: AppColors.moodStressed,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '21:00 - 04:00 arası aktivite',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(nightHours.length, (i) {
                  final hour = nightHours[i];
                  final val = nightData[hour] ?? 0;
                  final ratio = maxVal > 0 ? val / maxVal : 0.0;
                  final isLate = hour >= 0 && hour <= 4;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: Duration(milliseconds: 400 + i * 50),
                            height: 80 * ratio + 4,
                            decoration: BoxDecoration(
                              color: isLate
                                  ? AppColors.moodStressed.withOpacity(0.7)
                                  : AppColors.sky.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$hour',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final totals = _categoryTotals;
    if (totals.isEmpty) {
      return GlassCard(
        child: Center(
          child: Text(
            'Henüz harcama verisi yok.',
            style: TextStyle(color: Colors.white.withOpacity(0.4)),
          ),
        ),
      );
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 60 * (1 - _cardAnimation.value)),
        child: Opacity(opacity: _cardAnimation.value, child: child),
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori Dağılımı',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ...sorted.take(5).map((entry) {
              final color = _categoryColors[entry.key] ?? Colors.white54;
              final ratio = _totalExpense > 0
                  ? entry.value / _totalExpense
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _categories[entry.key] ?? 'Diğer',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '%${(ratio * 100).toInt()} • ${CurrencyFormatter.format(entry.value)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNudgeCard() {
    final topCategory = _categoryTotals.entries.isEmpty
        ? null
        : _categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);

    return GlassCard(
      borderColor: const Color(0xFF00E5A0).withOpacity(0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5A0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF00E5A0),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Koçun diyor ki:',
                  style: TextStyle(
                    color: Color(0xFF00E5A0),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topCategory != null
                      ? '${_categories[topCategory.key]} kategorisinde en çok harcıyorsun. Bu ay biraz kıssana? 😊'
                      : 'Harcamalarını eklemeye başla, sana özel analizler yapayım! 🚀',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
