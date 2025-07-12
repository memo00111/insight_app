import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// مساعد للتعامل مع النصوص العربية وإصلاح مشاكل العرض
class ArabicTextHelper {
  
  /// التحقق من وجود أحرف عربية في النص
  static bool containsArabic(String text) {
    if (text.isEmpty) return false;
    
    // التحقق من وجود أحرف عربية (U+0600 to U+06FF)
    final arabicRange = RegExp(r'[\u0600-\u06FF]');
    return arabicRange.hasMatch(text);
  }
  
  /// تنظيف وتحضير النص العربي للإرسال للخادم
  static String prepareArabicText(String text) {
    if (!containsArabic(text)) return text;
    
    // إزالة الأحرف غير المرغوب فيها وتنظيف النص
    String cleanedText = text
        .replaceAll(RegExp(r'[\u200E\u200F\u202A-\u202E]'), '') // إزالة أحرف التحكم في الاتجاه
        .trim();
    
    return cleanedText;
  }
  
  /// تحضير البيانات للإرسال للخادم مع معلومات إضافية للنص العربي
  static Map<String, dynamic> enhancePayloadForArabic(
    Map<String, dynamic> originalPayload,
    String languageDirection,
  ) {
    final enhancedPayload = Map<String, dynamic>.from(originalPayload);
    
    // إضافة معلومات إضافية للنص العربي
    enhancedPayload['language_direction'] = languageDirection;
    enhancedPayload['text_direction'] = languageDirection == 'rtl' ? 'rtl' : 'ltr';
    enhancedPayload['requires_arabic_shaping'] = languageDirection == 'rtl';
    
    // تحسين النصوص في texts_dict
    if (enhancedPayload['texts_dict'] is Map) {
      final textsDict = Map<String, dynamic>.from(enhancedPayload['texts_dict']);
      
      textsDict.forEach((key, value) {
        if (value is String && value.isNotEmpty) {
          textsDict[key] = prepareArabicText(value);
        }
      });
      
      enhancedPayload['texts_dict'] = textsDict;
    }
    
    return enhancedPayload;
  }
  
  /// إنشاء رسالة تشخيصية مفصلة للإرسال للفريق التقني
  static String generateDiagnosticReport(
    Map<String, dynamic> formData,
    String languageDirection,
    List<String> fieldLabels,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('🔍 تقرير تشخيص مشكلة النص العربي');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    buffer.writeln('📊 معلومات عامة:');
    buffer.writeln('- اتجاه اللغة: $languageDirection');
    buffer.writeln('- عدد الحقول: ${fieldLabels.length}');
    buffer.writeln('- البيانات المدخلة: ${formData.length}');
    buffer.writeln();
    
    buffer.writeln('📝 تحليل النصوص:');
    formData.forEach((fieldId, value) {
      if (value is String && value.isNotEmpty) {
        final hasArabic = containsArabic(value);
        buffer.writeln('- $fieldId: "$value"');
        buffer.writeln('  * يحتوي على عربي: ${hasArabic ? "نعم" : "لا"}');
        if (hasArabic) {
          buffer.writeln('  * طول النص: ${value.length}');
          buffer.writeln('  * أحرف Unicode: ${value.runes.map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(' ')}');
        }
        buffer.writeln();
      }
    });
    
    buffer.writeln('🏷️ تصنيفات الحقول:');
    for (int i = 0; i < fieldLabels.length; i++) {
      final label = fieldLabels[i];
      final hasArabic = containsArabic(label);
      buffer.writeln('- حقل ${i + 1}: "$label" (عربي: ${hasArabic ? "نعم" : "لا"})');
    }
    buffer.writeln();
    
    buffer.writeln('🛠️ توصيات للفريق التقني:');
    buffer.writeln('1. التأكد من دعم الخط المستخدم للأحرف العربية');
    buffer.writeln('2. استخدام مكتبة arabic-reshaper و python-bidi في Python');
    buffer.writeln('3. تطبيق Text Shaping قبل رسم النص على الصورة');
    buffer.writeln('4. التأكد من اتجاه النص (RTL) عند الرسم');
    buffer.writeln('5. استخدام font يدعم العربية مثل Cairo أو Amiri');
    buffer.writeln();
    
    buffer.writeln('💻 مثال كود Python للإصلاح:');
    buffer.writeln('''
```python
from arabic_reshaper import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFont

def draw_arabic_text(draw, text, position, font, fill='black'):
    if is_arabic(text):
        # إعادة تشكيل النص العربي
        reshaped_text = arabic_reshaper.reshape(text)
        # تطبيق اتجاه النص
        bidi_text = get_display(reshaped_text)
        draw.text(position, bidi_text, font=font, fill=fill)
    else:
        draw.text(position, text, font=font, fill=fill)
```''');
    
    return buffer.toString();
  }
  
  /// عرض رسالة تحذيرية للمستخدم حول مشكلة النص العربي
  static void showArabicTextWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('تحذير - النص العربي'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم اكتشاف مشكلة في عرض النص العربي على الصورة النهائية.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('المشكلة:'),
            Text('• النص العربي يظهر مقطع ومشوه'),
            Text('• النص الإنجليزي يظهر بشكل صحيح'),
            SizedBox(height: 12),
            Text('الحل:'),
            Text('• المشكلة في الخادم وليس في التطبيق'),
            Text('• يحتاج الفريق التقني لتحديث معالج النصوص'),
            Text('• البيانات محفوظة بشكل صحيح'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }
  
  /// إنشاء معاينة محلية للنص العربي (للاختبار)
  static Widget buildArabicTextPreview(
    String text, {
    TextStyle? style,
    TextDirection? textDirection,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معاينة النص:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: style?.copyWith(
              fontFamily: 'Cairo',
            ) ?? const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
            ),
            textDirection: textDirection ?? 
              (containsArabic(text) ? TextDirection.rtl : TextDirection.ltr),
          ),
          const SizedBox(height: 8),
          Text(
            'الاتجاه: ${containsArabic(text) ? "من اليمين إلى اليسار" : "من اليسار إلى اليمين"}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
