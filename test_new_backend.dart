import 'dart:io';
import 'package:dio/dio.dart';

class BackendTester {
  static const String baseUrl = 'https://fantastic-bassoon-g4457g4gv9w6cvpgp-8000.app.github.dev';
  late Dio _dio;

  BackendTester() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  // Test Main API Info
  Future<void> testMainEndpoint() async {
    print('🔍 اختبار الـ endpoint الرئيسي...');
    try {
      Response response = await _dio.get('/');
      print('✅ الـ endpoint الرئيسي يعمل');
      print('📋 الرد: ${response.data}');
      
      // Check if it contains the expected services
      if (response.data.toString().contains('Form Analyzer') &&
          response.data.toString().contains('Money Reader') &&
          response.data.toString().contains('Document Reader')) {
        print('✅ جميع الخدمات المطلوبة متوفرة');
      } else {
        print('⚠️ قد تكون بعض الخدمات مفقودة');
      }
    } catch (e) {
      print('❌ فشل في الوصول للـ endpoint الرئيسي: $e');
    }
  }

  // Test Health Endpoints
  Future<void> testHealthEndpoints() async {
    print('\n🏥 اختبار endpoints الصحة...');
    
    final healthEndpoints = [
      '/health',
      '/form/ping',
      '/money/ping',
      '/document/ping'
    ];

    for (String endpoint in healthEndpoints) {
      try {
        Response response = await _dio.get(endpoint);
        print('✅ $endpoint يعمل بشكل صحيح');
      } catch (e) {
        print('❌ $endpoint لا يعمل: $e');
      }
    }
  }

  // Test Form Analyzer Endpoints
  Future<void> testFormEndpoints() async {
    print('\n📝 اختبار endpoints تحليل النماذج...');
    
    // Test check-image endpoint
    try {
      Response response = await _dio.post('/form/check-image');
      print('✅ Form check-image endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Form check-image endpoint متاح (يتطلب صورة)');
        print('📋 تنسيق الخطأ المتوقع: ${e.response?.data}');
      } else {
        print('❌ Form check-image endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Form check-image: $e');
    }

    // Test analyze-form endpoint
    try {
      Response response = await _dio.post('/form/analyze-form');
      print('✅ Form analyze-form endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Form analyze-form endpoint متاح (يتطلب بيانات)');
        print('📋 المتطلبات: ${e.response?.data}');
      } else {
        print('❌ Form analyze-form endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Form analyze-form: $e');
    }

    // Test annotate-image endpoint
    try {
      Response response = await _dio.post('/form/annotate-image');
      print('✅ Form annotate-image endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Form annotate-image endpoint متاح (يتطلب بيانات)');
      } else {
        print('❌ Form annotate-image endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Form annotate-image: $e');
    }

    // Test form text-to-speech endpoint
    try {
      Response response = await _dio.post('/form/text-to-speech');
      print('✅ Form text-to-speech endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Form text-to-speech endpoint متاح (يتطلب نص)');
      } else {
        print('❌ Form text-to-speech endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Form text-to-speech: $e');
    }

    // Test form speech-to-text endpoint
    try {
      Response response = await _dio.post('/form/speech-to-text');
      print('✅ Form speech-to-text endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Form speech-to-text endpoint متاح (يتطلب صوت)');
      } else {
        print('❌ Form speech-to-text endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Form speech-to-text: $e');
    }

    // Test session-info endpoint
    try {
      Response response = await _dio.get('/form/session-info');
      print('✅ Form session-info endpoint متاح');
      print('📋 معلومات الجلسات: ${response.data}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Form session-info endpoint متاح');
      } else {
        print('❌ Form session-info endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Form session-info: $e');
    }
  }

  // Test Money Reader Endpoints
  Future<void> testMoneyEndpoints() async {
    print('\n💰 اختبار endpoints تحليل العملات...');
    
    try {
      Response response = await _dio.post('/money/analyze');
      print('✅ Money analyze endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Money analyze endpoint متاح (يتطلب صورة)');
        print('📋 الحقل المطلوب: ${e.response?.data}');
      } else {
        print('❌ Money analyze endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Money analyze: $e');
    }
  }

  // Test Document Reader Endpoints
  Future<void> testDocumentEndpoints() async {
    print('\n📄 اختبار endpoints قراءة المستندات...');
    
    try {
      Response response = await _dio.post('/document/upload');
      print('✅ Document upload endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Document upload endpoint متاح (يتطلب ملف)');
      } else {
        print('❌ Document upload endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Document upload: $e');
    }
  }

  // Test Shared Services
  Future<void> testSharedEndpoints() async {
    print('\n🎤 اختبار الخدمات المشتركة...');
    
    // Test Text-to-Speech
    try {
      Response response = await _dio.post('/text-to-speech');
      print('✅ Text-to-Speech endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Text-to-Speech endpoint متاح (يتطلب نص)');
      } else {
        print('❌ Text-to-Speech endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Text-to-Speech: $e');
    }

    // Test Speech-to-Text
    try {
      Response response = await _dio.post('/speech-to-text');
      print('✅ Speech-to-Text endpoint متاح');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        print('✅ Speech-to-Text endpoint متاح (يتطلب صوت)');
      } else {
        print('❌ Speech-to-Text endpoint غير متاح: ${e.response?.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ في Speech-to-Text: $e');
    }
  }

  // Run All Tests
  Future<void> runAllTests() async {
    print('🚀 بدء اختبار التطابق مع الباك اند الجديد...');
    print('🔗 عنوان الخادم: $baseUrl');
    
    await testMainEndpoint();
    await testHealthEndpoints();
    await testFormEndpoints();
    await testMoneyEndpoints();
    await testDocumentEndpoints();
    await testSharedEndpoints();
    
    print('\n✅ انتهاء الاختبارات!');
    print('📋 تحقق من النتائج أعلاه للتأكد من التطابق');
  }
}

// Function to run tests
void main() async {
  final tester = BackendTester();
  await tester.runAllTests();
} 