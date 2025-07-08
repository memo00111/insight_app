import 'dart:io';
import 'package:dio/dio.dart';
import 'constants.dart';

class NetworkHelper {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isApiReachable([String? baseUrl]) async {
    try {
      final url = baseUrl ?? AppConstants.baseUrl;
      final dio = Dio();
      final response = await dio.get(
        '$url/health',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> checkSystemHealth() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '${AppConstants.baseUrl}/health',
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      
      if (response.statusCode == 200) {
        return {
          'status': 'healthy',
          'message': 'النظام يعمل بشكل طبيعي',
          'data': response.data,
        };
      } else {
        return {
          'status': 'error',
          'message': 'خطأ في الخادم (${response.statusCode})',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': getErrorMessage(e),
        'data': null,
      };
    }
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'انتهت مهلة الاتصال - تحقق من الإنترنت';
        case DioExceptionType.sendTimeout:
          return 'انتهت مهلة الإرسال - حاول مرة أخرى';
        case DioExceptionType.receiveTimeout:
          return 'انتهت مهلة الاستقبال - الخادم بطيء';
        case DioExceptionType.connectionError:
          return 'فشل في الاتصال بالخادم - تحقق من الإنترنت';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          switch (statusCode) {
            case 400:
              return 'طلب غير صحيح - تحقق من البيانات المرسلة';
            case 401:
              return 'غير مخول - تحقق من صلاحيات الوصول';
            case 403:
              return 'ممنوع - ليس لديك صلاحية للوصول';
            case 404:
              return 'المورد غير موجود';
            case 429:
              return 'تم تجاوز الحد المسموح - حاول مرة أخرى لاحقاً';
            case 500:
              return 'خطأ داخلي في الخادم';
            case 502:
              return 'بوابة سيئة - الخادم غير متاح';
            case 503:
              return 'الخدمة غير متاحة - حاول لاحقاً';
            case 504:
              return 'انتهت مهلة البوابة';
            default:
              return 'خطأ في الخادم ($statusCode)';
          }
        case DioExceptionType.cancel:
          return 'تم إلغاء العملية';
        default:
          return 'خطأ في الشبكة - ${error.message}';
      }
    } else if (error is SocketException) {
      return 'فشل في الاتصال - تحقق من الإنترنت';
    } else if (error is FormatException) {
      return 'خطأ في تنسيق البيانات';
    } else {
      return 'خطأ غير متوقع: ${error.toString()}';
    }
  }

  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ].contains(error.type);
    }
    return error is SocketException;
  }

  static bool isServerError(dynamic error) {
    if (error is DioException && error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      return statusCode != null && statusCode >= 500;
    }
    return false;
  }

  static bool isClientError(dynamic error) {
    if (error is DioException && error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode;
      return statusCode != null && statusCode >= 400 && statusCode < 500;
    }
    return false;
  }

  static Future<bool> canRetryRequest(dynamic error) async {
    // Check if it's a network error that might be temporary
    if (isNetworkError(error)) {
      // Check if internet is available
      return await hasInternetConnection();
    }
    
    // Check if it's a server error (5xx) which might be temporary
    if (isServerError(error)) {
      return true;
    }
    
    // Don't retry client errors (4xx) as they're usually permanent
    if (isClientError(error)) {
      return false;
    }
    
    return false;
  }

  static Future<T> retryRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        final canRetry = await canRetryRequest(e);
        if (!canRetry) {
          rethrow;
        }
        
        // Exponential backoff
        final waitTime = Duration(
          milliseconds: delay.inMilliseconds * (1 << (attempts - 1)),
        );
        
        await Future.delayed(waitTime);
      }
    }
    
    throw Exception('تم تجاوز الحد الأقصى للمحاولات');
  }

  static Map<String, String> getHeaders({String? contentType}) {
    return {
      'Content-Type': contentType ?? 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Insight-Flutter-App/1.0.0',
      'X-App-Version': AppConstants.appVersion,
    };
  }

  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  static String sanitizeUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url.trimRight().replaceAll(RegExp(r'/+$'), '');
  }
} 