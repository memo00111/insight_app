import 'package:flutter/material.dart';
import '../utils/signature_field_detector.dart';

/// صفحة لاختبار وظيفة كشف حقول التوقيع
class SignatureDetectionTestPage extends StatelessWidget {
  const SignatureDetectionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // أمثلة لحقول مختلفة للاختبار
    final testFields = [
      'الاسم الكامل',
      'التوقيع',
      'توقيع المدير', 
      'امضاء الموظف',
      'ختم الشركة',
      'العنوان',
      'رقم الهاتف',
      'Signature',
      'Sign here',
      'Manager signature',
      'Full name',
      'Phone number',
      'Design', // يجب ألا يكتشف
      'Assignment', // يجب ألا يكتشف
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'اختبار كشف التوقيع',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      backgroundColor: const Color(0xFF1A1A2E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: const Color(0xFF16213E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختبار كشف حقول التوقيع',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'هذا الاختبار يظهر كيف يتم كشف حقول التوقيع تلقائياً',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // عرض نتائج الاختبار
            ...testFields.map((fieldLabel) {
              final isSignature = SignatureFieldDetector.isSignatureField(fieldLabel);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSignature 
                  ? Colors.green.shade800 
                  : const Color(0xFF16213E),
                child: ListTile(
                  leading: Icon(
                    isSignature ? Icons.draw : Icons.text_fields,
                    color: isSignature ? Colors.green.shade200 : Colors.blue.shade200,
                  ),
                  title: Text(
                    fieldLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  subtitle: Text(
                    isSignature ? 'حقل توقيع 🖋️' : 'حقل نص عادي 📝',
                    style: TextStyle(
                      color: isSignature ? Colors.green.shade200 : Colors.grey.shade300,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  trailing: Icon(
                    isSignature ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSignature ? Colors.green.shade200 : Colors.grey.shade400,
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // إحصائيات
            Card(
              color: const Color(0xFF16213E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إحصائيات النتائج',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildStatRow(
                      'إجمالي الحقول',
                      testFields.length.toString(),
                      Icons.list,
                      Colors.blue.shade200,
                    ),
                    
                    _buildStatRow(
                      'حقول التوقيع المكتشفة',
                      testFields.where((field) => 
                        SignatureFieldDetector.isSignatureField(field)
                      ).length.toString(),
                      Icons.draw,
                      Colors.green.shade200,
                    ),
                    
                    _buildStatRow(
                      'حقول النص العادية',
                      testFields.where((field) => 
                        !SignatureFieldDetector.isSignatureField(field)
                      ).length.toString(),
                      Icons.text_fields,
                      Colors.orange.shade200,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // أمثلة للكلمات المفتاحية
            Card(
              color: const Color(0xFF16213E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أمثلة الكلمات المفتاحية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Text(
                      'العربية:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade200,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Text(
                      'توقيع، التوقيع، امضاء، الامضاء، ختم، اعتماد، موافقة، تصديق',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'الإنجليزية:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade200,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Text(
                      'signature, sign here, signed, autograph, endorsement',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
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
  
  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
