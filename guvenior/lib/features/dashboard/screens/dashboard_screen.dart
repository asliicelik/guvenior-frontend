import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/screens/login_screen.dart';
import '../../income/screens/income_screen.dart';
import '../../expense/screens/expense_screen.dart';
import '../../income/services/income_service.dart';
import '../../expense/services/expense_service.dart';
import '../../../core/services/api_service.dart';
import '../../insights/screens/insights_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String _fullName = '';
  double _totalIncome = 0;
  double _totalExpense = 0;
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
      final incomes = await IncomeService.getIncomes();
      final expenses = await ExpenseService.getExpenses();
      setState(() {
        _totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
        _totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
        _isLoading = false;
      });
      _cardController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _cardController.forward();
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  double get _balance => _totalIncome - _totalExpense;
  double get _spendingRatio =>
      _totalIncome > 0 ? (_totalExpense / _totalIncome).clamp(0, 1) : 0;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  String get _aiMessage {
    if (_totalIncome == 0) return 'Henüz gelir eklemedin. Hadi başlayalım! 🚀';
    if (_spendingRatio < 0.3)
      return 'Harika gidiyorsun! Gelirinizin sadece %${(_spendingRatio * 100).toInt()}\'ini harcadın. 💪';
    if (_spendingRatio < 0.6)
      return 'Dengeli bir ay geçiriyorsun. Biraz daha dikkatli olabilirsin. 👀';
    if (_spendingRatio < 0.9)
      return 'Harcamalar biraz fazla. Seninle konuşalım! 💡';
    return 'Bu ay bütçen kritik seviyede. Beraber çözelim. 🤝';
  }

  Color get _aiColor {
    if (_spendingRatio < 0.3) return const Color(0xFF00E5A0);
    if (_spendingRatio < 0.6) return AppColors.sky;
    if (_spendingRatio < 0.9) return AppColors.peach;
    return AppColors.moodStressed;
  }

  String get _statusText {
    if (_totalIncome == 0) return 'Henüz Başlamadın';
    if (_spendingRatio < 0.3) return 'Mükemmel Gidiyorsun!';
    if (_spendingRatio < 0.6) return 'Gayet İyi Durumdayken';
    if (_spendingRatio < 0.9) return 'Dikkat Etmeli';
    return 'Kritik Seviye';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedNav,
        children: [
          _buildHomeBody(),
          const SizedBox(),
          const InsightsScreen(),
          const SizedBox(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

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
          // Peach glow
          Positioned(
            top: -100,
            right: -80,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.scale(
                scale: 1 + _bgController.value * 0.2,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.peach.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Sky glow
          Positioned(
            bottom: 100,
            left: -60,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.scale(
                scale: 1 + (1 - _bgController.value) * 0.2,
                child: Container(
                  width: 250,
                  height: 250,
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
                          const SizedBox(height: 20),
                          _buildAppBar(),
                          const SizedBox(height: 28),
                          _buildGreeting(),
                          const SizedBox(height: 20),
                          _buildAICard(),
                          const SizedBox(height: 16),
                          _buildStatusCard(),
                          const SizedBox(height: 16),
                          _buildCircularProgress(),
                          const SizedBox(height: 16),
                          _buildQuickActions(),
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

  Widget _buildAppBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.peachSkyGradient,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.peachSkyGradient.createShader(bounds),
          child: Text(
            'Güvenior',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _logout,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(Icons.logout, color: Colors.white54, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
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
            '$_greeting 👋',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hi, $_fullName.',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICard() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 40 * (1 - _cardAnimation.value)),
        child: Opacity(opacity: _cardAnimation.value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _aiColor.withOpacity(0.15),
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
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
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
            Text(
              'STATUS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBadge(Icons.auto_awesome, _aiColor),
                const SizedBox(width: 8),
                _buildBadge(Icons.timer, AppColors.peach),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildCircularProgress() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 60 * (1 - _cardAnimation.value)),
        child: Opacity(opacity: _cardAnimation.value, child: child),
      ),
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: _spendingRatio,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(_aiColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '%${(_spendingRatio * 100).toInt()}',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'OF SALARY',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Gelir Ekle',
            gradient: AppColors.peachSkyGradient,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IncomeScreen()),
              );
              _loadData();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Harcama Ekle',
            gradient: LinearGradient(
              colors: [AppColors.sky, AppColors.sky.withOpacity(0.6)],
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              );
              _loadData();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
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
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.add_circle_outline,
                label: 'Entry',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Insights',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.show_chart_rounded,
                label: 'Simulation',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNav = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.peach.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.peach : Colors.white38,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.peach : Colors.white38,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
