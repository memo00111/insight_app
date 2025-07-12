import 'package:flutter/material.dart';

class FontTestWidget extends StatelessWidget {
  const FontTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: const Text('اختبار الخطوط'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختبار خط Cairo العادي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختبار خط Cairo خفيف',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختبار خط Cairo عريض',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'النص العربي مع الأرقام 123456',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'نص طويل لاختبار الخط العربي والتأكد من وضوح القراءة والعرض الصحيح للحروف العربية والتشكيل والمسافات بين الكلمات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey[300],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // اختبار مع نمط Material Design
            Text(
              'عنوان كبير',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'عنوان متوسط',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'نص أساسي',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'نص صغير',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
