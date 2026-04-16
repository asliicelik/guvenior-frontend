import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../income/screens/income_screen.dart';
import '../../expense/screens/expense_screen.dart';
import '../../income/services/income_service.dart';
import '../../expense/services/expense_service.dart';
import '../../income/models/income_model.dart';
import '../../expense/models/expense_model.dart';
import '../../../core/services/local_data_service.dart';
import '../../../core/utils/currency_format.dart';
import '../../insights/screens/insights_screen.dart';
import '../../simulation/screens/simulation_screen.dart';
import '../../entry/screens/entry_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../auth/services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String _fullName = '';
  List<Income> _incomes = [];
  List<Expense> _expenses = [];
  double _monthlyIncome = 0;
  int _streak = 0;
  bool _isLoading = true;
  int _selectedNav = 0;

  late AnimationController _bgController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

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
    final prefs = await SharedPreferences.getInstance();
    setState(() => _fullName = prefs.getString('fullName') ?? 'Kullanıcı');
    try {
      // Önce profili senkronize et:
      await AuthService.getProfile();
      
      final results = await Future.wait([
        IncomeService.getIncomes(),
        ExpenseService.getExpenses(),
        LocalDataService.getSalary(),
        LocalDataService.getSalaryDay(),
        LocalDataService.checkAndUpdateStreak(),
      ]);
      setState(() {
        _incomes = results[0] as List<Income>;
        _expenses = results[1] as List<Expense>;
        _monthlyIncome = results[2] as double;
        _streak = results[4] as int;
        _isLoading = false;
      });
      _cardController.forward();
    } catch (_) {
      setState(() => _isLoading = false);
      _cardController.forward();
    }
  }

  // ── Computed values ─────────────────────────────────────────────────────────

  double get _totalIncome => _incomes.fold(0.0, (s, i) => s + i.amount);
  double get _totalExpense => _expenses.fold(0.0, (s, e) => s + e.amount);
  double get _netBalance => _monthlyIncome + _totalIncome - _totalExpense;
  double get _spendingRatio =>
      (_monthlyIncome + _totalIncome) > 0
          ? (_totalExpense / (_monthlyIncome + _totalIncome)).clamp(0.0, 1.0)
          : 0.0;

  // Last 7 days expenses grouped by day
  List<double> get _weeklyExpenses {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _expenses
          .where((e) =>
              e.spentAt.year == day.year &&
              e.spentAt.month == day.month &&
              e.spentAt.day == day.day)
          .fold(0.0, (s, e) => s + e.amount);
    });
  }

  // Recent 5 transactions (income + expense mixed)
  List<Map<String, dynamic>> get _recentTransactions {
    final list = <Map<String, dynamic>>[];
    for (final i in _incomes) {
      list.add({
        'title': i.title, 'amount': i.amount, 'date': i.receivedDate,
        'isIncome': true, 'type': i.type,
      });
    }
    for (final e in _expenses) {
      list.add({
        'title': e.title, 'amount': e.amount, 'date': e.spentAt,
        'isIncome': false, 'category': e.category,
      });
    }
    list.sort((a, b) =>
        (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return list.take(5).toList();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  String get _aiMessage {
    if (_monthlyIncome == 0 && _totalIncome == 0) {
      return 'Henüz gelir eklemedin. Ayarlardan aylık gelirini gir! 🚀';
    }
    if (_spendingRatio < 0.3) {
      return 'Harika gidiyorsun! Gelirinizin sadece %${(_spendingRatio * 100).toInt()} harcandı. 💪';
    }
    if (_spendingRatio < 0.6) {
      return 'Dengeli bir ay geçiriyorsun. Biraz daha dikkatli olabilirsin. 👀';
    }
    if (_spendingRatio < 0.9) {
      return 'Harcamalar biraz fazla. Seninle konuşalım! 💡';
    }
    return 'Bu ay bütçen kritik seviyede. Beraber çözelim. 🤝';
  }

  Color get _aiColor {
    if (_spendingRatio < 0.3) return const Color(0xFF00E5A0);
    if (_spendingRatio < 0.6) return AppColors.sky;
    if (_spendingRatio < 0.9) return AppColors.peach;
    return AppColors.moodStressed;
  }

  // ─── Category / type meta ─────────────────────────────────────────────────

  final Map<int, String> _categoryNames = {
    1: 'Yemek', 2: 'Ulaşım', 3: 'Kira', 4: 'Alışveriş',
    5: 'Eğlence', 6: 'Faturalar', 7: 'Eğitim', 8: 'Diğer',
  };
  final Map<int, Color> _categoryColors = {
    1: const Color(0xFFFF9F43), 2: const Color(0xFF54A0FF),
    3: const Color(0xFF00E5A0), 4: const Color(0xFFFF6B9D),
    5: const Color(0xFFA29BFE), 6: const Color(0xFFFFB085),
    7: const Color(0xFF85C9FF), 8: const Color(0xFFB2BEC3),
  };
  final Map<int, IconData> _categoryIcons = {
    1: Icons.restaurant_outlined, 2: Icons.directions_bus_outlined,
    3: Icons.home_outlined, 4: Icons.shopping_bag_outlined,
    5: Icons.movie_outlined, 6: Icons.receipt_outlined,
    7: Icons.school_outlined, 8: Icons.more_horiz,
  };
  final Map<int, String> _incomeTypes = {
    1: 'Maaş', 2: 'Freelance', 3: 'Burs', 4: 'Aile Desteği', 5: 'Diğer',
  };
  final Map<int, IconData> _typeIcons = {
    1: Icons.work_outline, 2: Icons.laptop_outlined,
    3: Icons.school_outlined, 4: Icons.favorite_outline, 5: Icons.more_horiz,
  };

  // ─── Build ──────────────────────────────────────────────────────────────────

  Widget _getCurrentPage(int index) {
    switch (index) {
      case 0: return _buildHomeBody();
      case 1: return const EntryScreen();
      case 2: return const InsightsScreen();
      case 3: return const SimulationScreen();
      case 4: return const SettingsScreen();
      default: return _buildHomeBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(_selectedNav),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Home body ───────────────────────────────────────────────────────────────

  Widget _buildHomeBody() {
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
                Color.lerp(const Color(0xFF0D1117), const Color(0xFF1A1225), t)!,
                Color.lerp(const Color(0xFF111827), const Color(0xFF0D1A2E), t)!,
                Color.lerp(const Color(0xFF0D1117), const Color(0xFF1A1225), t)!,
              ],
            ),
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          // Peach glow
          Positioned(
            top: -100, right: -80,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.scale(
                scale: 1 + _bgController.value * 0.2,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.peach.withOpacity(0.12), Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),
          ),
          // Sky glow
          Positioned(
            bottom: 100, left: -60,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.scale(
                scale: 1 + (1 - _bgController.value) * 0.2,
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.sky.withOpacity(0.1), Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.peach))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.peach,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnimatedBuilder(
                        animation: _cardAnimation,
                        builder: (ctx, child) => Transform.translate(
                          offset: Offset(0, 20 * (1 - _cardAnimation.value)),
                          child: Opacity(opacity: _cardAnimation.value, child: child),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildAppBarRow(),
                            const SizedBox(height: 24),
                            _buildGreeting(),
                            const SizedBox(height: 20),
                            _buildBalanceCard(),
                            const SizedBox(height: 16),
                            _buildAICard(),
                            const SizedBox(height: 16),
                            _buildWeeklyChart(),
                            const SizedBox(height: 16),
                            _buildStreakCard(),
                            const SizedBox(height: 16),
                            _buildRecentTransactions(),
                            const SizedBox(height: 16),
                            _buildQuickActions(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── App bar row ─────────────────────────────────────────────────────────────

  Widget _buildAppBarRow() {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.peachSkyGradient,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (b) => AppColors.peachSkyGradient.createShader(b),
          child: Text('Güvenior',
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            setState(() => _selectedNav = 4);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.settings_outlined, color: Colors.white54, size: 18),
          ),
        ),
      ],
    );
  }

  // ─── Greeting ────────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$_greeting 👋',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 4),
        Text('Merhaba, $_fullName.',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ─── Balance card ────────────────────────────────────────────────────────────

  Widget _buildBalanceCard() {
    final isPositive = _netBalance >= 0;
    final balanceColor = isPositive ? const Color(0xFF00E5A0) : AppColors.moodStressed;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            balanceColor.withOpacity(0.7),
            balanceColor.withOpacity(0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: balanceColor.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NET BAKİYE',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 10,
                    fontWeight: FontWeight.w700, letterSpacing: 1.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPositive ? '✅ Pozitif' : '⚠️ Negatif',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isPositive
                ? CurrencyFormatter.format(_netBalance.abs())
                : '-${CurrencyFormatter.format(_netBalance.abs())}',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900,
                height: 1),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _balanceChip('Aylık Gelir', _monthlyIncome, AppColors.peach, Icons.work_outline),
              const SizedBox(width: 8),
              _balanceChip('Gelir', _totalIncome, AppColors.sky,
                  Icons.trending_up_rounded),
              const SizedBox(width: 8),
              _balanceChip('Gider', _totalExpense, AppColors.moodStressed,
                  Icons.trending_down_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceChip(String label, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.6), size: 11),
                const SizedBox(width: 3),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              CurrencyFormatter.format(amount),
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─── AI card ──────────────────────────────────────────────────────────────────

  Widget _buildAICard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _aiColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _aiColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: _aiColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _aiMessage,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 13, height: 1.5,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Weekly chart ─────────────────────────────────────────────────────────────

  Widget _buildWeeklyChart() {
    final data = _weeklyExpenses;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Haftalık Harcama',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              Text(
                CurrencyFormatter.format(data.fold(0.0, (s, v) => s + v)),
                style: TextStyle(
                    color: AppColors.sky, fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Son 7 gün',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11)),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                maxY: maxVal > 0 ? maxVal * 1.3 : 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF161B22),
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      CurrencyFormatter.format(rod.toY),
                      GoogleFonts.inter(
                          color: AppColors.sky, fontWeight: FontWeight.w700,
                          fontSize: 11),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final day = now.subtract(Duration(days: 6 - val.toInt()));
                        final labels = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pa'];
                        return Text(
                          labels[day.weekday - 1],
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 9),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final val = data[i];
                  final isToday = i == 6;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: val > 0 ? val : 0.5,
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: isToday
                              ? [AppColors.peach, AppColors.sky]
                              : [
                                  AppColors.sky.withOpacity(0.6),
                                  AppColors.sky.withOpacity(0.3),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Streak card ──────────────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    final String emoji;
    final String label;
    final Color color;
    if (_streak >= 30) {
      emoji = '🏆'; label = 'Efsane Streak!'; color = const Color(0xFFFFD93D);
    } else if (_streak >= 8) {
      emoji = '💪'; label = 'Süper Gidiyorsun!'; color = AppColors.peach;
    } else if (_streak >= 1) {
      emoji = '🔥'; label = 'Streak Devam Ediyor!'; color = const Color(0xFFFF8C69);
    } else {
      emoji = '💡'; label = 'Bugün Başla!'; color = AppColors.sky;
    }

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  _streak > 0
                      ? 'Üst üste $_streak gün uygulamayı açtın!'
                      : 'Uygulamayı her gün aç ve streak kazan.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 12),
                ),
              ],
            ),
          ),
          if (_streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '$_streak 🔥',
                style: GoogleFonts.inter(
                    color: color, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Recent transactions ──────────────────────────────────────────────────────

  Widget _buildRecentTransactions() {
    final txns = _recentTransactions;
    if (txns.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Son İşlemler',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () => setState(() => _selectedNav = 1),
              child: Text('Tümünü gör',
                  style: TextStyle(
                      color: AppColors.peach, fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...txns.map((t) => _buildRecentTile(t)),
      ],
    );
  }

  Widget _buildRecentTile(Map<String, dynamic> t) {
    final isIncome = t['isIncome'] as bool;
    final color = isIncome
        ? AppColors.peach
        : (_categoryColors[t['category']] ?? Colors.white54);
    final icon = isIncome
        ? (_typeIcons[t['type']] ?? Icons.attach_money)
        : (_categoryIcons[t['category']] ?? Icons.more_horiz);
    final subtitle = isIncome
        ? (_incomeTypes[t['type']] ?? 'Gelir')
        : (_categoryNames[t['category']] ?? 'Harcama');
    final date = t['date'] as DateTime;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t['title'],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '$subtitle • ${date.day}.${date.month}.${date.year}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 10),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(t['amount'] as double)}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick actions ────────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            icon: Icons.add_circle_outline,
            label: 'Gelir Ekle',
            gradient: AppColors.peachSkyGradient,
            onTap: () async {
              await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const IncomeScreen()));
              _loadData();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            icon: Icons.remove_circle_outline,
            label: 'Harcama Ekle',
            gradient: LinearGradient(
                colors: [AppColors.sky, AppColors.sky.withOpacity(0.6)]),
            onTap: () async {
              await Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ExpenseScreen()));
              _loadData();
            },
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.peach.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ─── Bottom nav ───────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.grid_view_rounded, 'Ana Sayfa', 0),
              _navItem(Icons.calendar_month_rounded, 'Kayıt', 1),
              _navItem(Icons.bar_chart_rounded, 'Analiz', 2),
              _navItem(Icons.show_chart_rounded, 'Simülasyon', 3),
              _navItem(Icons.settings_rounded, 'Ayarlar', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.peach.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? AppColors.peach : Colors.white38, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.peach : Colors.white38,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
