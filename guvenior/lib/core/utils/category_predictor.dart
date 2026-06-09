class CategoryPredictor {
  // Brand/keyword to Category ID mappings
  static const Map<int, List<String>> _keywords = {
    1: [ // Yemek (Food / Groceries)
      'yemek', 'restoran', 'restaurant', 'kafe', 'cafe', 'migros', 'getir', 
      'yemeksepeti', 'bim', 'a101', 'şok', 'carrefour', 'macro', 'macrocenter', 
      'burger', 'mcdonalds', 'pizza', 'kahve', 'starbucks', 'dominos', 'kfc', 
      'döner', 'kebap', 'fırın', 'market', 'manav', 'kasap'
    ],
    2: [ // Ulaşım (Transport)
      'ulaşım', 'transport', 'uber', 'taksi', 'taxi', 'bitaksi', 'martı', 'binbin', 
      'bilet', 'otobüs', 'metro', 'pegasus', 'thy', 'akbil', 'istanbulkart', 
      'yakıt', 'benzin', 'shell', 'opet', 'petrol', 'bp', 'otopark'
    ],
    3: [ // Kira (Rent)
      'kira', 'rent', 'ev', 'house', 'aidat', 'depozito'
    ],
    4: [ // Alışveriş (Shopping / Retail / Pets)
      'alışveriş', 'shopping', 'zara', 'trendyol', 'h&m', 'hm', 'mango', 
      'bershka', 'pull&bear', 'pull and bear', 'n11', 'hepsiburada', 'amazon', 
      'lcw', 'koton', 'boyner', 'gratis', 'watsons', 'kedi', 'mama', 'köpek', 
      'petshop', 'ayakkabı', 'elbise', 'pantolon', 't-shirt'
    ],
    5: [ // Eğlence (Entertainment / Subscriptions)
      'eğlence', 'fun', 'netflix', 'spotify', 'youtube', 'disney', 'sinema', 
      'cinema', 'konser', 'tiyatro', 'biletix', 'oyun', 'steam', 'playstation', 
      'xbox', 'pub', 'bar', 'kulüp', 'club', 'bira', 'şarap', 'müzik'
    ],
    6: [ // Faturalar (Bills / Utilities)
      'fatura', 'bill', 'elektrik', 'su', 'doğalgaz', 'gaz', 'internet', 
      'turkcell', 'vodafone', 'telekom', 'türk telekom', 'ttnet', 'd-smart', 'digiturk'
    ],
    7: [ // Eğitim (Education)
      'eğitim', 'education', 'okul', 'school', 'kurs', 'udemy', 'coursera', 
      'kitap', 'book', 'kırtasiye', 'ders', 'üniversite', 'kolej'
    ],
  };

  /// Predicts the category ID based on the transaction title.
  /// Returns null if no match is found, so it can default to the user's current selection or 'Diğer' (8).
  static int? predict(String title) {
    if (title.isEmpty) return null;
    final normalized = title.trim().toLowerCase();

    for (final entry in _keywords.entries) {
      final categoryId = entry.key;
      final keywordsList = entry.value;

      for (final kw in keywordsList) {
        if (normalized.contains(kw)) {
          return categoryId;
        }
      }
    }
    return null; // Let the screen fall back to the default or Diğer (8)
  }
}
