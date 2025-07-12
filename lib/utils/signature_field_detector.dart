/// مساعد لكشف حقول التوقيع بناءً على نص التسمية
class SignatureFieldDetector {
  
  /// التحقق من أن الحقل هو حقل توقيع بناءً على الكلمات المفتاحية
  static bool isSignatureField(String? label) {
    if (label == null || label.isEmpty) return false;
    
    final labelLower = label.toLowerCase();
    
    // قائمة الكلمات المفتاحية للتوقيع (عربي وإنجليزي)
    final signatureKeywords = [
      // الكلمات الإنجليزية
      'signature', 'signatures', 'signed', 'signhere', 'sign here', 
      'signby', 'sign by', 'signdate', 'sign date', 'autograph', 'endorsement',
      
      // الكلمات العربية
      'توقيع', 'التوقيع', 'توقيعي', 'توقيعك', 'توقيعه', 'توقيعها',
      'امضاء', 'الامضاء', 'امضائي', 'امضاؤك', 'امضاؤه', 'امضاؤها',
      'اعتماد', 'موافقة', 'تصديق', 'ختم', 'الختم',
      'وقع', 'يوقع', 'موقع', 'موقعة', 'موقعه',
      'اوقع', 'يووقع', 'مووقع'  // أخطاء إملائية شائعة
    ];
    
    // البحث عن الكلمات المفتاحية
    for (final keyword in signatureKeywords) {
      final keywordLower = keyword.toLowerCase();
      
      // للكلمات العربية
      if (_containsArabic(keyword)) {
        if (_containsArabicKeyword(labelLower, keywordLower)) {
          return true;
        }
      } else {
        // للكلمات الإنجليزية - استخدام حدود الكلمات
        if (_containsEnglishKeyword(labelLower, keywordLower)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  /// التحقق من وجود أحرف عربية في النص
  static bool _containsArabic(String text) {
    for (int i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (codeUnit >= 0x0600 && codeUnit <= 0x06FF) {
        return true;
      }
    }
    return false;
  }
  
  /// البحث عن كلمة مفتاحية عربية
  static bool _containsArabicKeyword(String label, String keyword) {
    final startIdx = label.indexOf(keyword);
    if (startIdx == -1) return false;
    
    // التحقق من حدود الكلمة العربية
    final before = startIdx == 0 || !_isArabicLetter(label[startIdx - 1]);
    final after = startIdx + keyword.length >= label.length || 
                  !_isArabicLetter(label[startIdx + keyword.length]);
    
    return before && after;
  }
  
  /// البحث عن كلمة مفتاحية إنجليزية
  static bool _containsEnglishKeyword(String label, String keyword) {
    final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
    return pattern.hasMatch(label);
  }
  
  /// التحقق من أن الحرف عربي
  static bool _isArabicLetter(String char) {
    if (char.isEmpty) return false;
    final codeUnit = char.codeUnitAt(0);
    return codeUnit >= 0x0600 && codeUnit <= 0x06FF;
  }
  
  /// الحصول على أمثلة لحقول التوقيع
  static List<String> getSignatureFieldExamples() {
    return [
      'التوقيع',
      'توقيع المدير',
      'الامضاء',
      'ختم الشركة',
      'Signature',
      'Sign here',
      'Manager signature',
      'Authorized signature'
    ];
  }
  
  /// اختبار وظيفة كشف التوقيع
  static Map<String, bool> testSignatureDetection() {
    final testCases = {
      'التوقيع': true,
      'توقيع المدير': true,
      'امضاء الموظف': true,
      'ختم الشركة': true,
      'الاسم الكامل': false,
      'العنوان': false,
      'Signature': true,
      'Sign here': true,
      'Design': false,  // يجب ألا يكتشف "sign" في "design"
      'Full name': false,
      'Manager signature': true,
      'Assignment': false,  // يجب ألا يكتشف "sign" في "assignment"
    };
    
    final results = <String, bool>{};
    testCases.forEach((label, expected) {
      final detected = isSignatureField(label);
      results[label] = detected == expected;
    });
    
    return results;
  }
}
