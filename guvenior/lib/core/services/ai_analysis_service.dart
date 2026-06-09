import 'dart:math';
import '../../features/expense/models/expense_model.dart';

enum NudgeType { warning, info, success, danger }

class AiNudge {
  final String title;
  final String message;
  final NudgeType type;
  final String emoji;

  AiNudge({
    required this.title,
    required this.message,
    required this.type,
    required this.emoji,
  });
}

class AiAnalysisService {
  /// Calculates the total spending in the first 48 hours after receiving the salary,
  /// for the current/most recent salary cycle.
  static double calculateCurrentSalaryPost48hSpending(
    List<Expense> expenses,
    double salary,
    int salaryDay,
  ) {
    if (expenses.isEmpty || salary <= 0) return 0.0;

    final now = DateTime.now();
    // Determine the start date of the latest salary cycle
    DateTime salaryDate = DateTime(now.year, now.month, salaryDay);
    if (now.isBefore(salaryDate)) {
      // If we haven't reached salaryDay this month, the cycle started last month
      int prevMonth = now.month - 1;
      int prevYear = now.year;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear -= 1;
      }
      salaryDate = DateTime(prevYear, prevMonth, salaryDay);
    }

    final windowEnd = salaryDate.add(const Duration(hours: 48));

    double total = 0.0;
    for (final e in expenses) {
      if (e.spentAt.isAfter(salaryDate.subtract(const Duration(seconds: 1))) &&
          e.spentAt.isBefore(windowEnd.add(const Duration(seconds: 1)))) {
        total += e.amount;
      }
    }
    return total;
  }

  /// Calculates the spending in the first 48 hours of the previous salary cycle for comparison
  static double calculatePreviousSalaryPost48hSpending(
    List<Expense> expenses,
    double salary,
    int salaryDay,
  ) {
    if (expenses.isEmpty || salary <= 0) return 0.0;

    final now = DateTime.now();
    DateTime salaryDate = DateTime(now.year, now.month, salaryDay);
    if (now.isBefore(salaryDate)) {
      int prevMonth = now.month - 1;
      int prevYear = now.year;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear -= 1;
      }
      salaryDate = DateTime(prevYear, prevMonth, salaryDay);
    }

    // Now subtract 1 month from current cycle's salary date to find the previous one
    int prevMonth = salaryDate.month - 1;
    int prevYear = salaryDate.year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear -= 1;
    }
    DateTime prevSalaryDate = DateTime(prevYear, prevMonth, salaryDay);
    final prevWindowEnd = prevSalaryDate.add(const Duration(hours: 48));

    double total = 0.0;
    for (final e in expenses) {
      if (e.spentAt.isAfter(prevSalaryDate.subtract(const Duration(seconds: 1))) &&
          e.spentAt.isBefore(prevWindowEnd.add(const Duration(seconds: 1)))) {
        total += e.amount;
      }
    }
    return total;
  }

  /// Detects if there has been a sudden surge (spike) in spending in the last 7 days.
  /// A surge is defined as a single day spending that is > 2.5 times the average daily spending.
  static Map<String, dynamic>? detectSuddenSpendingSurge(List<Expense> expenses) {
    if (expenses.isEmpty) return null;

    // Group expenses by day (yyyy-MM-dd)
    final dailyTotals = <String, double>{};
    for (final e in expenses) {
      final dateStr = '${e.spentAt.year}-${e.spentAt.month.toString().padLeft(2, '0')}-${e.spentAt.day.toString().padLeft(2, '0')}';
      dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0) + e.amount;
    }

    if (dailyTotals.isEmpty) return null;

    final totalSpent = dailyTotals.values.reduce((a, b) => a + b);
    final averageDaily = totalSpent / dailyTotals.length;

    // Sort days to find the latest surge in the last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    String? surgeDate;
    double surgeAmount = 0.0;

    for (final entry in dailyTotals.entries) {
      final parts = entry.key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      
      if (date.isAfter(sevenDaysAgo) && entry.value > (averageDaily * 2.5) && entry.value > 500) {
        if (entry.value > surgeAmount) {
          surgeAmount = entry.value;
          surgeDate = entry.key;
        }
      }
    }

    if (surgeDate != null) {
      return {
        'date': surgeDate,
        'amount': surgeAmount,
        'multiplier': averageDaily > 0 ? (surgeAmount / averageDaily).toStringAsFixed(1) : '2.5',
      };
    }
    return null;
  }

  /// Generates dynamic, youth-friendly, non-judgmental financial nudges.
  /// If a live AI backend were connected, this would call a post endpoint,
  /// but our smart local parser acts as a robust fail-safe client-side AI.
  static List<AiNudge> generateNudges({
    required List<Expense> expenses,
    required double salary,
    required int salaryDay,
  }) {
    final nudges = <AiNudge>[];

    if (expenses.isEmpty) {
      nudges.add(AiNudge(
        title: 'İlk Adımı Atalım! 🚀',
        message: 'Harcamalarını girmeye başla, sana özel analizler ve eğlenceli ipuçları hazırlayayım! Birlikte harika işler çıkaracağız.',
        type: NudgeType.info,
        emoji: '🌱',
      ));
      return nudges;
    }

    final totalExpense = expenses.fold(0.0, (s, e) => s + e.amount);

    // 1. Post-Salary 48h Spending Nudge
    final post48h = calculateCurrentSalaryPost48hSpending(expenses, salary, salaryDay);
    if (salary > 0 && post48h > 0) {
      final ratio = post48h / salary;
      final prevPost48h = calculatePreviousSalaryPost48hSpending(expenses, salary, salaryDay);
      
      if (ratio > 0.15) {
        String msg = 'Maaş yatar yatmaz harcamalar bir tık hızlı başlamış sanki? 😉 Maaşının ilk 48 saatinde %${(ratio * 100).toStringAsFixed(0)}\'ini (₺${post48h.toStringAsFixed(0)}) harcamışsın.';
        if (prevPost48h > 0 && post48h > prevPost48h) {
          msg += ' Geçen aya göre maaş sonrası harcaman da artmış. Önümüzdeki günlerde kartı biraz nadasa mı bıraksak?';
        } else {
          msg += ' Harika bütçen için ilk günlerde biraz frene basmak ay sonu elini aşırı rahatlatır!';
        }
        
        nudges.add(AiNudge(
          title: 'Maaş Sonrası Hızlı Başlangıç 💸',
          message: msg,
          type: NudgeType.warning,
          emoji: '⚡',
        ));
      }
    }

    // 2. Night Shopping Nudge
    final nightTotal = expenses
        .where((e) => e.spentAt.hour >= 21 || e.spentAt.hour <= 4)
        .fold(0.0, (s, e) => s + e.amount);
    final nightRatio = totalExpense > 0 ? nightTotal / totalExpense : 0.0;
    if (nightRatio > 0.20 && nightTotal > 200) {
      nudges.add(AiNudge(
        title: 'Gece Alışverişleri Alarmı 🌙',
        message: 'Gece gelen o sepeti onaylama isteği... Biliyoruz ama gece alışverişlerin bütçenin %${(nightRatio * 100).toStringAsFixed(0)}\'ini (₺${nightTotal.toStringAsFixed(0)}) götürmüş. Gece 21:00\'den sonra beğendiklerini sepette bekletip sabah tekrar değerlendirmeye ne dersin?',
        type: NudgeType.warning,
        emoji: '🛒',
      ));
    }

    // 3. Sudden Surge Nudge
    final surge = detectSuddenSpendingSurge(expenses);
    if (surge != null) {
      nudges.add(AiNudge(
        title: 'Ani Harcama Tespit Edildi! 🚨',
        message: 'Yakın zamanda günlük ortalamanın ${surge['multiplier']} katı tutarında ani bir harcama (₺${(surge['amount'] as double).toStringAsFixed(0)}) yaptığını fark ettim. Acil bir durum değilse, bu tür ani kararlardan önce 24 saat kuralını uygulamak cüzdanını çok rahatlatır.',
        type: NudgeType.danger,
        emoji: '🔥',
      ));
    }

    // 4. Category Dominance/Limit Nudge
    final categoryTotals = <int, double>{};
    for (final e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }
    final categoriesMap = {
      1: 'Yemek',
      2: 'Ulaşım',
      3: 'Kira',
      4: 'Alışveriş',
      5: 'Eğlence',
      6: 'Faturalar',
      7: 'Eğitim',
      8: 'Diğer',
    };

    int? dominantCategory;
    double maxCategorySpent = 0.0;
    for (final entry in categoryTotals.entries) {
      if (entry.value > maxCategorySpent && entry.key != 3) { // Exclude Rent (Kira) as it is fixed
        maxCategorySpent = entry.value;
        dominantCategory = entry.key;
      }
    }

    if (dominantCategory != null && totalExpense > 0) {
      final catRatio = maxCategorySpent / totalExpense;
      if (catRatio > 0.35) {
        final catName = categoriesMap[dominantCategory] ?? 'Diğer';
        nudges.add(AiNudge(
          title: '$catName Sınırına Yaklaştın! ⚠️',
          message: 'Bu ay ev hariç bütçenin aslan payını (%${(catRatio * 100).toStringAsFixed(0)}) $catName kategorisi kapmış. Bu kategoride harcama yaparken hedeflerini hatırla. Bir sonraki harcamada kendini durdurabilirsin, sana güveniyoruz! 🌸',
          type: NudgeType.warning,
          emoji: '🎯',
        ));
      }
    }

    // 5. Positive / Balance Nudge (Fallback if everything is in perfect order)
    if (nudges.isEmpty || (nightRatio < 0.15 && post48h < (salary * 0.10))) {
      nudges.add(AiNudge(
        title: 'Bütçe Sihirbazı! 🧙‍♂️✨',
        message: 'Harcamalarını mükemmel dengeliyorsun! Gece alışverişlerin yok denecek kadar az, maaş sonrası harcamaların ise gayet makul. Finansal geleceğini güvenceye alıyorsun, harika gidiyorsun!',
        type: NudgeType.success,
        emoji: '💎',
      ));
    }

    return nudges;
  }

  /// Dynamic AI interpretations for Life Plan Simulations with Turkey's inflation impact.
  static Map<String, dynamic> interpretSimulation({
    required String goalLabel,
    required double monthlyIncome,
    required double monthlyContribution,
    required double currentSavings,
    required double targetMonths,
    required double successProbability,
    required double defaultTarget,
  }) {
    // Sabit Gider Oranı (Fixed Expense Ratio)
    final fixedRatio = monthlyIncome > 0 ? (monthlyContribution / monthlyIncome) : 0.0;
    final fixedRatioPercent = (fixedRatio * 100).round();

    // Sürdürülebilirlik Puanı (Sustainability Rating)
    String sustainability;
    String sustainabilityDesc;
    if (fixedRatio <= 0.20) {
      sustainability = 'Yüksek Sürdürülebilirlik';
      sustainabilityDesc = 'Bu tasarruf oranı gelirinize göre son derece sağlıklı. Yaşam kalitenizi bozmadan bu hedefi sürdürebilirsiniz.';
    } else if (fixedRatio <= 0.40) {
      sustainability = 'Dengeli Sürdürülebilirlik';
      sustainabilityDesc = 'Gelirinizin önemli bir kısmını bu hedefe ayırıyorsunuz. Diğer harcamalarınızı biraz kısmanız gerekebilir ancak yapılabilir durumdadır.';
    } else {
      sustainability = 'Riskli Sürdürülebilirlik';
      sustainabilityDesc = 'Aylık gelirinizin %$fixedRatioPercent\'ini tek bir hedefe ayırmak bütçenizi çok zorlayabilir. Olası bir acil durumda nakit sıkışıklığı yaşayabilirsiniz.';
    }

    // ─── Enflasyon Hesaplamaları (Turkey Asset Inflation ~45% annually)
    const double inflationRate = 0.45;
    final double years = targetMonths / 12;
    final double futureTarget = defaultTarget * pow(1 + inflationRate, years);

    // Savings growth with standard ~8% cash compound yield
    final double projectedSavings = currentSavings + (monthlyContribution * targetMonths * 1.08);
    final double inflationRatio = (projectedSavings / futureTarget).clamp(0.0, 1.0);
    final double inflationSuccessProb = 1 / (1 + exp(-10 * (inflationRatio - 0.7)));
    final int inflationSuccessPercent = (inflationSuccessProb * 100).round();

    String formatTL(double amount) {
      if (amount >= 1000000) {
        return '${(amount / 1000000).toStringAsFixed(2)}M ₺';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(0)}K ₺';
      }
      return '${amount.toStringAsFixed(0)} ₺';
    }

    final originalTargetStr = formatTL(defaultTarget);
    final futureTargetStr = formatTL(futureTarget);

    // AI advice text in a supportive youth-friendly tone incorporating inflation
    String advice;
    if (inflationSuccessPercent >= 70) {
      advice = 'Efsane bir planlama! 🎯 Bugün $originalTargetStr olan $goalLabel hedefin, yıllık %45 enflasyonla ${targetMonths.toInt()} ay sonra yaklaşık **$futureTargetStr** olacak. Ama sen paranı harika biriktiriyorsun ve enflasyona rağmen başarı şansın **%$inflationSuccessPercent**! Birikimlerini altın, hisse senedi veya fon gibi enflasyon korumalı araçlarda değerlendirerek bu başarıyı garantileyebilirsin. 💎🚀';
    } else if (inflationSuccessPercent >= 45) {
      advice = 'İyi yoldasın ama Türkiye\'deki enflasyon gerçeği planlarını biraz zorlaştırıyor! 📈 Bugün $originalTargetStr olan $goalLabel hedefin, %45 yıllık enflasyon etkisiyle ${targetMonths.toInt()} ay sonra **$futureTargetStr** seviyesine çıkacak. Bu da başarı olasılığını **%$inflationSuccessPercent** seviyesine çekiyor. Başarı şansını arttırmak için aylık katkını her yıl enflasyon oranında artırmanı (endekslemeni) ve birikimlerini mutlaka yatırım fonlarında değerlendirmeni öneriyorum. 😉';
    } else if (inflationSuccessPercent >= 20) {
      advice = 'Enflasyon dalgası bütçeni biraz zorluyor! ⚠️ Bugün $originalTargetStr olan $goalLabel hedefin, ${targetMonths.toInt()} ay sonra enflasyonla **$futureTargetStr** olacak! Birikimlerin TL mevduatta kalırsa alım gücün eriyebilir ve başarı şansın **%$inflationSuccessPercent**\'e düşebilir. AI koçun olarak tavsiyem: Aylık katkını biraz artır, hedef süresini uzat veya birikimlerini yüksek getirili yatırım sepetlerinde değerlendirmeyi dene. Adım adım gidelim! 🧘‍♂️';
    } else {
      advice = 'Ciddi bir enflasyon alarmı! 🚨 Türkiye\'deki %45 yıllık varlık enflasyonuyla bugün $originalTargetStr olan $goalLabel hedefin, ${targetMonths.toInt()} ay sonra tam **$futureTargetStr** olacak! 🤯 Bu fiyat artış hızı karşısında mevcut birikim planınla başarı şansın maalesef **%$inflationSuccessPercent** seviyesinde kalıyor. Bu hedefe ulaşmak için ya hedef bütçesini düşürmeli, ya süreyi uzatmalı, ya da paranı kesinlikle enflasyon üstü getiri sunan (hisse, altın, Eurobond vb. 📊) sepetlerde büyütmelisin! Pes etmek yok, akıllıca planlayacağız! ❤️';
    }

    return {
      'fixedRatio': fixedRatioPercent,
      'sustainability': sustainability,
      'sustainabilityDesc': sustainabilityDesc,
      'advice': advice,
      'futureTarget': futureTarget,
      'futureTargetStr': futureTargetStr,
      'inflationSuccessPercent': inflationSuccessPercent,
      'inflationRatePercent': (inflationRate * 100).toInt(),
    };
  }
}
