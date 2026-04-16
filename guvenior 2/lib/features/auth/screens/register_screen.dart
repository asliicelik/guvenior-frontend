import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _monthlyIncomeController = MoneyMaskedTextController(
    decimalSeparator: '',
    thousandSeparator: '.',
    precision: 0,
    rightSymbol: ' ₺',
  );
  final _salaryDayController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  int _currentPage = 0;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _bgController;

  final List<Color> _bgColors = [
    const Color(0xFF1A0D2E),
    const Color(0xFF0D1A2E),
    const Color(0xFF0D1A1A),
  ];

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeIn,
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _slideController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _monthlyIncomeController.dispose();
    _salaryDayController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.moodStressed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _nextPage() async {
    if (_currentPage == 0 && _fullNameController.text.trim().isEmpty) {
      _showError('Lütfen adınızı girin.');
      return;
    }
    if (_currentPage == 1) {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        _showError('Lütfen e-posta ve şifre girin.');
        return;
      }
      if (_passwordController.text.trim().length < 6) {
        _showError('Şifre en az 6 karakter olmalı.');
        return;
      }
    }

    await _slideController.reverse();
    setState(() => _currentPage++);
    _slideController.forward();
  }

  Future<void> _prevPage() async {
    await _slideController.reverse();
    setState(() => _currentPage--);
    _slideController.forward();
  }

  Future<void> _register() async {
    if (_monthlyIncomeController.numberValue == 0) {
      _showError('Lütfen aylık gelirinizi girin.');
      return;
    }
    if (_salaryDayController.text.trim().isEmpty) {
      _showError('Lütfen maaş gününüzü girin.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        RegisterRequest(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          monthlyIncome: _monthlyIncomeController.numberValue,
          salaryDay: int.tryParse(_salaryDayController.text.trim()) ?? 1,
        ),
        monthlyIncome: _monthlyIncomeController.numberValue,
        salaryDay: int.tryParse(_salaryDayController.text.trim()) ?? 1,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      _showError('Kayıt başarısız. Bilgileri kontrol edin.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color get _accentColor =>
      [AppColors.peach, AppColors.sky, const Color(0xFF00E5A0)][_currentPage];

  Color get _bgColor => _bgColors[_currentPage];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgColor, Color.lerp(_bgColor, Colors.black, 0.5)!],
          ),
        ),
        child: Stack(
          children: [
            // Glow efekti
            Positioned(
              top: -100,
              right: -80,
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, __) => Transform.scale(
                  scale: 1 + _bgController.value * 0.15,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _accentColor.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Üst bar
                    Row(
                      children: [
                        if (_currentPage > 0)
                          GestureDetector(
                            onTap: _prevPage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        const Spacer(),
                        // Adım göstergesi
                        Row(
                          children: List.generate(
                            3,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(left: 6),
                              width: i == _currentPage ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _currentPage
                                    ? _accentColor
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.06),
                    // İkon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(_currentPage),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentColor.withOpacity(0.15),
                          border: Border.all(
                            color: _accentColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          [
                            Icons.person_outline,
                            Icons.email_outlined,
                            Icons.account_balance_wallet_outlined,
                          ][_currentPage],
                          size: 36,
                          color: _accentColor,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    // Başlık + form - slide animasyonu
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTitle(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getSubtitle(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.04),
                              ..._getFields(),
                              const Spacer(),
                              GradientButton(
                                text: _currentPage < 2
                                    ? 'Devam Et →'
                                    : (_isLoading
                                          ? 'Kaydediliyor...'
                                          : 'Başlayalım'),
                                onPressed: _currentPage < 2
                                    ? _nextPage
                                    : _register,
                                gradient: LinearGradient(
                                  colors: [
                                    _accentColor,
                                    _accentColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentPage) {
      case 0:
        return 'Merhaba!\nSeni tanıyalım';
      case 1:
        return 'Hesabını\noluşturalım';
      case 2:
        return 'Son adım!\nGelirini girelim';
      default:
        return '';
    }
  }

  String _getSubtitle() {
    switch (_currentPage) {
      case 0:
        return 'Adın ne? Seni nasıl çağıralım?';
      case 1:
        return 'E-posta ve şifreni belirle.';
      case 2:
        return 'Aylık gelirini ve maaş gününü gir.';
      default:
        return '';
    }
  }

  List<Widget> _getFields() {
    switch (_currentPage) {
      case 0:
        return [
          _buildField(
            controller: _fullNameController,
            label: 'Ad Soyad',
            icon: Icons.badge_outlined,
          ),
        ];
      case 1:
        return [
          _buildField(
            controller: _emailController,
            label: 'E-posta',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _passwordController,
            label: 'Şifre',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ];
      case 2:
        return [
          _buildField(
            controller: _monthlyIncomeController,
            label: 'Aylık Gelir',
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _salaryDayController,
            label: 'Maaş Günü (1-31)',
            icon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
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
          borderSide: BorderSide(color: _accentColor, width: 1.5),
        ),
      ),
    );
  }
}
