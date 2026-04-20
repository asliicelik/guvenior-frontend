import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/utils/currency_format.dart';

// ─── Goal Model ──────────────────────────────────────────────────────────────

class _Goal {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String emoji;
  final double defaultTarget; // TL

  const _Goal({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.emoji,
    required this.defaultTarget,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers
  late AnimationController _bgController;
  late AnimationController _entryController;
  late AnimationController _sliderPulseController;
  late Animation<double> _entryAnimation;
  late Animation<double> _sliderPulse;

  // ── Goals
  static const List<_Goal> _goals = [
    _Goal(
      id: 'rent',
      label: 'Ev Al',
      icon: Icons.home_rounded,
      color: Color(0xFF85C9FF),
      emoji: '🏠',
      defaultTarget: 3000000,
    ),
    _Goal(
      id: 'car',
      label: 'Araba Al',
      icon: Icons.directions_car_rounded,
      color: Color(0xFFFFB085),
      emoji: '🚗',
      defaultTarget: 1500000,
    ),
    _Goal(
      id: 'travel',
      label: 'Tatil',
      icon: Icons.flight_rounded,
      color: Color(0xFFA29BFE),
      emoji: '✈️',
      defaultTarget: 30000,
    ),
    _Goal(
      id: 'education',
      label: 'Eğitim',
      icon: Icons.school_rounded,
      color: Color(0xFF00E5A0),
      emoji: '🎓',
      defaultTarget: 80000,
    ),
  ];

  String _selectedGoalId = 'rent';
  _Goal get _selectedGoal =>
      _goals.firstWhere((g) => g.id == _selectedGoalId);

  // ── Sliders
  double _currentSavings = 100000;
  double _monthlyContribution = 5000;
  double _targetMonths = 36;

  // ── Success probability (computed)
  double get _successProbability {
    final target = _selectedGoal.defaultTarget;
    final projected = _currentSavings +
        (_monthlyContribution * _targetMonths * 1.08); // ~8% yıllık bileşik
    final ratio = (projected / target).clamp(0.0, 1.0);
    // Smooth S-curve for realism
    return (1 / (1 + exp(-10 * (ratio - 0.7))));
  }

  int get _successPercent => (_successProbability * 100).round();

  Color get _successColor {
    if (_successPercent >= 75) return const Color(0xFF00E5A0);
    if (_successPercent >= 50) return AppColors.sky;
    if (_successPercent >= 30) return AppColors.peach;
    return AppColors.moodStressed;
  }

  // ── 5-year growth chart data
  List<FlSpot> get _growthSpots {
    final spots = <FlSpot>[];
    double balance = _currentSavings;
    final monthlyRate = 0.08 / 12; // 8% annual
    for (int m = 0; m <= 60; m += 12) {
      if (m > 0) {
        for (int i = 0; i < 12; i++) {
          balance = balance * (1 + monthlyRate) + _monthlyContribution;
        }
      }
      spots.add(FlSpot(m / 12, balance));
    }
    return spots;
  }

  // ── AI tip message
  String get _aiTip {
    final goal = _selectedGoal;
    if (_successPercent >= 75) {
      return '${goal.emoji} Harika bir yoldasın! Aylık ${CurrencyFormatter.format(_monthlyContribution * 0.1)} daha ekleyerek hedefine ${(_targetMonths * 0.85).toInt()} ayda ulaşabilirsin.';
    } else if (_successPercent >= 50) {
      final cappedPct = min(95, _successPercent + 20);
      return "${goal.emoji} İyi gidiyorsun! Aylık katkını biraz artırırsan başarı olasılığın %${cappedPct}'e çıkar.";
    } else if (_successPercent >= 30) {
      return '${goal.emoji} Hedefe ulaşmak için aylık ${CurrencyFormatter.format(_monthlyContribution * 0.4)} daha birikim yapman öneriliyor. Küçük adımlar büyük fark yaratır!';
    }
    return '${goal.emoji} Hedef süresini biraz uzatmayı veya mevcut birikimini artırmayı düşün. Her küçük adım seni hedefine yaklaştırır! 💪';
  }

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _sliderPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _sliderPulse = CurvedAnimation(
      parent: _sliderPulseController,
      curve: Curves.easeInOut,
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    _sliderPulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        final t = _bgController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.4, -1),
              end: Alignment(1 - t * 0.4, 1),
              colors: [
                Color.lerp(
                  const Color(0xFF0D1117),
                  const Color(0xFF0F1620),
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
          // Peach ambient glow
          Positioned(
            top: -120,
            left: -80,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.scale(
                scale: 1 + _bgController.value * 0.25,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.peach.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Sky ambient glow
          Positioned(
            bottom: 80,
            right: -80,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) => Transform.scale(
                scale: 1 + (1 - _bgController.value) * 0.2,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.sky.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _entryAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 30 * (1 - _entryAnimation.value)),
                  child: Opacity(
                    opacity: _entryAnimation.value,
                    child: child,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildGoalGrid(),
                    const SizedBox(height: 20),
                    _buildSlidersCard(),
                    const SizedBox(height: 20),
                    _buildSuccessCard(),
                    const SizedBox(height: 20),
                    _buildGrowthChart(),
                    const SizedBox(height: 20),
                    _buildAICard(),
                    const SizedBox(height: 24),
                    _buildActivateButton(),
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

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.peach.withOpacity(0.2),
                AppColors.sky.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.peach.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.peachSkyGradient.createShader(bounds),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.peachSkyGradient.createShader(bounds),
                child: Text(
                  'Life Plan Simulation',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Yaşam Planı\nSimülasyonu',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hedefini seç, parametrelerini ayarla — AI koçun senin için hesaplayacak.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ─── Goal Grid ────────────────────────────────────────────────────────────

  Widget _buildGoalGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HEDEFİNİ SEÇ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: _goals
              .map((goal) => _buildGoalCard(goal))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildGoalCard(_Goal goal) {
    final isSelected = _selectedGoalId == goal.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedGoalId = goal.id;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    goal.color.withOpacity(0.35),
                    goal.color.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? goal.color.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: goal.color.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: goal.color.withOpacity(isSelected ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                goal.icon,
                color: goal.color,
                size: 20,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                Text(
                  '₺${_formatAmount(goal.defaultTarget)}',
                  style: TextStyle(
                    color: isSelected
                        ? goal.color
                        : Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sliders Card ─────────────────────────────────────────────────────────

  Widget _buildSlidersCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PARAMETRELERİ AYARLA',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildSlider(
            label: 'Mevcut Birikim',
            value: _currentSavings,
            min: 0,
            max: 3000000,
            step: 10000,
            color: AppColors.peach,
            icon: Icons.savings_rounded,
            onChanged: (v) => setState(() => _currentSavings = v),
          ),
          const SizedBox(height: 20),
          _buildSlider(
            label: 'Aylık Katkı',
            value: _monthlyContribution,
            min: 500,
            max: 50000,
            step: 500,
            color: AppColors.sky,
            icon: Icons.add_chart_rounded,
            onChanged: (v) => setState(() => _monthlyContribution = v),
          ),
          const SizedBox(height: 20),
          _buildSlider(
            label: 'Hedef Süre',
            value: _targetMonths,
            min: 6,
            max: 120,
            step: 1,
            color: const Color(0xFFA29BFE),
            icon: Icons.calendar_month_rounded,
            isMonths: true,
            onChanged: (v) => setState(() => _targetMonths = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required double step,
    required Color color,
    required IconData icon,
    required ValueChanged<double> onChanged,
    bool isMonths = false,
  }) {
    final divisions = ((max - min) / step).round();
    final displayValue = isMonths
        ? '${value.toInt()} ay'
        : '₺${_formatAmount(value)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                displayValue,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: _GradientThumbShape(color: color),
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            overlayColor: color.withOpacity(0.15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ─── Success Probability Card ──────────────────────────────────────────────

  Widget _buildSuccessCard() {
    final goal = _selectedGoal;
    final projected = _currentSavings +
        (_monthlyContribution * _targetMonths * 1.08);
    final gap = goal.defaultTarget - projected;

    return AnimatedBuilder(
      animation: _sliderPulse,
      builder: (_, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _successColor.withOpacity(0.7 + _sliderPulse.value * 0.1),
                _successColor.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _successColor
                    .withOpacity(0.25 + _sliderPulse.value * 0.1),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BAŞARI OLASILIĞI',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${goal.emoji} ${goal.label}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _successPercent >= 75
                      ? '🔥 Güçlü'
                      : _successPercent >= 50
                          ? '✅ İyi'
                          : _successPercent >= 30
                              ? '⚠️ Zayıf'
                              : '❌ Kritik',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Big percentage
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _successProbability),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) {
              return Text(
                '%${(val * 100).round()}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 68,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _successProbability),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: val,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          // Details row
          Row(
            children: [
              _buildDetailChip(
                  'Tahmini', '₺${_formatAmount(projected.clamp(0, double.infinity))}'),
              const SizedBox(width: 10),
              _buildDetailChip(
                  'Hedef', '₺${_formatAmount(goal.defaultTarget)}'),
              if (gap > 0) ...[
                const SizedBox(width: 10),
                _buildDetailChip('Açık', '₺${_formatAmount(gap)}',
                    isWarning: true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value,
      {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isWarning ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5-Year Growth Chart ──────────────────────────────────────────────────

  Widget _buildGrowthChart() {
    final spots = _growthSpots;
    final maxY = spots.last.y * 1.15;
    final goal = _selectedGoal;
    // Target line y position
    final targetY = goal.defaultTarget.toDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 Yıllık Büyüme Tahmini',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.peach.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '%8 yıllık',
                  style: TextStyle(
                    color: AppColors.peach,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bileşik faiz + aylık katkı projeksiyonu',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: max(maxY, targetY * 1.1),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final year = value.toInt();
                        if (year < 0 || year > 5) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          year == 0 ? 'Bugün' : 'Y$year',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: targetY,
                      color: _selectedGoal.color.withOpacity(0.5),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          color: _selectedGoal.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (_) => 'Hedef',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  // Savings growth line
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: LinearGradient(
                      colors: [AppColors.peach, AppColors.sky],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) {
                        return FlDotCirclePainter(
                          radius: spot.x == 5 ? 5 : 0,
                          color: AppColors.peach,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.peach.withOpacity(0.2),
                          AppColors.sky.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF161B22),
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            '₺${_formatAmount(s.y)}',
                            GoogleFonts.inter(
                              color: AppColors.peach,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartStat(
                  'Bugün', '₺${_formatAmount(_currentSavings)}', AppColors.peach),
              _buildChartStat(
                  '5. Yıl',
                  '₺${_formatAmount(spots.last.y)}',
                  AppColors.sky),
              _buildChartStat(
                  'Büyüme',
                  '+${_currentSavings > 0 ? ((spots.last.y / _currentSavings - 1) * 100).toStringAsFixed(0) : '∞'}%',
                  const Color(0xFF00E5A0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ─── AI Card ──────────────────────────────────────────────────────────────

  Widget _buildAICard() {
    const aiGreen = Color(0xFF00E5A0);
    return GlassCard(
      borderColor: aiGreen.withOpacity(0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: aiGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: aiGreen,
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
                    color: aiGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _aiTip,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 12),
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildTag('💡 Kişisel analiz', aiGreen),
                    _buildTag('📊 Veri tabanlı', AppColors.sky),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Activate Button ──────────────────────────────────────────────────────

  Widget _buildActivateButton() {
    return GestureDetector(
      onTap: _onActivatePlan,
      child: AnimatedBuilder(
        animation: _sliderPulse,
        builder: (_, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.peachSkyGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.peach
                      .withOpacity(0.3 + _sliderPulse.value * 0.15),
                  blurRadius: 20 + _sliderPulse.value * 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Planı Aktifleştir',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onActivatePlan() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildActivationSheet(),
    );
  }

  Widget _buildActivationSheet() {
    final goal = _selectedGoal;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [goal.color.withOpacity(0.4), goal.color.withOpacity(0.2)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: goal.color.withOpacity(0.5), width: 2),
            ),
            child: Icon(goal.icon, color: goal.color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Plan Aktifleştirildi! 🎉',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.emoji} ${goal.label} hedefin için %$_successPercent başarı olasılığıyla planın kaydedildi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.peachSkyGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Harika!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

// ─── Custom Slider Thumb ──────────────────────────────────────────────────────

class _GradientThumbShape extends SliderComponentShape {
  final Color color;
  const _GradientThumbShape({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, 12, glowPaint);

    // White ring
    final ringPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10, ringPaint);

    // Colored center
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerPaint);
  }
}
