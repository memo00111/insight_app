class ImageQualityResponse {
  final String languageDirection;
  final bool qualityGood;
  final String qualityMessage;
  final int imageWidth;
  final int imageHeight;
  final String sessionId;
  final String formExplanation;

  ImageQualityResponse({
    required this.languageDirection,
    required this.qualityGood,
    required this.qualityMessage,
    required this.imageWidth,
    required this.imageHeight,
    required this.sessionId,
    required this.formExplanation,
  });

  factory ImageQualityResponse.fromJson(Map<String, dynamic> json) {
    // Log the incoming data for debugging
    print('🔍 ImageQualityResponse.fromJson - البيانات الواردة:');
    json.forEach((key, value) {
      print('   $key: $value (نوع: ${value.runtimeType})');
    });
    
    final languageDirection = json['language_direction']?.toString() ?? 'rtl';
    final qualityGood = json['quality_good'] ?? false;
    final sessionId = json['session_id']?.toString() ?? '';
    
    print('🔍 القيم المستخرجة:');
    print('   languageDirection: "$languageDirection"');
    print('   qualityGood: $qualityGood');
    print('   sessionId: "$sessionId"');
    
    return ImageQualityResponse(
      languageDirection: languageDirection,
      qualityGood: qualityGood,
      qualityMessage: json['quality_message']?.toString() ?? '',
      imageWidth: json['image_width'] ?? 0,
      imageHeight: json['image_height'] ?? 0,
      sessionId: sessionId,
      formExplanation: json['form_explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language_direction': languageDirection,
      'quality_good': qualityGood,
      'quality_message': qualityMessage,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'session_id': sessionId,
      'form_explanation': formExplanation,
    };
  }
}

class SpeechToTextResponse {
  final String text;

  SpeechToTextResponse({
    required this.text,
  });

  factory SpeechToTextResponse.fromJson(Map<String, dynamic> json) {
    return SpeechToTextResponse(
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}

class SessionInfoResponse {
  final int activeSessions;
  final int sessionTimeout;

  SessionInfoResponse({
    required this.activeSessions,
    required this.sessionTimeout,
  });

  factory SessionInfoResponse.fromJson(Map<String, dynamic> json) {
    return SessionInfoResponse(
      activeSessions: json['active_sessions'] ?? 0,
      sessionTimeout: json['session_timeout'] ?? 3600,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active_sessions': activeSessions,
      'session_timeout': sessionTimeout,
    };
  }
}

class FormAnalyzerException implements Exception {
  final String message;
  final int statusCode;

  FormAnalyzerException(this.message, this.statusCode);

  @override
  String toString() => 'FormAnalyzerException: $message (Status: $statusCode)';
}

class QuotaExceededException extends FormAnalyzerException {
  QuotaExceededException(String message) : super(message, 429);
}
