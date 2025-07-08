import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  String _lastWords = '';
  String _lastError = '';
  String _status = '';
  
  // Getters
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;
  String get lastError => _lastError;
  String get status => _status;

  // Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => _lastError = error.errorMsg,
        onStatus: (status) => _status = status,
      );
      return _isInitialized;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  // Start listening
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'ar_SA',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    if (_isListening) return;

    try {
      _isListening = true;
      _lastWords = '';
      
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            onResult(_lastWords);
          }
        },
        localeId: localeId,
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(partialResults: false),
      );
      } catch (e) {
        _isListening = false;
      }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speech.stop();
      _isListening = false;
    } catch (e) {
      _lastError = e.toString();
    }
  }

  // Parse page number from Arabic speech
  int? parsePageNumber(String text) {
    text = text.toLowerCase().trim();
    
    // Remove common words
    text = text.replaceAll(RegExp(r'(page|number|go|to)'), '');
    text = text.trim();
    
    // Extract digits
    final digitMatch = RegExp(r'\d+').firstMatch(text);
    if (digitMatch != null) {
      return int.tryParse(digitMatch.group(0)!);
    }
    
    return null;
  }

  // Parse form field data from speech (محسن)
  Map<String, String> parseFormData(String text) {
    final data = <String, String>{};
    text = text.toLowerCase().trim();
    
    // إزالة علامات الترقيم غير المرغوب فيها
    text = text.replaceAll(RegExp(r'[،,؛;]'), ' ');
    
    // أنماط البحث المحسنة للبيانات العربية
    final patterns = {
      'الاسم': [
        r'(?:اسم|الاسم|اسمي|اسمي هو)\s*:?\s*([أ-ي\s]+?)(?:\s|$|رقم|هوية|عمر|تاريخ|هاتف|عنوان|ايميل)',
        r'اسم\s+([أ-ي\s]+?)(?:\s*رقم|\s*$)',
      ],
      'رقم الهوية': [
        r'(?:رقم الهوية|هوية|رقم هوية|الرقم القومي|رقم قومي)\s*:?\s*(\d+)',
        r'هوية\s+(\d+)',
      ],
      'تاريخ الميلاد': [
        r'(?:تاريخ الميلاد|الميلاد|تاريخ ميلاد|ولدت في|مولود في)\s*:?\s*(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
        r'(?:تاريخ الميلاد|الميلاد)\s*:?\s*(\d{1,2}\s+\d{1,2}\s+\d{2,4})',
      ],
      'العمر': [
        r'(?:العمر|عمر|عمري|سني)\s*:?\s*(\d+)(?:\s*سنة|\s*عام|\s|$)',
      ],
      'رقم الهاتف': [
        r'(?:هاتف|رقم الهاتف|موبايل|جوال|تليفون)\s*:?\s*(\+?\d[\d\s-]{8,})',
      ],
      'العنوان': [
        r'(?:عنوان|العنوان|السكن|أسكن في|أقيم في)\s*:?\s*([^،\n]+?)(?:\s*هاتف|\s*ايميل|\s*$)',
      ],
      'البريد الإلكتروني': [
        r'(?:ايميل|بريد|بريد الكتروني|إيميل)\s*:?\s*(\S+@\S+\.\S+)',
      ],
    };
    
    // البحث عن كل نمط
    for (final fieldEntry in patterns.entries) {
      final fieldName = fieldEntry.key;
      final fieldPatterns = fieldEntry.value;
      
      for (final pattern in fieldPatterns) {
        final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
        if (match != null && match.group(1) != null) {
          String value = match.group(1)!.trim();
          
          // تنظيف القيمة المستخرجة
          if (fieldName == 'الاسم') {
            value = _cleanName(value);
          } else if (fieldName == 'رقم الهاتف') {
            value = _cleanPhoneNumber(value);
          } else if (fieldName == 'العنوان') {
            value = _cleanAddress(value);
          }
          
          if (value.isNotEmpty) {
            data[fieldName] = value;
            break; // إيجاد أول تطابق صحيح
          }
        }
      }
    }
    
    return data;
  }

  // تنظيف الاسم
  String _cleanName(String name) {
    name = name.trim();
    // إزالة الكلمات الزائدة
    name = name.replaceAll(RegExp(r'(هو|هي|اسم|اسمي)'), '');
    name = name.trim();
    
    // التأكد من وجود حروف عربية فقط ومسافات
    if (RegExp(r'^[أ-ي\s]+$').hasMatch(name) && name.split(' ').length >= 2) {
      return name;
    }
    return '';
  }

  // تنظيف رقم الهاتف
  String _cleanPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.length >= 10) {
      return phone;
    }
    return '';
  }

  // تنظيف العنوان
  String _cleanAddress(String address) {
    address = address.trim();
    // إزالة الكلمات الزائدة
    address = address.replaceAll(RegExp(r'(في|أسكن|أقيم|عنوان)'), '');
    address = address.trim();
    
    if (address.length >= 5) {
      return address;
    }
    return '';
  }

  // Check microphone permission
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  // Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  // Dispose
  void dispose() {
    if (_isListening) {
      stopListening();
    }
  }
}
