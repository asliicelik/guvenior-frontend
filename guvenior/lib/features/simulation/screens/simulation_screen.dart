import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/utils/currency_format.dart';
import '../models/financial_goal_model.dart';
import '../services/financial_goal_service.dart';

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

  // ── State variables
  List<FinancialGoalSimulation> _simulations = [];
  int? _selectedGoalId;
  bool _isLoading = true;

  // ── Local drag values for slider smoothness
  double? _dragSavings;
  double? _dragContribution;
  double? _dragMonths;

  FinancialGoalSimulation? get _selectedSimulation {
    if (_simulations.isEmpty || _selectedGoalId == null) return null;
    return _simulations.firstWhere(
      (s) => s.goalId == _selectedGoalId,
      orElse: () => _simulations.first,
    );
  }

  // ── Meta mapping for goal types
  final Map<int, Color> _typeColors = {
    1: const Color(0xFF85C9FF), // Home
    2: const Color(0xFFFFB085), // Car
    3: const Color(0xFF00E5A0), // Rent
    4: const Color(0xFFA29BFE), // Education
    5: const Color(0xFFFF6B9D), // Emergency Fund
    6: const Color(0xFFB2BEC3), // Other
  };

  final Map<int, IconData> _typeIcons = {
    1: Icons.home_rounded,
    2: Icons.directions_car_rounded,
    3: Icons.key_rounded,
    4: Icons.school_rounded,
    5: Icons.security_rounded,
    6: Icons.star_rounded,
  };

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

    _loadData();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    _sliderPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final sims = await FinancialGoalService.getSimulations();
      setState(() {
        _simulations = sims;
        if (sims.isNotEmpty) {
          if (_selectedGoalId == null || !sims.any((s) => s.goalId == _selectedGoalId)) {
            _selectedGoalId = sims.first.goalId;
          }
        } else {
          _selectedGoalId = null;
        }
        _dragSavings = null;
        _dragContribution = null;
        _dragMonths = null;
        _isLoading = false;
      });
      _entryController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _entryController.forward();
    }
  }

  // ── computed coverage rate for the UI
  int get _coveragePercent {
    final sim = _selectedSimulation;
    if (sim == null) return 0;
    final totalPlanned = sim.analysis.plannedTotalSavings;
    final target = sim.analysis.projectedTargetPrice;
    if (target <= 0) return 100;
    return (totalPlanned / target * 100).clamp(0, 100).round();
  }

  Color get _successColor {
    final risk = _selectedSimulation?.analysis.riskLevel;
    if (risk == 'Dusuk') return const Color(0xFF00E5A0);
    if (risk == 'Orta') return AppColors.sky;
    return AppColors.peach;
  }

  // ── Growth Chart Projection
  List<FlSpot> get _growthSpots {
    final sim = _selectedSimulation;
    if (sim == null) return [];

    final spots = <FlSpot>[];
    double balance = _dragSavings ?? sim.analysis.currentSavings;
    final contrib = _dragContribution ?? sim.analysis.monthlyContribution;
    final monthlyRate = 0.08 / 12; // 8% annual yield

    for (int m = 0; m <= 60; m += 12) {
      if (m > 0) {
        for (int i = 0; i < 12; i++) {
          balance = balance * (1 + monthlyRate) + contrib;
        }
      }
      spots.add(FlSpot(m / 12, balance));
    }
    return spots;
  }

  // ── Helper to format values
  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
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
              begin: Alignment(-1 + t * 0.4, -1),
              end: Alignment(1 - t * 0.4, 1),
              colors: [
                Color.lerp(const Color(0xFF0D1117), const Color(0xFF0F1620), t)!,
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
          // Ambient Glows
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
                            if (_simulations.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildSlidersCard(),
                              const SizedBox(height: 20),
                              _buildSuccessCard(),
                              const SizedBox(height: 20),
                              _buildGrowthChart(),
                              const SizedBox(height: 20),
                              _buildAICard(),
                              const SizedBox(height: 20),
                              _buildSpendingImpactSection(),
                            ],
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
        Column(
          children: [
            GestureDetector(
              onTap: _showAddGoalBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.peach.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.peach.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.peach, size: 24),
              ),
            ),
            if (_selectedSimulation != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _onDeleteSelectedGoal,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 24),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildGoalGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HEDEFLERİM',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_simulations.isEmpty)
          GestureDetector(
            onTap: _showAddGoalBottomSheet,
            child: GlassCard(
              padding: const EdgeInsets.all(32),
              borderColor: AppColors.peach.withOpacity(0.3),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: AppColors.peach, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      'Henüz Bir Hedef Eklemedin!',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI Simülatörünü çalıştırmak için ilk hedefini hemen oluştur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: _simulations.map((sim) {
              final isSelected = _selectedGoalId == sim.goalId;
              // Map default or custom values
              final color = _typeColors[1] ?? AppColors.sky; // Fallback
              final icon = _typeIcons[1] ?? Icons.star;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedGoalId = sim.goalId;
                  _dragSavings = null;
                  _dragContribution = null;
                  _dragMonths = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              color.withOpacity(0.35),
                              color.withOpacity(0.15),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.6)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.25),
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
                          color: color.withOpacity(isSelected ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 20,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sim.title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '₺${_formatAmount(sim.analysis.currentPrice)}',
                            style: TextStyle(
                              color: isSelected ? color : Colors.white.withOpacity(0.4),
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
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSlidersCard() {
    final sim = _selectedSimulation!;
    final color = const Color(0xFF85C9FF);

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
            value: _dragSavings ?? sim.analysis.currentSavings,
            min: 0,
            max: sim.analysis.currentPrice * 1.5,
            step: 5000,
            color: AppColors.peach,
            icon: Icons.savings_rounded,
            onChanged: (v) => setState(() => _dragSavings = v),
            onChangeEnd: (v) => _onUpdateGoalParameter(currentSavings: v),
          ),
          const SizedBox(height: 20),
          _buildSlider(
            label: 'Aylık Katkı',
            value: _dragContribution ?? sim.analysis.monthlyContribution,
            min: 0,
            max: sim.analysis.currentPrice / 10,
            step: 500,
            color: AppColors.sky,
            icon: Icons.add_chart_rounded,
            onChanged: (v) => setState(() => _dragContribution = v),
            onChangeEnd: (v) => _onUpdateGoalParameter(monthlyContribution: v),
          ),
          const SizedBox(height: 20),
          _buildSlider(
            label: 'Hedef Süre (Kalan Ay)',
            value: _dragMonths ?? sim.analysis.monthsRemaining.toDouble(),
            min: 1,
            max: 120,
            step: 1,
            color: const Color(0xFFA29BFE),
            icon: Icons.calendar_month_rounded,
            isMonths: true,
            onChanged: (v) => setState(() => _dragMonths = v),
            onChangeEnd: (v) {
              final days = (v.toInt() * 30.43).round();
              final newTargetDate = DateTime.now().add(Duration(days: days));
              _onUpdateGoalParameter(targetDate: newTargetDate);
            },
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
    required ValueChanged<double> onChangeEnd,
    bool isMonths = false,
  }) {
    final actualMax = max > min ? max : min + 1000;
    final divisions = ((actualMax - min) / step).round();
    final displayValue = isMonths ? '${value.toInt()} ay' : '₺${_formatAmount(value)}';

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
            value: value.clamp(min, actualMax),
            min: min,
            max: actualMax,
            divisions: divisions > 0 ? divisions : 1,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard() {
    final sim = _selectedSimulation!;
    final analysis = sim.analysis;
    final gap = analysis.fundingGap;

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
                color: _successColor.withOpacity(0.25 + _sliderPulse.value * 0.1),
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
                    'HEDEF GERÇEKLEŞME ORANI',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sim.title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  analysis.riskLevel == 'Dusuk'
                      ? '🔥 Düşük Risk'
                      : analysis.riskLevel == 'Orta'
                          ? '✅ Orta Risk'
                          : '⚠️ Yüksek Risk',
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
          Text(
            '%$_coveragePercent',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 68,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _coveragePercent / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildDetailChip('Planlanan Toplam', '₺${_formatAmount(analysis.plannedTotalSavings)}'),
              const SizedBox(width: 10),
              _buildDetailChip('Enflasyonlu Fiyat', '₺${_formatAmount(analysis.projectedTargetPrice)}'),
              if (gap > 0) ...[
                const SizedBox(width: 10),
                _buildDetailChip('Açık', '₺${_formatAmount(gap)}', isWarning: true),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, String value, {bool isWarning = false}) {
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

  Widget _buildGrowthChart() {
    final spots = _growthSpots;
    if (spots.isEmpty) return const SizedBox.shrink();

    final maxY = spots.last.y * 1.15;
    final targetY = _selectedSimulation!.analysis.projectedTargetPrice;

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.peach.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
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
            'Bileşik faiz (%8) + aylık katkı projeksiyonu',
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
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final year = value.toInt();
                        if (year < 0 || year > 5) return const SizedBox.shrink();
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
                      color: AppColors.sky.withOpacity(0.5),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(
                          color: AppColors.sky,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (_) => 'Hedef',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: LinearGradient(colors: [AppColors.peach, AppColors.sky]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: spot.x == 5 ? 5 : 0,
                        color: AppColors.peach,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICard() {
    final sim = _selectedSimulation!;
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
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  sim.aiMessage.isNotEmpty ? sim.aiMessage : sim.ruleBasedRecommendation,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingImpactSection() {
    return GestureDetector(
      onTap: () => _showSpendingImpactBottomSheet(_selectedGoalId!),
      child: GlassCard(
        borderColor: AppColors.sky.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sky.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calculate_rounded, color: AppColors.sky, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harcama Etki Analizi',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Planladığın bir harcamanın bu hedefe etkisini gör.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }

  // ─── Slider update helper
  Future<void> _onUpdateGoalParameter({
    double? currentSavings,
    double? monthlyContribution,
    DateTime? targetDate,
  }) async {
    if (_selectedGoalId == null) return;
    try {
      await FinancialGoalService.updateGoal(
        _selectedGoalId!,
        currentSavings: currentSavings,
        monthlyContribution: monthlyContribution,
        targetDate: targetDate,
      );
      // Reload simulation from backend
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan güncellenirken hata oluştu: $e')),
      );
    }
  }

  // ─── Delete Goal action
  Future<void> _onDeleteSelectedGoal() async {
    if (_selectedGoalId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Hedefi Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu finansal hedefi ve buna bağlı tüm analizleri silmek istediğine emin misin?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: AppColors.moodStressed)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FinancialGoalService.deleteGoal(_selectedGoalId!);
        setState(() {
          _selectedGoalId = null;
        });
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  // ─── Add Goal UI Bottom Sheet Form
  void _showAddGoalBottomSheet() {
    final titleController = TextEditingController();
    FinancialGoalType selectedType = FinancialGoalType.home;
    final priceController = TextEditingController();
    final savingsController = TextEditingController();
    final contributionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Yeni Hedef Oluştur 🎯',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: titleController,
                      label: 'Hedef Adı (örn: Yeni Ev)',
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<FinancialGoalType>(
                      label: 'Hedef Kategorisi',
                      value: selectedType,
                      items: FinancialGoalType.values.map((type) {
                        return DropdownMenuItem<FinancialGoalType>(
                          value: type,
                          child: Text('${type.emoji} ${type.label}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: priceController,
                      label: 'Hedef Fiyatı (TL)',
                      icon: Icons.monetization_on_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: savingsController,
                      label: 'Mevcut Birikim (TL)',
                      icon: Icons.savings_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: contributionController,
                      label: 'Aylık Tasarruf Katkısı (TL)',
                      icon: Icons.add_chart_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hedef Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().add(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('Tarih Seç'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        final title = titleController.text.trim();
                        final price = double.tryParse(priceController.text) ?? 0.0;
                        final savings = double.tryParse(savingsController.text) ?? 0.0;
                        final contribution = double.tryParse(contributionController.text) ?? 0.0;

                        if (title.isEmpty || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lütfen tüm alanları geçerli şekilde doldurun.'),
                              backgroundColor: AppColors.moodStressed,
                            ),
                          );
                          return;
                        }

                        try {
                          await FinancialGoalService.addGoal(
                            title: title,
                            type: selectedType.value,
                            currentPrice: price,
                            currentSavings: savings,
                            monthlyContribution: contribution,
                            targetDate: selectedDate,
                          );
                          Navigator.pop(context);
                          _loadData();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Hedef kaydedilirken hata oluştu: $e'),
                              backgroundColor: AppColors.moodStressed,
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.peachSkyGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Hedefi Oluştur',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.peach),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: const Color(0xFF161B22),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.peach),
        ),
      ),
    );
  }

  // ─── Spending Impact simulator Sheet
  void _showSpendingImpactBottomSheet(int goalId) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    int selectedCategory = 8; // Other
    SpendingImpactResponse? impactResult;
    bool isCalculating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Harcama Etki Analizi 💸',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu harcama hedefinizi kaç ay geciktirecek hesaplayalım.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (impactResult == null) ...[
                      _buildTextField(
                        controller: titleController,
                        label: 'Harcama Adı (örn: Yeni Telefon)',
                        icon: Icons.shopping_bag_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: amountController,
                        label: 'Harcama Tutarı (TL)',
                        icon: Icons.monetization_on_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown<int>(
                        label: 'Harcama Kategorisi',
                        value: selectedCategory,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('🍔 Yemek')),
                          DropdownMenuItem(value: 2, child: Text('🚌 Ulaşım')),
                          DropdownMenuItem(value: 3, child: Text('🏠 Kira')),
                          DropdownMenuItem(value: 4, child: Text('🛍️ Alışveriş')),
                          DropdownMenuItem(value: 5, child: Text('🎬 Eğlence')),
                          DropdownMenuItem(value: 6, child: Text('🧾 Faturalar')),
                          DropdownMenuItem(value: 7, child: Text('🎓 Eğitim')),
                          DropdownMenuItem(value: 8, child: Text('🏷️ Diğer')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          final title = titleController.text.trim();
                          final amount = double.tryParse(amountController.text) ?? 0.0;

                          if (title.isEmpty || amount <= 0) {
                            return;
                          }

                          setModalState(() => isCalculating = true);
                          try {
                            final res = await FinancialGoalService.simulateSpendingImpact(
                              goalId: goalId,
                              title: title,
                              category: selectedCategory,
                              amount: amount,
                            );
                            setModalState(() {
                              impactResult = res;
                              isCalculating = false;
                            });
                          } catch (e) {
                            setModalState(() => isCalculating = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata: $e')),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: AppColors.peachSkyGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: isCalculating
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Etkiyi Hesapla',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  impactResult!.analysis.expenseTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (impactResult!.analysis.impactLevel == 'Yuksek'
                                            ? AppColors.moodStressed
                                            : impactResult!.analysis.impactLevel == 'Orta'
                                                ? AppColors.peach
                                                : const Color(0xFF00E5A0))
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Etki: ${impactResult!.analysis.impactLevel == 'Yuksek' ? 'Yüksek' : impactResult!.analysis.impactLevel == 'Orta' ? 'Orta' : 'Düşük'}',
                                    style: TextStyle(
                                      color: impactResult!.analysis.impactLevel == 'Yuksek'
                                          ? AppColors.moodStressed
                                          : impactResult!.analysis.impactLevel == 'Orta'
                                              ? AppColors.peach
                                              : const Color(0xFF00E5A0),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            _buildImpactRow('Planlanan Harcama:', '₺${impactResult!.analysis.expenseAmount.toStringAsFixed(0)}'),
                            const SizedBox(height: 8),
                            _buildImpactRow('Tahmini Gecikme:', '${impactResult!.analysis.estimatedDelayMonths} Ay'),
                            const SizedBox(height: 8),
                            _buildImpactRow('Aylık Telafi Önerisi:', '₺${impactResult!.analysis.suggestedMonthlyOffset.toStringAsFixed(0)}'),
                            const SizedBox(height: 16),
                            const Text(
                              'AI Koçun Yorumu:',
                              style: TextStyle(
                                color: Color(0xFF00E5A0),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              impactResult!.aiMessage,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => setModalState(() => impactResult = null),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              'Yeni Hesaplama Yap',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImpactRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─── Custom Slider Thumb
class _GradientThumbShape extends SliderComponentShape {
  final Color color;
  const _GradientThumbShape({required this.color});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

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
