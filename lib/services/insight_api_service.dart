import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/form_analysis_response.dart';
import '../models/currency_analysis_response.dart';
import '../models/document_response.dart';
import '../utils/arabic_text_helper.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class InsightApiService {
  static const String baseUrl = 'http://34.134.153.40:8080';
  late Dio _dio;

  InsightApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
      validateStatus: (status) => status != null && status < 500,
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      error: true,
      logPrint: (object) => print('🔗 API Log: $object'),
    ));
  }

  // Helper method for making POST requests
  Future<Response> post(String path, {dynamic data, Options? options}) async {
    return await _dio.post(path, data: data, options: options);
  }

  // Helper method for making GET requests
  Future<Response> get(String path) async {
    return await _dio.get(path);
  }

  // Helper method for making DELETE requests
  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // Form Analysis Methods
  
  // 1. فحص جودة الصورة وكشف اللغة
  Future<Map<String, dynamic>> checkFormImageQuality(File imageFile) async {
    print('📤 فحص جودة الصورة');
    print('📂 مسار الملف: ${imageFile.path}');
    
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      print('📤 بدء فحص جودة الصورة...');
      print('🌐 الرابط: ${_dio.options.baseUrl}/form/check-file');
      Response response = await post('/form/check-file', data: formData);
      
      print('📨 كود استجابة فحص الجودة: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ تم فحص جودة الصورة بنجاح');
        final result = response.data as Map<String, dynamic>;
        
        // Log detailed response for debugging
        print('🔍 تفاصيل استجابة فحص الجودة:');
        result.forEach((key, value) {
          print('   $key: $value (نوع: ${value.runtimeType})');
        });
        
        // Specifically check language_direction
        final languageDirection = result['language_direction'];
        if (languageDirection != null) {
          print('🔤 اتجاه اللغة المكتشف: "$languageDirection"');
          print('🔤 نوع البيانات: ${languageDirection.runtimeType}');
          print('🔤 طول النص: ${languageDirection.toString().length}');
          if (languageDirection is String) {
            print('🔤 الأحرف: ${languageDirection.codeUnits}');
          }
        } else {
          print('⚠️ لم يتم إرجاع اتجاه اللغة');
        }
        
        return result;
      } else {
        print('❌ فشل في فحص جودة الصورة - الكود: ${response.statusCode}');
        if (response.data != null && response.data['detail'] != null) {
          throw Exception(response.data['detail'].toString());
        }
        throw Exception('فشل في فحص جودة الصورة: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio في فحص الجودة: ${e.type}');
      print('❌ رسالة الخطأ: ${e.message}');
      if (e.response != null) {
        print('❌ كود الخطأ: ${e.response?.statusCode}');
        print('❌ بيانات الخطأ: ${e.response?.data}');
      }
      throw _handleDioError(e, 'فحص جودة الصورة');
    } catch (e) {
      print('❌ خطأ عام في فحص الجودة: $e');
      throw Exception('خطأ غير متوقع في فحص جودة الصورة: $e');
    }
  }

  // 2. تحليل النموذج الرئيسي
  Future<FormAnalysisResponse> analyzeFormData(
    File imageFile,
    String sessionId, {
    String? languageDirection,
  }) async {
    print('📤 تحليل النموذج مع معرف الجلسة: $sessionId');
    print('📂 مسار الملف: ${imageFile.path}');
    print('🔤 اتجاه اللغة: $languageDirection');
    print('🔤 نوع اتجاه اللغة: ${languageDirection?.runtimeType}');
    
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
        'session_id': sessionId,
      });
      
      if (languageDirection != null) {
        formData.fields.add(MapEntry('language_direction', languageDirection));
        print('✅ تم إضافة اتجاه اللغة: $languageDirection');
      } else {
        print('⚠️ لم يتم تمرير اتجاه اللغة');
      }

      print('📤 بدء تحليل النموذج...');
      print('🌐 الرابط: ${_dio.options.baseUrl}/form/analyze-form');
      print('📦 بيانات الطلب:');
      print('   - session_id: $sessionId');
      print('   - language_direction: $languageDirection');
      print('   - file: ${imageFile.path}');
      
      Response response = await post('/form/analyze-form', data: formData);

      print('📨 كود الاستجابة: ${response.statusCode}');
      print('📄 بيانات الاستجابة: ${response.data}');

      if (response.statusCode == 200) {
        print('✅ تم تحليل النموذج بنجاح');
        final analysisResponse = FormAnalysisResponse.fromJson(response.data);
        print('📝 عدد الحقول المكتشفة: ${analysisResponse.fields.length}');
        
        // Log field details for debugging
        for (int i = 0; i < analysisResponse.fields.length; i++) {
          final field = analysisResponse.fields[i];
          print('📝 حقل $i: ${field.label} (${field.type})');
        }
        
        return analysisResponse;
      } else {
        print('❌ فشل في تحليل النموذج - الكود: ${response.statusCode}');
        if (response.data != null && response.data['detail'] != null) {
          throw Exception(response.data['detail'].toString());
        }
        throw Exception('فشل في تحليل النموذج: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      print('❌ رسالة الخطأ: ${e.message}');
      if (e.response != null) {
        print('❌ كود الخطأ: ${e.response?.statusCode}');
        print('❌ بيانات الخطأ: ${e.response?.data}');
      }
      throw _handleDioError(e, 'تحليل النموذج');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في تحليل النموذج: $e');
    }
  }

  // 3. تحديث المعاينة المباشرة مع دعم محسن للنصوص العربية
  Future<Uint8List> annotateImage({
    required Uint8List originalImageBytes,
    required Map<String, dynamic> textsDict,
    required List<UIField> uiFields,
    String? signatureImageB64,
    String? signatureFieldId,
    String? languageDirection,
  }) async {
    print('📝 بدء إضافة التعليقات على النموذج');
    print('🔤 اتجاه اللغة: $languageDirection');
    
    // تشخيص النصوص العربية
    bool hasArabicText = false;
    textsDict.forEach((key, value) {
      if (value is String && ArabicTextHelper.containsArabic(value)) {
        hasArabicText = true;
        print('🔍 نص عربي مكتشف في الحقل $key: "$value"');
      }
    });
    
    if (hasArabicText) {
      print('⚠️ تم اكتشاف نصوص عربية - تطبيق تحسينات خاصة');
      
      // إنشاء تقرير تشخيصي مفصل
      final fieldLabels = uiFields.map((field) => field.label).toList();
      final diagnosticReport = ArabicTextHelper.generateDiagnosticReport(
        textsDict,
        languageDirection ?? 'rtl',
        fieldLabels,
      );
      print('📋 تقرير التشخيص:\n$diagnosticReport');
    }
    
    try {
      // إعداد البيانات مع تحسينات للنص العربي
      Map<String, dynamic> requestData = {
        'original_image_b64': base64Encode(originalImageBytes),
        'texts_dict': textsDict,
        'ui_fields': uiFields.map((e) => e.toJson()).toList(),
      };
      
      // تطبيق تحسينات النص العربي
      if (languageDirection != null) {
        requestData = ArabicTextHelper.enhancePayloadForArabic(
          requestData,
          languageDirection,
        );
      }
      
      if (signatureImageB64 != null) {
        requestData['signature_image_b64'] = signatureImageB64;
        print('✏️ تمت إضافة صورة التوقيع إلى الطلب');
      }
      
      if (signatureFieldId != null) {
        requestData['signature_field_id'] = signatureFieldId;
        print('🆔 معرف حقل التوقيع: $signatureFieldId');
      }
      
      // تأكد من أن التوقيع والمعرف موجودان معًا
      if ((signatureImageB64 != null && signatureFieldId == null) || 
          (signatureImageB64 == null && signatureFieldId != null)) {
        print('⚠️ تحذير: يجب توفير صورة التوقيع ومعرف الحقل معًا لإظهار التوقيع بشكل صحيح');
      }

      print('📤 إرسال البيانات المحسنة للخادم...');
      Response response = await _dio.post(
        '/form/annotate-image',
        data: requestData,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        print('✅ تم إنشاء المعاينة المباشرة بنجاح');
        
        if (hasArabicText) {
          print('ℹ️ تم إنشاء الصورة مع نصوص عربية - قد تحتاج لتحديث الخادم لدعم أفضل');
        }
        
        return Uint8List.fromList(response.data);
      } else {
        print('❌ فشل في إنشاء المعاينة - الكود: ${response.statusCode}');
        throw Exception('فشل في إنشاء المعاينة المباشرة: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      throw _handleDioError(e, 'إنشاء المعاينة المباشرة');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في إنشاء المعاينة: $e');
    }
  }

  // 4. تحويل النص إلى كلام
  Future<Uint8List> formTextToSpeech(String text) async {
    print('� بدء تحويل النص إلى كلام: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
    
    try {
      final requestData = {
        'text': text,
        'provider': 'gemini',
      };

      Response response = await _dio.post(
        '/form/text-to-speech',
        data: requestData,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        print('✅ تم تحويل النص إلى كلام بنجاح');
        return Uint8List.fromList(response.data);
      } else if (response.statusCode == 429) {
        print('❌ تم تجاوز الحد الأقصى لاستخدام الخدمة');
        throw Exception('تم تجاوز الحد الأقصى لاستخدام خدمة تحويل النص إلى كلام');
      } else {
        print('❌ فشل في تحويل النص - الكود: ${response.statusCode}');
        throw Exception('فشل في تحويل النص إلى كلام: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      if (e.response?.statusCode == 429) {
        throw Exception('تم تجاوز الحد الأقصى لاستخدام خدمة تحويل النص إلى كلام');
      }
      throw _handleDioError(e, 'تحويل النص إلى كلام');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في تحويل النص إلى كلام: $e');
    }
  }

  // 5. تحويل الكلام إلى نص
  Future<String> formSpeechToText(Uint8List audioBytes, String languageCode) async {
    print('🎤 بدء تحويل الكلام إلى نص - لغة: $languageCode');
    print('📊 حجم البيانات الصوتية: ${audioBytes.length} بايت');
    
    try {
      // التحقق من صحة البيانات
      if (audioBytes.isEmpty) {
        throw Exception('البيانات الصوتية فارغة');
      }
      
      if (audioBytes.length < 1000) { // أقل من 1KB
        throw Exception('الملف الصوتي صغير جداً - قد لا يحتوي على صوت');
      }
      
      // إرسال language_code كـ query parameter حسب API documentation
      final queryParams = 'language_code=$languageCode';
      
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          audioBytes,
          filename: 'audio.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      });

      print('📤 إرسال البيانات إلى /form/speech-to-text?$queryParams');
      Response response = await post('/form/speech-to-text?$queryParams', data: formData);

      if (response.statusCode == 200) {
        print('✅ تم تحويل الكلام إلى نص بنجاح');
        // API يُرجع string مباشرة حسب الوثائق
        final result = response.data is String ? response.data : (response.data['text'] ?? '');
        print('📝 النص المستخرج: $result');
        return result;
      } else if (response.statusCode == 422) {
        print('❌ خطأ 422: البيانات المرسلة غير صحيحة');
        print('📋 تفاصيل الاستجابة: ${response.data}');
        throw Exception('البيانات الصوتية غير صحيحة أو التنسيق غير مدعوم');
      } else if (response.statusCode == 429) {
        print('❌ تم تجاوز الحد الأقصى لاستخدام الخدمة');
        throw Exception('تم تجاوز الحد الأقصى لاستخدام خدمة تحويل الكلام إلى نص');
      } else {
        print('❌ فشل في تحويل الكلام - الكود: ${response.statusCode}');
        print('📋 رسالة الاستجابة: ${response.data}');
        throw Exception('فشل في تحويل الكلام إلى نص: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      print('📋 تفاصيل الخطأ: ${e.message}');
      
      if (e.response?.statusCode == 422) {
        print('📋 تفاصيل خطأ 422: ${e.response?.data}');
        throw Exception('تنسيق الملف الصوتي غير مدعوم. يرجى المحاولة مرة أخرى');
      } else if (e.response?.statusCode == 429) {
        throw Exception('تم تجاوز الحد الأقصى لاستخدام خدمة تحويل الكلام إلى نص');
      } else {
        throw Exception('خطأ في الاتصال: ${e.message ?? "خطأ غير معروف"}');
      }
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في تحويل الكلام إلى نص: $e');
    }
  }

  // 6. إدارة الجلسات
  Future<void> deleteFormSession(String sessionId) async {
    print('🗑️ حذف جلسة النموذج: $sessionId');
    
    try {
      Response response = await delete('/form/session/$sessionId');

      if (response.statusCode == 200) {
        print('✅ تم حذف الجلسة بنجاح');
      } else {
        print('❌ فشل في حذف الجلسة - الكود: ${response.statusCode}');
        throw Exception('فشل في حذف الجلسة: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      throw _handleDioError(e, 'حذف الجلسة');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في حذف الجلسة: $e');
    }
  }

  Future<Map<String, dynamic>> getFormSessionInfo() async {
    print('ℹ️ الحصول على معلومات الجلسات');
    
    try {
      Response response = await get('/form/session-info');

      if (response.statusCode == 200) {
        print('✅ تم الحصول على معلومات الجلسات بنجاح');
        return response.data;
      } else {
        print('❌ فشل في الحصول على معلومات الجلسات - الكود: ${response.statusCode}');
        throw Exception('فشل في الحصول على معلومات الجلسات: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      throw _handleDioError(e, 'الحصول على معلومات الجلسات');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في الحصول على معلومات الجلسات: $e');
    }
  }

  // Helper method for signature field detection
  static bool isSignatureField(String label) {
    List<String> signatureKeywords = [
      // عربي
      'توقيع', 'التوقيع', 'توقيعي', 'توقيعك', 
      'امضاء', 'الامضاء', 'امضائي', 'امضاؤك',
      'اعتماد', 'ختم', 'الختم',
      
      // إنجليزي
      'signature', 'signatures', 'signed', 'sign here',
      'sign by', 'autograph', 'endorsement'
    ];
    
    return signatureKeywords.any((keyword) => 
      label.toLowerCase().contains(keyword.toLowerCase())
    );
  }

  Future<void> saveFormAnalysis(File imageFile, FormAnalysisResponse analysis) async {
    print('💾 حفظ تحليل النموذج');
    
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
        'analysis': jsonEncode(analysis.toJson()),
      });

      Response response = await post('/form/save', data: formData);
      
      if (response.statusCode != 200) {
        throw Exception('فشل في حفظ النموذج: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('خطأ في حفظ النموذج: $e');
    }
  }

  Future<Uint8List> getAnnotatedImage(dynamic image, Map<String, String> textsDict, List<UIField> uiFields) async {
    print('📝 بدء إضافة التعليقات على النموذج (Legacy Method)');
    
    try {
      late Uint8List imageBytes;
      
      if (image is File) {
        if (!await image.exists()) {
          throw Exception('الملف غير موجود: ${image.path}');
        }
        imageBytes = await image.readAsBytes();
      } else if (image is Uint8List) {
        imageBytes = image;
      } else if (image is String) {
        final file = File(image);
        if (!await file.exists()) {
          throw Exception('الملف غير موجود: $image');
        }
        imageBytes = await file.readAsBytes();
      } else {
        throw Exception('نوع الصورة غير مدعوم');
      }
      
      // استخدم الطريقة الجديدة
      return await annotateImage(
        originalImageBytes: imageBytes,
        textsDict: textsDict,
        uiFields: uiFields,
      );
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      print('❌ رسالة الخطأ: ${e.message}');
      if (e.response != null) {
        print('❌ كود الخطأ: ${e.response?.statusCode}');
        print('❌ بيانات الخطأ: ${e.response?.data}');
      }
      throw _handleDioError(e, 'إنشاء الصورة المعلمة');
    } catch (e) {
      print('❌ خطأ في إنشاء الصورة المعلمة: $e');
      throw Exception('خطأ في إنشاء الصورة المعلمة: $e');
    }
  }

  Future<Uint8List> textToSpeech(String text) async {
    print('🗣️ تحويل النص إلى كلام');
    
    try {
      final requestData = {
        'text': text,
        'provider': 'gemini'
      };

      Response response = await post(
        '/form/text-to-speech', 
        data: requestData,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      if (response.statusCode == 200) {
        print('✅ تم تحويل النص إلى كلام بنجاح');
        return Uint8List.fromList(response.data);
      } else if (response.statusCode == 429) {
        print('⚠️ تم تجاوز حد الاستخدام لخدمة تحويل النص إلى كلام');
        throw Exception('تم تجاوز حد الاستخدام لخدمة تحويل النص إلى كلام');
      } else {
        print('❌ فشل في تحويل النص إلى كلام - الكود: ${response.statusCode}');
        throw Exception('فشل في تحويل النص إلى كلام: ${response.statusMessage}');
      }
    } catch (e) {
      print('❌ خطأ في تحويل النص إلى كلام: $e');
      throw Exception('خطأ في تحويل النص إلى كلام: $e');
    }
  }

  Future<String> speechToText(File audioFile, [String languageCode = 'ar']) async {
    print('🎤 تحويل الكلام إلى نص');
    
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          contentType: MediaType('audio', 'wav'),
        ),
        'language_code': languageCode,
      });

      Response response = await post('/document/speech-to-text', data: formData);
      
      if (response.statusCode == 200) {
        print('✅ تم تحويل الكلام إلى نص بنجاح');
        return response.data['text'];
      } else if (response.statusCode == 429) {
        print('⚠️ تم تجاوز حد الاستخدام لخدمة تحويل الكلام إلى نص');
        throw Exception('تم تجاوز حد الاستخدام لخدمة تحويل الكلام إلى نص');
      } else {
        print('❌ فشل في تحويل الكلام إلى نص - الكود: ${response.statusCode}');
        throw Exception('فشل في تحويل الكلام إلى نص: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      if (e.response?.statusCode == 429) {
        throw Exception('تم تجاوز حد الاستخدام لخدمة تحويل الكلام إلى نص');
      }
      throw _handleDioError(e, 'تحويل الصوت إلى نص');
    } catch (e) {
      print('❌ خطأ في تحويل الصوت إلى نص: $e');
      throw Exception('خطأ في تحويل الصوت إلى نص: $e');
    }
  }

  // Money Reader Methods
  Future<Map<String, dynamic>> pingMoneyReader() async {
    print('Ping Money Reader Service');
    try {
      final response = await get('/money/ping');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to ping Money Reader service: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Ping Money Reader');
    } catch (e) {
      throw Exception('An unexpected error occurred while pinging the Money Reader service: $e');
    }
  }

  Future<CurrencyAnalysisResponse> analyzeMoney(File imageFile) async {
    print('Analyzing currency image');
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      Response response = await post('/money/analyze', data: formData);

      if (response.statusCode == 200) {
        return CurrencyAnalysisResponse.fromJson(response.data);
      } else {
        if (response.data != null && response.data['detail'] != null) {
          throw Exception(response.data['detail'].toString());
        }
        throw Exception('Failed to analyze currency: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Analyze Currency');
    } catch (e) {
      throw Exception('An unexpected error occurred during currency analysis: $e');
    }
  }

  // Health check for Form service
  Future<bool> checkFormHealth() async {
    try {
      Response response = await _dio.get('/form/ping');
      print('✅ Form service صحي - الكود: ${response.statusCode}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ Form service غير صحي: ${e.response?.statusCode}');
      return false;
    } catch (e) {
      print('❌ خطأ في فحص Form service: $e');
      return false;
    }
  }

  // Document Reader Methods
  Future<DocumentResponse> uploadDocument(String filePath, {String language = 'arabic'}) async {
    print('📤 بدء رفع المستند: $filePath');
    print('🌐 اللغة المحددة: $language');
    print('🔗 URL الخادم: $baseUrl/document/upload');
    
    try {
      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود: $filePath');
      }
      
      final fileSize = await file.length();
      print('📊 حجم الملف: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} ميجابايت');
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'language': language,
      });

      print('📤 بدء إرسال الطلب...');
      Response response = await _dio.post('/document/upload', data: formData);
      print('✅ تم استلام الرد - الكود: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ تم رفع المستند بنجاح');
        return DocumentResponse.fromJson(response.data);
      } else {
        print('❌ فشل في رفع المستند - الكود: ${response.statusCode}');
        throw Exception('فشل في رفع المستند: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      print('❌ رسالة الخطأ: ${e.message}');
      if (e.response != null) {
        print('❌ كود الخطأ: ${e.response?.statusCode}');
        print('❌ بيانات الخطأ: ${e.response?.data}');
      }
      throw _handleDioError(e, 'رفع المستند');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في رفع المستند: $e');
    }
  }

  Future<SlideAnalysisResponse> getPageAnalysis(String sessionId, int pageNumber) async {
    try {
      Response response = await _dio.get('/document/$sessionId/page/$pageNumber');
      
      if (response.statusCode == 200) {
        return SlideAnalysisResponse.fromJson(response.data);
      } else {
        throw Exception('فشل في الحصول على تحليل الصفحة: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'تحليل الصفحة');
    } catch (e) {
      throw Exception('خطأ غير متوقع في تحليل الصفحة: $e');
    }
  }

  // Navigate Document with Voice Commands
  Future<NavigationResponse> navigateDocument(String sessionId, String command, {int? currentPage}) async {
    print('🎤 بدء التنقل الصوتي: $command');
    print('🔗 URL الخادم: $baseUrl/document/$sessionId/navigate');
    
    try {
      Map<String, dynamic> requestData = {
        'command': command,
        'current_page': currentPage ?? 1,
      };

      print('📤 بدء إرسال طلب التنقل...');
      Response response = await _dio.post('/document/$sessionId/navigate', data: requestData);
      print('✅ تم استلام رد التنقل - الكود: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ تم التنقل بنجاح');
        return NavigationResponse.fromJson(response.data);
      } else {
        print('❌ فشل في التنقل - الكود: ${response.statusCode}');
        throw Exception('فشل في التنقل: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio في التنقل: ${e.type}');
      print('❌ رسالة الخطأ: ${e.message}');
      if (e.response != null) {
        print('❌ كود الخطأ: ${e.response?.statusCode}');
        print('❌ بيانات الخطأ: ${e.response?.data}');
      }
      throw _handleDioError(e, 'التنقل الصوتي');
    } catch (e) {
      print('❌ خطأ عام في التنقل: $e');
      throw Exception('خطأ غير متوقع في التنقل الصوتي: $e');
    }
  }

  Future<List<int>> getPageImage(String sessionId, int pageNumber) async {
    try {
      Response response = await _dio.get('/document/$sessionId/page/$pageNumber/image',
          options: Options(responseType: ResponseType.bytes));
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('فشل في الحصول على صورة الصفحة: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'صورة الصفحة');
    } catch (e) {
      throw Exception('خطأ غير متوقع في الحصول على صورة الصفحة: $e');
    }
  }

  Future<DocumentSummaryResponse> getDocumentSummary(String sessionId) async {
    try {
      Response response = await _dio.get('/document/$sessionId/summary');
      
      if (response.statusCode == 200) {
        return DocumentSummaryResponse.fromJson(response.data);
      } else {
        throw Exception('فشل في الحصول على ملخص المستند: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'ملخص المستند');
    } catch (e) {
      throw Exception('خطأ غير متوقع في الحصول على ملخص المستند: $e');
    }
  }

  Future<bool> deleteDocumentSession(String sessionId) async {
    try {
      Response response = await _dio.delete('/document/$sessionId');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('خطأ في حذف جلسة المستند: ${e.message}');
      return false;
    } catch (e) {
      print('خطأ غير متوقع في حذف جلسة المستند: $e');
      return false;
    }
  }

  // Ask question about specific page
  Future<Map<String, dynamic>> askPageQuestion(String sessionId, int pageNumber, String question) async {
    try {
      Map<String, dynamic> requestData = {
        'question': question,
      };

      Response response = await _dio.post('/document/$sessionId/page/$pageNumber/question', data: requestData);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('فشل في طرح السؤال: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'طرح سؤال على الصفحة');
    } catch (e) {
      throw Exception('خطأ غير متوقع في طرح السؤال: $e');
    }
  }

  // Document Text-to-Speech
  Future<String> documentTextToSpeech(String text, {String provider = 'gemini'}) async {
    try {
      Map<String, dynamic> requestData = {
        'text': text,
        'provider': provider,
      };

      Response response = await _dio.post('/document/text-to-speech', data: requestData);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('فشل في تحويل النص إلى صوت: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'تحويل النص إلى صوت');
    } catch (e) {
      throw Exception('خطأ غير متوقع في تحويل النص إلى صوت: $e');
    }
  }

  // Document Speech-to-Text
  Future<String> documentSpeechToText(File audioFile, {String languageCode = 'ar'}) async {
    try {
      FormData formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(audioFile.path),
        'language_code': languageCode,
      });

      Response response = await _dio.post('/document/speech-to-text', data: formData);
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('فشل في تحويل الصوت إلى نص: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'تحويل الصوت إلى نص');
    } catch (e) {
      throw Exception('خطأ غير متوقع في تحويل الصوت إلى نص: $e');
    }
  }

  // Check document service health
  Future<bool> checkDocumentHealth() async {
    try {
      Response response = await _dio.get('/document/ping');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Health Check Methods
  Future<bool> checkFormAnalyzerHealth() async {
    try {
      Response response = await _dio.get('/form/ping');
      return response.statusCode == 200 && (response.data['status'] == 'healthy' || response.data['message'] != null);
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkMoneyReaderHealth() async {
    try {
      Response response = await _dio.get('/money/ping');
      return response.statusCode == 200 && (response.data['status'] == 'healthy' || response.data['message'] != null);
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkDocumentReaderHealth() async {
    try {
      Response response = await _dio.get('/document/ping');
      return response.statusCode == 200 && (response.data['status'] == 'healthy' || response.data['message'] != null);
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> checkSystemHealth() async {
    try {
      Response response = await _dio.get('/health');
      return response.data;
    } catch (e) {
      return {'status': 'error', 'message': 'فشل في الاتصال بالخادم'};
    }
  }

  Future<String> downloadForm(
    File imageFile,
    String format,
    Map<String, dynamic> formData,
    List<UIField> formFields,
    {String? signatureImageB64,
    String? signatureFieldId}
  ) async {
    try {
      print('💾 بدء تحميل النموذج بصيغة: $format');
      print('📁 ملف الصورة: ${imageFile.path}');
      print('📊 عدد الحقول: ${formFields.length}');
      print('📝 بيانات النموذج: $formData');
      print('✍️ هل يوجد توقيع: ${signatureImageB64 != null ? 'نعم' : 'لا'}');
      
      // Check if this is a PDF file by inspecting the file path
      bool isPdfFile = imageFile.path.toLowerCase().endsWith('.pdf');
      
      if (isPdfFile && format.toLowerCase() == 'pdf') {
        print('📄 معالجة ملف PDF...');
        
        // For PDF files, we need to get the session ID from file path or create one
        String sessionId = '';
        
        // Extract session ID from filename if possible (format: session_<id>.pdf)
        final fileNameParts = imageFile.path.split('/').last.split('_');
        if (fileNameParts.length > 1) {
          final potentialSessionId = fileNameParts[fileNameParts.length - 1].replaceAll('.pdf', '');
          if (potentialSessionId.length > 8) {
            sessionId = potentialSessionId;
            print('🔑 تم استخراج معرف الجلسة من اسم الملف: $sessionId');
          }
        }
        
        // If no session ID found, check for quality first
        if (sessionId.isEmpty) {
          print('🔍 فحص جودة ملف PDF أولاً...');
          final qualityResponse = await checkPdfQuality(imageFile);
          sessionId = qualityResponse['session_id'];
          print('🔑 تم إنشاء معرف جلسة جديد: $sessionId');
        }
        
        // Process the PDF using our new methods (with proper field ordering)
        return await processPdfDownload(
          sessionId,
          [1], // Assuming single page for simplicity, can be expanded
          [formData], // Single page data
          formFields,
          signatureImageB64: signatureImageB64,
          signatureFieldId: signatureFieldId,
        );
      } else {
        // For regular images or exporting to PNG, use the existing method
        // Read the image bytes
        final imageBytes = await imageFile.readAsBytes();
        print('📸 تم قراءة ${imageBytes.length} بايت من الصورة');
        
        // Convert form data to texts_dict format
        final textsDict = <String, dynamic>{};
        formData.forEach((key, value) {
          textsDict[key] = value.toString();
        });
        print('📝 تم تحويل البيانات: $textsDict');
        
        // Use the annotateImage method to get the annotated image bytes
        print('🖼️ بدء إنشاء الصورة المُعبأة...');
        final annotatedImageBytes = await annotateImage(
          originalImageBytes: imageBytes,
          textsDict: textsDict,
          uiFields: formFields,
          signatureImageB64: signatureImageB64,
          signatureFieldId: signatureFieldId,
        );
        print('✅ تم إنشاء الصورة المُعبأة: ${annotatedImageBytes.length} بايت');
        
        // Save the file based on format
        print('💾 بدء حفظ الملف...');
        final filePath = await _saveFile(annotatedImageBytes, format);
        print('✅ تم حفظ النموذج في: $filePath');
        return filePath;
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في تحميل النموذج: $e');
      print('📍 تفاصيل الخطأ: $stackTrace');
      throw Exception('خطأ في تحميل النموذج: $e');
    }
  }
  
  Future<String> _saveFile(Uint8List bytes, String format) async {
    try {
      // Get the downloads directory
      Directory? directory;
      
      if (Platform.isAndroid) {
        // For Android, try to use the Downloads folder
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // For other platforms, use documents directory
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory != null) {
        // Create filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'filled_form_$timestamp.${format.toLowerCase()}';
        final filePath = '${directory.path}/$fileName';
        
        if (format.toLowerCase() == 'png') {
          // Save as PNG
          final file = File(filePath);
          await file.writeAsBytes(bytes);
        } else if (format.toLowerCase() == 'pdf') {
          // Convert image to PDF and save
          await _saveAsPdf(bytes, filePath);
        }
        
        return filePath;
      } else {
        throw Exception('لا يمكن الوصول إلى مجلد التحميل');
      }
    } catch (e) {
      throw Exception('فشل في حفظ الملف: $e');
    }
  }
  
  Future<void> _saveAsPdf(Uint8List imageBytes, String filePath) async {
    try {
      // Create a simple PDF with the image
      final pdf = pw.Document();
      final image = pw.MemoryImage(imageBytes);
      
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
      
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
    } catch (e) {
      throw Exception('فشل في إنشاء ملف PDF: $e');
    }
  }

  // PDF Quality Check
  Future<Map<String, dynamic>> checkPdfQuality(File pdfFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          pdfFile.path,
          contentType: MediaType('application', 'pdf'),
        ),
      });

      final response = await _dio.post('form/check-pdf', data: formData);
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('فشل في فحص جودة ملف PDF');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'فحص جودة ملف PDF');
    } catch (e) {
      throw Exception('خطأ في فحص جودة ملف PDF: $e');
    }
  }

  // Analyze PDF Form
  Future<Map<String, dynamic>> analyzePdfForm({
    required String sessionId,
    String? languageDirection,
  }) async {
    try {
      final formData = FormData.fromMap({
        'session_id': sessionId,
        if (languageDirection != null) 'language_direction': languageDirection,
      });

      final response = await _dio.post('form/analyze-pdf', data: formData);
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('فشل في تحليل ملف PDF');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'تحليل ملف PDF');
    } catch (e) {
      throw Exception('خطأ في تحليل ملف PDF: $e');
    }
  }

  // Fill a PDF page with form data
  Future<Map<String, dynamic>> fillPdfPage({
    required String sessionId, 
    required int pageNumber,
    required Map<String, dynamic> textsDict,
    String? signatureImageB64,
    String? signatureFieldId,
  }) async {
    print('📝 بدء تعبئة صفحة PDF رقم $pageNumber...');
    print('🆔 معرف الجلسة: $sessionId');
    print('🖊️ عدد الحقول النصية: ${textsDict.length}');
    print('✍️ هل يوجد توقيع: ${signatureImageB64 != null ? 'نعم' : 'لا'}');
    
    try {
      // Convert textsDict to JSON string to ensure proper serialization
      final textsJsonString = jsonEncode(textsDict);
      
      // Create FormData with fields in the specific order expected by backend
      FormData formData = FormData.fromMap({
        'session_id': sessionId,
        'page_number': pageNumber,
        'texts_dict': textsJsonString,
      });
      
      // Add signature data only if provided
      if (signatureImageB64 != null) {
        formData.fields.add(MapEntry('signature_image_b64', signatureImageB64));
      }
      
      if (signatureFieldId != null) {
        formData.fields.add(MapEntry('signature_field_id', signatureFieldId));
      }
      
      print('📤 إرسال بيانات تعبئة الصفحة للخادم...');
      Response response = await post('/form/fill-pdf-page', data: formData);
      
      if (response.statusCode == 200) {
        print('✅ تم تعبئة صفحة PDF رقم $pageNumber بنجاح');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ فشل في تعبئة صفحة PDF - الكود: ${response.statusCode}');
        if (response.data != null && response.data['detail'] != null) {
          throw Exception(response.data['detail'].toString());
        }
        throw Exception('فشل في تعبئة صفحة PDF: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      print('❌ رسالة الخطأ: ${e.message}');
      if (e.response != null) {
        print('❌ كود الخطأ: ${e.response?.statusCode}');
        print('❌ بيانات الخطأ: ${e.response?.data}');
      }
      throw _handleDioError(e, 'تعبئة صفحة PDF');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في تعبئة صفحة PDF: $e');
    }
  }

  // PDF Exploration Methods
  
  // 1. Initial exploration of PDF file
  Future<Map<String, dynamic>> explorePdf(File pdfFile) async {
    print('📄 بدء استكشاف ملف PDF...');
    
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          pdfFile.path,
          contentType: MediaType('application', 'pdf'),
        ),
      });

      print('🌐 إرسال طلب استكشاف PDF...');
      final response = await _dio.post('form/explore-pdf', data: formData);
      
      if (response.statusCode == 200) {
        print('✅ تم استكشاف ملف PDF بنجاح');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ فشل في استكشاف ملف PDF - الكود: ${response.statusCode}');
        throw Exception('فشل في استكشاف ملف PDF');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      throw _handleDioError(e, 'استكشاف ملف PDF');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ في استكشاف ملف PDF: $e');
    }
  }

  // 2. Get explanation for a specific PDF page
  Future<Map<String, dynamic>> explainPdfPage({
    required String sessionId,
    required int pageNumber,
    String? languageDirection,
  }) async {
    print('📄 طلب شرح لصفحة PDF رقم $pageNumber...');
    print('🆔 معرف الجلسة: $sessionId');
    
    try {
      final formData = FormData.fromMap({
        'session_id': sessionId,
        'page_number': pageNumber,
        if (languageDirection != null) 'language_direction': languageDirection,
      });

      print('🌐 إرسال طلب شرح صفحة PDF...');
      final response = await _dio.post('form/explain-pdf-page', data: formData);
      
      if (response.statusCode == 200) {
        print('✅ تم شرح صفحة PDF بنجاح');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ فشل في شرح صفحة PDF - الكود: ${response.statusCode}');
        throw Exception('فشل في شرح صفحة PDF');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      throw _handleDioError(e, 'شرح صفحة PDF');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ في شرح صفحة PDF: $e');
    }
  }

  // 3. Analyze a specific PDF page
  Future<Map<String, dynamic>> analyzePdfPage({
    required String sessionId,
    required int pageNumber,
    String? languageDirection,
  }) async {
    print('📄 بدء تحليل صفحة PDF رقم $pageNumber...');
    print('🆔 معرف الجلسة: $sessionId');
    
    try {
      final formData = FormData.fromMap({
        'session_id': sessionId,
        'page_number': pageNumber,
        if (languageDirection != null) 'language_direction': languageDirection,
      });

      print('🌐 إرسال طلب تحليل صفحة PDF...');
      final response = await _dio.post('form/analyze-pdf-page', data: formData);
      
      if (response.statusCode == 200) {
        print('✅ تم تحليل صفحة PDF بنجاح');
        return response.data as Map<String, dynamic>;
      } else {
        print('❌ فشل في تحليل صفحة PDF - الكود: ${response.statusCode}');
        throw Exception('فشل في تحليل صفحة PDF');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      throw _handleDioError(e, 'تحليل صفحة PDF');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ في تحليل صفحة PDF: $e');
    }
  }

  // Helper method for downloading filled PDF
  Future<String> downloadFilledPdf(String sessionId) async {
    print('📥 بدء تحميل ملف PDF المعبأ - معرف الجلسة: $sessionId');
    
    try {
      Response response = await _dio.get(
        '/form/download-filled-pdf/$sessionId',
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.statusCode == 200) {
        print('✅ تم تحميل ملف PDF المعبأ بنجاح');
        
        // Save the PDF file
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'filled_pdf_$timestamp.pdf';
        final filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsBytes(response.data);
        
        print('💾 تم حفظ ملف PDF في: $filePath');
        return filePath;
      } else {
        print('❌ فشل في تحميل ملف PDF - الكود: ${response.statusCode}');
        throw Exception('فشل في تحميل ملف PDF المعبأ: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('❌ خطأ Dio: ${e.type}');
      throw _handleDioError(e, 'تحميل ملف PDF المعبأ');
    } catch (e) {
      print('❌ خطأ عام: $e');
      throw Exception('خطأ غير متوقع في تحميل ملف PDF المعبأ: $e');
    }
  }

  // Function to process PDF download after filling all pages
  Future<String> processPdfDownload(
    String sessionId, 
    List<int> pageNumbers, 
    List<Map<String, dynamic>> pageDataList,
    List<UIField> allFields,
    {String? signatureImageB64, String? signatureFieldId}
  ) async {
    print('🔄 بدء عملية معالجة وتحميل PDF - معرف الجلسة: $sessionId');
    print('📄 عدد الصفحات: ${pageNumbers.length}');
    
    try {
      // Process each page in the correct API sequence order
      for (int i = 0; i < pageNumbers.length; i++) {
        final pageNumber = pageNumbers[i];
        final pageData = pageDataList[i];
        
        print('📝 معالجة الصفحة $pageNumber (${i+1} من ${pageNumbers.length})');
        
        // 1. Analyze page (Ensures we have the latest field information)
        try {
          print('🔍 تحليل صفحة PDF رقم $pageNumber...');
          await analyzePdfPage(
            sessionId: sessionId,
            pageNumber: pageNumber,
          );
        } catch (e) {
          print('⚠️ تحذير: فشل في تحليل الصفحة $pageNumber: $e');
          // Continue even if analysis fails
        }
        
        // 2. Fill the page with data
        print('✏️ تعبئة صفحة PDF رقم $pageNumber...');
        await fillPdfPage(
          sessionId: sessionId,
          pageNumber: pageNumber,
          textsDict: pageData,
          signatureImageB64: signatureImageB64,
          signatureFieldId: signatureFieldId,
        );
      }
      
      // 3. Download the final PDF after all pages are filled
      print('📥 تحميل ملف PDF بعد تعبئة كل الصفحات...');
      final filePath = await downloadFilledPdf(sessionId);
      
      // Clean up session to avoid orphaned data on the server
      try {
        await deleteFormSession(sessionId);
        print('🗑️ تم حذف جلسة PDF: $sessionId');
      } catch (e) {
        print('⚠️ تحذير: فشل في حذف جلسة PDF: $e');
      }
      
      return filePath;
    } catch (e) {
      print('❌ خطأ في معالجة وتحميل PDF: $e');
      throw Exception('فشل في معالجة وتحميل PDF: $e');
    }
  }

  // Helper method for handling Dio errors
  Exception _handleDioError(DioException e, String operation) {
    String message;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        message = 'انتهت مهلة الاتصال أثناء $operation. يرجى التحقق من الإنترنت.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'انتهت مهلة إرسال البيانات أثناء $operation. الملف قد يكون كبير جداً.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'انتهت مهلة استقبال البيانات أثناء $operation. يرجى المحاولة لاحقاً.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode != null) {
          switch (statusCode) {
            case 400:
              message = 'خطأ في البيانات المرسلة. يرجى التأكد من صحة الملف.';
              break;
            case 401:
              message = 'خطأ في التخويل. يرجى إعادة تشغيل التطبيق.';
              break;
            case 403:
              message = 'ليس لديك صلاحية للوصول لهذه الخدمة.';
              break;
            case 404:
              message = 'الخدمة المطلوبة غير متاحة حالياً.';
              break;
            case 422:
              message = 'البيانات المرسلة غير صحيحة. يرجى التأكد من نوع الملف.';
              break;
            case 429:
              message = 'تم تجاوز الحد المسموح من الطلبات. يرجى المحاولة لاحقاً.';
              break;
            case 500:
              message = 'خطأ في الخادم أثناء $operation. يرجى المحاولة مرة أخرى.';
              break;
            case 502:
            case 503:
            case 504:
              message = 'الخادم غير متاح حالياً. يرجى المحاولة لاحقاً.';
              break;
            default:
              message = 'خطأ في الخادم (كود: $statusCode) أثناء $operation.';
          }
        } else {
          message = 'خطأ غير معروف في الاتصال أثناء $operation.';
        }
        break;
      case DioExceptionType.cancel:
        message = 'تم إلغاء العملية.';
        break;
      case DioExceptionType.connectionError:
        message = 'فشل في الاتصال بالخادم. يرجى التحقق من الإنترنت.';
        break;
      case DioExceptionType.badCertificate:
        message = 'خطأ في شهادة الأمان. يرجى التحقق من الاتصال.';
        break;
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true) {
          message = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';
        } else if (e.message?.contains('HandshakeException') == true) {
          message = 'خطأ في الاتصال الآمن. يرجى التحقق من الإنترنت.';
        } else {
          message = 'خطأ غير متوقع أثناء $operation: ${e.message}';
        }
    }
    
    print('🔥 Dio Error Handler: $message');
    return Exception(message);
  }
}