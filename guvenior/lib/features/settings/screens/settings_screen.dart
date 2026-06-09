import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/services/local_data_service.dart';
import '../../../core/utils/currency_format.dart';
import '../../expense/models/recurring_expense_model.dart';
import '../../expense/services/recurring_expense_service.dart';
import '../../auth/models/auth_model.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;

  double _monthlyIncome = 0;
  int _salaryDay = 1;
  List<RecurringExpense> _recurringExpenses = [];
  String _fullName = '';
  String _email = '';
  bool _isLoading = true;

  final Map<int, String> _categoryNames = {
    1: 'Yemek', 2: 'Ulaşım', 3: 'Kira', 4: 'Alışveriş',
    5: 'Eğlence', 6: 'Faturalar', 7: 'Eğitim', 8: 'Diğer',
  };
  final Map<int, IconData> _categoryIcons = {
    1: Icons.restaurant_outlined, 2: Icons.directions_bus_outlined,
    3: Icons.home_outlined, 4: Icons.shopping_bag_outlined,
    5: Icons.movie_outlined, 6: Icons.receipt_outlined,
    7: Icons.school_outlined, 8: Icons.more_horiz,
  };
  final Map<int, Color> _categoryColors = {
    1: const Color(0xFFFF9F43), 2: const Color(0xFF54A0FF),
    3: const Color(0xFF00E5A0), 4: const Color(0xFFFF6B9D),
    5: const Color(0xFFA29BFE), 6: const Color(0xFFFFB085),
    7: const Color(0xFF85C9FF), 8: const Color(0xFFB2BEC3),
  };

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    _loadData();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final results = await Future.wait([
      LocalDataService.getSalary(),
      LocalDataService.getSalaryDay(),
      RecurringExpenseService.getRecurringExpenses(),
    ]);
    setState(() {
      _monthlyIncome = results[0] as double;
      _salaryDay = results[1] as int;
      _recurringExpenses = results[2] as List<RecurringExpense>;
      _fullName = prefs.getString('fullName') ?? '';
      _email = prefs.getString('email') ?? '';
      _isLoading = false;
    });
  }

  // ─── Maaş Düzenleme ────────────────────────────────────────────────────────

  void _showSalarySheet() {
    final salaryCtrl =
        TextEditingController(text: _monthlyIncome > 0 ? _monthlyIncome.toStringAsFixed(0) : '');
    final dayCtrl =
        TextEditingController(text: _salaryDay > 0 ? '$_salaryDay' : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            Text('Aylık Gelir Bilgisi',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Aylık geliriniz her ay bütçenize eklenir.',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            const SizedBox(height: 20),
            _sheetField(salaryCtrl, 'Aylık Gelir (₺)', Icons.payments_outlined,
                keyboard: TextInputType.number, accent: AppColors.peach),
            const SizedBox(height: 12),
            _sheetField(dayCtrl, 'Gelir Günü (1–31)',
                Icons.calendar_today_outlined,
                keyboard: TextInputType.number, accent: AppColors.peach),
            const SizedBox(height: 24),
            _primaryButton('Kaydet', AppColors.peachSkyGradient, () async {
              final s = double.tryParse(salaryCtrl.text.trim());
              final d = int.tryParse(dayCtrl.text.trim());
              if (s != null && s > 0 && d != null && d >= 1 && d <= 31) {
                await AuthService.updateSalary(s, d);
              }
              if (mounted) Navigator.pop(context);
              _loadData();
            }),
          ],
        ),
      ),
    );
  }

  // ─── Tekrarlayan Gider ─────────────────────────────────────────────────────

  void _showAddRecurringSheet({RecurringExpense? editing}) {
    final titleCtrl =
        TextEditingController(text: editing?.title ?? '');
    final amountCtrl = TextEditingController(
        text: editing != null ? editing.amount.toStringAsFixed(0) : '');
    final dayCtrl =
        TextEditingController(text: editing != null ? '${editing.dayOfMonth}' : '');
    int category = editing?.category ?? 6;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              Text(
                editing == null ? 'Tekrarlayan Gider Ekle' : 'Gideri Düzenle',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Her ay otomatik olarak takvimde gösterilir.',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
              const SizedBox(height: 20),
              _sheetField(titleCtrl, 'Başlık (ör: Telefon Faturası)',
                  Icons.title, accent: AppColors.sky),
              const SizedBox(height: 12),
              _sheetField(amountCtrl, 'Tutar (₺)', Icons.payments_outlined,
                  keyboard: TextInputType.number, accent: AppColors.sky),
              const SizedBox(height: 12),
              _sheetField(dayCtrl, 'Her ayın kaçında? (1–31)',
                  Icons.repeat_rounded,
                  keyboard: TextInputType.number, accent: AppColors.sky),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: category,
                dropdownColor: const Color(0xFF1A2333),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Kategori', Icons.category_outlined, AppColors.sky),
                items: _categoryNames.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Row(children: [
                            Icon(_categoryIcons[e.key], size: 15,
                                color: _categoryColors[e.key]),
                            const SizedBox(width: 8),
                            Text(e.value),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setModal(() => category = v!),
              ),
              const SizedBox(height: 24),
              _primaryButton(
                editing == null ? 'Ekle' : 'Güncelle',
                LinearGradient(
                    colors: [AppColors.sky, AppColors.sky.withOpacity(0.7)]),
                () async {
                  final title = titleCtrl.text.trim();
                  final amount = double.tryParse(amountCtrl.text.trim());
                  final day = int.tryParse(dayCtrl.text.trim());
                  if (title.isEmpty || amount == null || day == null) return;
                  if (day < 1 || day > 31) return;

                  if (editing == null) {
                    await RecurringExpenseService.addRecurringExpense(
                      CreateRecurringExpenseRequest(
                        title: title,
                        amount: amount,
                        category: category,
                        dayOfMonth: day,
                      ),
                    );
                  } else {
                    await RecurringExpenseService.deleteRecurringExpense(editing.id);
                    await RecurringExpenseService.addRecurringExpense(
                      CreateRecurringExpenseRequest(
                        title: title, amount: amount,
                        category: category, dayOfMonth: day,
                      ),
                    );
                  }
                  if (mounted) Navigator.pop(context);
                  _loadData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRecurring(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu tekrarlayan gideri silmek istediğinize emin misiniz?',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Sil',
                  style: TextStyle(color: AppColors.moodStressed))),
        ],
      ),
    );
    if (confirm == true) {
      await RecurringExpenseService.deleteRecurringExpense(id);
      _loadData();
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (ctx, child) {
        final t = _bgController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 0.4, -1),
              end: Alignment(1 - t * 0.4, 1),
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
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.peach))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildAccountCard(),
                    const SizedBox(height: 16),
                    _buildSalaryCard(),
                    const SizedBox(height: 16),
                    _buildRecurringSection(),
                    const SizedBox(height: 24),
                    _buildLogoutButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.peachSkyGradient.createShader(b),
          child: Text('Ayarlar',
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 6),
        Text('Hesap bilgileri ve finansal yapılandırma.',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
      ],
    );
  }

  Widget _buildAccountCard() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.peachSkyGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'G',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fullName,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(_email,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5A0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00E5A0).withOpacity(0.3)),
            ),
            child: const Text('Aktif',
                style: TextStyle(
                    color: Color(0xFF00E5A0), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('GELİR BİLGİSİ', AppColors.peach),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _infoChip(
                  'Aylık Gelir',
                  _monthlyIncome > 0 ? CurrencyFormatter.format(_monthlyIncome) : 'Girilmedi',
                  AppColors.peach,
                  Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoChip(
                  'Gelir Günü',
                  'Her ayın $_salaryDay. günü',
                  AppColors.sky,
                  Icons.calendar_today_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showSalarySheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.peach.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.peach.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined, color: AppColors.peach, size: 16),
                  const SizedBox(width: 6),
                  Text('Maaş Bilgisini Düzenle',
                      style: TextStyle(
                          color: AppColors.peach, fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('TEKRARLAYAN GİDERLER', AppColors.sky),
            const Spacer(),
            GestureDetector(
              onTap: () => _showAddRecurringSheet(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.sky, AppColors.sky.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Ekle', style: TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recurringExpenses.isEmpty)
          GlassCard(
            child: Column(
              children: [
                Icon(Icons.repeat, color: Colors.white.withOpacity(0.2), size: 36),
                const SizedBox(height: 8),
                Text('Henüz tekrarlayan gider yok.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 13)),
                const SizedBox(height: 4),
                Text('Kira, fatura gibi aylık giderlerini buraya ekle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.25), fontSize: 11)),
              ],
            ),
          )
        else
          ..._recurringExpenses.map((r) => _buildRecurringTile(r)),
      ],
    );
  }

  Widget _buildRecurringTile(RecurringExpense r) {
    final color = _categoryColors[r.category] ?? Colors.white54;
    final icon = _categoryIcons[r.category] ?? Icons.more_horiz;
    final catName = _categoryNames[r.category] ?? 'Diğer';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('$catName • Her ayın ${r.dayOfMonth}. günü',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 11)),
                ],
              ),
            ),
            Text(CurrencyFormatter.format(r.amount),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showAddRecurringSheet(editing: r),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.sky.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_outlined, color: AppColors.sky, size: 15),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _deleteRecurring(r.id),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.moodStressed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline, color: AppColors.moodStressed, size: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.moodStressed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.moodStressed.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.moodStressed, size: 18),
            const SizedBox(width: 8),
            Text('Çıkış Yap',
                style: TextStyle(
                    color: AppColors.moodStressed, fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _sheetHandle() => Center(
        child: Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(2)),
        ),
      );

  Widget _sectionLabel(String label, Color color) => Text(
        label,
        style: TextStyle(
            color: color.withOpacity(0.7), fontSize: 10,
            fontWeight: FontWeight.w700, letterSpacing: 1.4),
      );

  Widget _infoChip(String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _primaryButton(String label, Gradient gradient, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
              gradient: gradient, borderRadius: BorderRadius.circular(14)),
          child: Center(
            child: Text(label,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      );

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    required Color accent,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: _inputDeco(label, icon, accent),
      );

  InputDecoration _inputDeco(String label, IconData icon, Color accent) =>
      InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent, width: 1.5)),
      );
}
