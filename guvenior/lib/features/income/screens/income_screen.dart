import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/services/local_data_service.dart';
import '../../../core/utils/currency_format.dart';
import '../models/income_model.dart';
import '../services/income_service.dart';
import '../../auth/services/auth_service.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen>
    with TickerProviderStateMixin {
  List<Income> _incomes = [];
  bool _isLoading = false;
  double _monthlyIncome = 0;
  int _salaryDay = 1;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  int _selectedType = 5; // Default to 'Diğer'
  DateTime _selectedDate = DateTime.now();

  late AnimationController _bgController;

  final Map<int, String> _incomeTypes = {
    1: 'Maaş',
    2: 'Freelance',
    3: 'Burs',
    4: 'Aile Desteği',
    5: 'Diğer',
  };

  final Map<int, IconData> _typeIcons = {
    1: Icons.work_outline,
    2: Icons.laptop_outlined,
    3: Icons.school_outlined,
    4: Icons.favorite_outline,
    5: Icons.more_horiz,
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
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Sync salary from backend first
      await AuthService.getProfile();
      
      final results = await Future.wait([
        IncomeService.getIncomes(),
        LocalDataService.getSalary(),
        LocalDataService.getSalaryDay(),
      ]);
      
      setState(() {
        _incomes = results[0] as List<Income>;
        _monthlyIncome = results[1] as double;
        _salaryDay = results[2] as int;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading income data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addIncome() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;

    try {
      await IncomeService.addIncome(
        CreateIncomeRequest(
          title: _titleController.text.trim(),
          amount: amount,
          receivedDate: _selectedDate,
          type: _selectedType,
        ),
      );
      _titleController.clear();
      _amountController.clear();
      if (mounted) Navigator.pop(context);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gelir eklenemedi: $e'), backgroundColor: AppColors.moodStressed),
        );
      }
    }
  }

  Future<void> _deleteIncome(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Geliri Sil', style: TextStyle(color: Colors.white)),
        content: const Text('Bu geliri silmek istediğine emin misin?', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Sil', style: TextStyle(color: AppColors.moodStressed))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await IncomeService.deleteIncome(id);
        _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Silinemedi: $e')));
      }
    }
  }

  void _showAddIncomeSheet() {
    _selectedType = 5;
    _selectedDate = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHeader('Gelir Ekle'),
              const SizedBox(height: 24),
              _buildField(controller: _titleController, label: 'Başlık', icon: Icons.title),
              const SizedBox(height: 14),
              _buildField(controller: _amountController, label: 'Tutar (₺)', icon: Icons.payments_outlined, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _selectedType,
                dropdownColor: const Color(0xFF1A2333),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Gelir Türü', Icons.category_outlined),
                items: _incomeTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Row(children: [Icon(_typeIcons[e.key], size: 16, color: AppColors.peach), const SizedBox(width: 8), Text(e.value)]))).toList(),
                onChanged: (val) => setModalState(() => _selectedType = val!),
              ),
              const SizedBox(height: 14),
              _datePicker(setModalState),
              const SizedBox(height: 24),
              GradientButton(text: 'Geliri Ekle', onPressed: _addIncome, gradient: AppColors.peachSkyGradient),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetHeader(String title) => Row(children: [Container(width: 4, height: 24, decoration: BoxDecoration(gradient: AppColors.peachSkyGradient, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]);

  Widget _datePicker(Function setModalState) => GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now(), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.peach)), child: child!));
      if (picked != null) setModalState(() => _selectedDate = picked);
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(children: [const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 18), const SizedBox(width: 12), Text(DateFormat('dd MMMM yyyy', 'tr').format(_selectedDate), style: const TextStyle(color: Colors.white, fontSize: 15))]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
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
            _buildBgDecor(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: AppColors.peach))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              if (_monthlyIncome > 0) _buildSalaryCard(),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('DİĞER GELİRLER', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                              ),
                              if (_incomes.isEmpty)
                                _buildEmptyState()
                              else
                                ..._incomes.map((i) => _buildIncomeTile(i)),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddIncomeSheet, backgroundColor: AppColors.peach, child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  Widget _buildBgDecor() => Positioned(top: -80, right: -60, child: AnimatedBuilder(animation: _bgController, builder: (_, __) => Transform.scale(scale: 1 + _bgController.value * 0.2, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.peach.withOpacity(0.12), Colors.transparent]))))));

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))), child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
        ),
        const SizedBox(width: 16),
        Text('Gelirlerim', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const Spacer(),
        _totalBalanceChip(),
      ],
    ),
  );

  Widget _totalBalanceChip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppColors.peach.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.peach.withOpacity(0.3))),
    child: Text(CurrencyFormatter.format(_incomes.fold(0.0, (s, i) => s + i.amount) + _monthlyIncome), style: const TextStyle(color: AppColors.peach, fontSize: 13, fontWeight: FontWeight.w700)),
  );

  Widget _buildSalaryCard() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.peach.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.peach.withOpacity(0.3))), child: const Icon(Icons.work_outline, color: AppColors.peach, size: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aylık Maaş (Sabit)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Backend üzerinden senkronize • Her ayın $_salaryDay. günü', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
              ],
            ),
          ),
          Text(CurrencyFormatter.format(_monthlyIncome), style: const TextStyle(color: AppColors.peach, fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    ),
  );

  Widget _buildIncomeTile(Income income) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.peach.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.peach.withOpacity(0.3))), child: Icon(_typeIcons[income.type] ?? Icons.attach_money, color: AppColors.peach, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(income.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 4), Text('${_incomeTypes[income.type] ?? 'Diğer'} • ${DateFormat('dd MMM yyyy', 'tr').format(income.receivedDate)}', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11))])),
          Text(CurrencyFormatter.format(income.amount), style: const TextStyle(color: AppColors.peach, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(width: 12),
          GestureDetector(onTap: () => _deleteIncome(income.id), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.moodStressed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_outline, color: AppColors.moodStressed, size: 18))),
        ],
      ),
    ),
  );

  Widget _buildEmptyState() => Center(child: Padding(padding: const EdgeInsets.only(top: 60), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.white.withOpacity(0.2)), const SizedBox(height: 16), Text('Henüz başka gelir eklenmedi.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14))])));

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(labelText: label, labelStyle: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14), prefixIcon: Icon(icon, color: Colors.white38, size: 20), filled: true, fillColor: Colors.white.withOpacity(0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.peach, width: 1.5)));

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool obscure = false, TextInputType? keyboardType}) => TextField(controller: controller, obscureText: obscure, keyboardType: keyboardType, style: const TextStyle(color: Colors.white, fontSize: 15), decoration: _inputDecoration(label, icon));
}
