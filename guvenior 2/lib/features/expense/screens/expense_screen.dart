import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/services/local_data_service.dart';
import '../models/expense_model.dart';
import '../models/recurring_expense_model.dart';
import '../services/expense_service.dart';
import '../services/recurring_expense_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen>
    with TickerProviderStateMixin {
  List<Expense> _expenses = [];
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  int _selectedCategory = 1;
  DateTime _selectedDate = DateTime.now();

  // Tekrarlayan gider durumu (sheet içinde kullanılır)
  bool _isRecurring = false;
  int _recurringDay = 1;

  // Tekrarlayan olabilecek kategoriler
  static const _recurringEligible = {3, 5, 6, 7}; // Kira, Eğlence, Faturalar, Eğitim

  late AnimationController _bgController;

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

  final Map<int, IconData> _categoryIcons = {
    1: Icons.restaurant_outlined,
    2: Icons.directions_bus_outlined,
    3: Icons.home_outlined,
    4: Icons.shopping_bag_outlined,
    5: Icons.movie_outlined,
    6: Icons.receipt_outlined,
    7: Icons.school_outlined,
    8: Icons.more_horiz,
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
    _loadExpenses();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await ExpenseService.getExpenses();
      setState(() => _expenses = expenses);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Harcamalar yüklenemedi.'),
            backgroundColor: AppColors.moodStressed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addExpense() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null) return;
    try {
      await ExpenseService.addExpense(
        CreateExpenseRequest(
          title: _titleController.text.trim(),
          amount: amount,
          spentAt: _selectedDate,
          category: _selectedCategory,
        ),
      );
      // Tekrarlayan gider olarak da kaydet
      if (_isRecurring) {
        await RecurringExpenseService.addRecurringExpense(
          CreateRecurringExpenseRequest(
            title: _titleController.text.trim(),
            amount: amount,
            category: _selectedCategory,
            dayOfMonth: _recurringDay,
          )
        );
      }
      _titleController.clear();
      _amountController.clear();
      _isRecurring = false;
      _recurringDay = 1;
      Navigator.pop(context);
      _loadExpenses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Harcama eklenemedi.'),
            backgroundColor: AppColors.moodStressed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showAddExpenseSheet() {
    _isRecurring = false;
    _recurringDay = DateTime.now().day;
    _selectedCategory = 1;
    _selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 4, height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.sky, AppColors.sky.withOpacity(0.6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Harcama Ekle',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: _titleController,
                label: 'Başlık',
                icon: Icons.title,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _amountController,
                label: 'Tutar (₺)',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF1A2333),
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Kategori', Icons.category_outlined),
                items: _categories.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Row(children: [
                            Icon(_categoryIcons[e.key], size: 16,
                                color: _categoryColors[e.key]),
                            const SizedBox(width: 8),
                            Text(e.value),
                          ]),
                        ))
                    .toList(),
                onChanged: (val) {
                  setModal(() {
                    _selectedCategory = val!;
                    // Tekrarlayan seçeneği eligible değilse sıfırla
                    if (!_recurringEligible.contains(_selectedCategory)) {
                      _isRecurring = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              // Tarih seçici
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.sky,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.white38, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMMM yyyy', 'tr').format(_selectedDate),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ]),
                ),
              ),
              // ─── Tekrarlayan toggle (sadece eligible kategorilerde) ────────
              if (_recurringEligible.contains(_selectedCategory)) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isRecurring
                        ? const Color(0xFFA29BFE).withOpacity(0.12)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isRecurring
                          ? const Color(0xFFA29BFE).withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.repeat_rounded,
                              color: Color(0xFFA29BFE), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tekrarlayan Gider mi?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Her ay otomatik takvime eklensin',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isRecurring,
                            onChanged: (v) =>
                                setModal(() => _isRecurring = v),
                            activeColor: const Color(0xFFA29BFE),
                            inactiveTrackColor:
                                Colors.white.withOpacity(0.1),
                          ),
                        ],
                      ),
                      // Her ayın kaçında?
                      if (_isRecurring) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_repeat_rounded,
                                  color: Color(0xFFA29BFE), size: 16),
                              const SizedBox(width: 10),
                              Text(
                                'Her ayın $_recurringDay. günü',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                              const Spacer(),
                              Row(children: [
                                GestureDetector(
                                  onTap: () => setModal(() {
                                    if (_recurringDay > 1) _recurringDay--;
                                  }),
                                  child: Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.remove,
                                        color: Colors.white54, size: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                  child: Text('$_recurringDay',
                                    style: const TextStyle(
                                      color: Color(0xFFA29BFE),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    )),
                                ),
                                GestureDetector(
                                  onTap: () => setModal(() {
                                    if (_recurringDay < 31) _recurringDay++;
                                  }),
                                  child: Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.add,
                                        color: Colors.white54, size: 16),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              GradientButton(
                text: 'Harcamayı Ekle',
                onPressed: _addExpense,
                gradient: LinearGradient(
                  colors: [AppColors.sky, AppColors.sky.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.45),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sky, width: 1.5),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: _inputDecoration(label, icon),
    );
  }

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
              left: -60,
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, __) => Transform.scale(
                  scale: 1 + _bgController.value * 0.2,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.sky.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Harcamalarım',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sky.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.sky.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            CurrencyFormatter.format(_expenses.fold(0.0, (s, e) => s + e.amount)),
                            style: TextStyle(
                              color: AppColors.sky,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.sky,
                            ),
                          )
                        : _expenses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Henüz harcama eklenmedi.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _expenses.length,
                            itemBuilder: (_, i) {
                              final expense = _expenses[i];
                              final color =
                                  _categoryColors[expense.category] ??
                                  Colors.white54;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: color.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Icon(
                                          _categoryIcons[expense.category] ??
                                              Icons.more_horiz,
                                          color: color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              expense.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_categories[expense.category] ?? 'Diğer'} • ${DateFormat('dd MMM yyyy', 'tr').format(expense.spentAt)}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.45,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '-${CurrencyFormatter.format(expense.amount)}',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseSheet,
        backgroundColor: AppColors.sky,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
