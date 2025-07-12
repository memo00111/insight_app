import 'lib/utils/signature_field_detector.dart';

/// اختبار وظيفة كشف حقول التوقيع
void main() {
  print('🔍 اختبار وظيفة كشف حقول التوقيع');
  print('=' * 50);
  
  // اختبار الحقول العربية
  final arabicFields = [
    'التوقيع',
    'توقيع المدير',
    'امضاء الموظف',
    'ختم الشركة',
    'توقيع المسؤول',
    'الامضاء الشخصي',
    'موافقة وتوقيع',
    'اعتماد وختم',
  ];
  
  print('\n📝 اختبار الحقول العربية:');
  for (final field in arabicFields) {
    final isSignature = SignatureFieldDetector.isSignatureField(field);
    print('  ${isSignature ? '✅' : '❌'} "$field" -> ${isSignature ? 'حقل توقيع' : 'ليس حقل توقيع'}');
  }
  
  // اختبار الحقول الإنجليزية
  final englishFields = [
    'Signature',
    'Sign here',
    'Manager signature',
    'Employee signature',
    'Authorized signature',
    'Digital signature',
    'Signature field',
    'Please sign',
  ];
  
  print('\n📝 اختبار الحقول الإنجليزية:');
  for (final field in englishFields) {
    final isSignature = SignatureFieldDetector.isSignatureField(field);
    print('  ${isSignature ? '✅' : '❌'} "$field" -> ${isSignature ? 'Signature field' : 'Not signature field'}');
  }
  
  // اختبار الحقول التي يجب ألا تُكتشف
  final nonSignatureFields = [
    'الاسم الكامل',
    'العنوان',
    'رقم الهاتف',
    'التاريخ',
    'Full name',
    'Address',
    'Phone number',
    'Design', // يحتوي على "sign" لكن ليس حقل توقيع
    'Assignment', // يحتوي على "sign" لكن ليس حقل توقيع
    'Designation', // يحتوي على "sign" لكن ليس حقل توقيع
  ];
  
  print('\n📝 اختبار الحقول التي يجب ألا تُكتشف:');
  for (final field in nonSignatureFields) {
    final isSignature = SignatureFieldDetector.isSignatureField(field);
    print('  ${!isSignature ? '✅' : '❌'} "$field" -> ${isSignature ? 'خطأ: اكتُشف كحقل توقيع' : 'صحيح: ليس حقل توقيع'}');
  }
  
  // تشغيل الاختبارات المدمجة
  print('\n🧪 تشغيل الاختبارات المدمجة:');
  final testResults = SignatureFieldDetector.testSignatureDetection();
  
  int passedTests = 0;
  int totalTests = testResults.length;
  
  testResults.forEach((testCase, passed) {
    print('  ${passed ? '✅' : '❌'} "$testCase" -> ${passed ? 'نجح' : 'فشل'}');
    if (passed) passedTests++;
  });
  
  print('\n📊 نتائج الاختبار:');
  print('  إجمالي الاختبارات: $totalTests');
  print('  الاختبارات الناجحة: $passedTests');
  print('  الاختبارات الفاشلة: ${totalTests - passedTests}');
  print('  معدل النجاح: ${(passedTests / totalTests * 100).toStringAsFixed(1)}%');
  
  if (passedTests == totalTests) {
    print('\n🎉 جميع الاختبارات نجحت! وظيفة كشف التوقيع تعمل بشكل مثالي.');
  } else {
    print('\n⚠️ بعض الاختبارات فشلت. يرجى مراجعة الكود.');
  }
}
