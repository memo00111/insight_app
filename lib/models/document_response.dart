class DocumentResponse {
  final String sessionId;
  final String filename;
  final String fileType;
  final int totalPages;
  final String language;
  final String presentationSummary;
  final String status;
  final String message;

  DocumentResponse({
    required this.sessionId,
    required this.filename,
    required this.fileType,
    required this.totalPages,
    required this.language,
    required this.presentationSummary,
    required this.status,
    required this.message,
  });

  factory DocumentResponse.fromJson(Map<String, dynamic> json) {
    return DocumentResponse(
      sessionId: json['session_id'] ?? '',
      filename: json['filename'] ?? '',
      fileType: json['file_type'] ?? '',
      totalPages: (json['total_pages'] is num) ? (json['total_pages'] as num).toInt() : 0,
      language: json['language'] ?? 'arabic',
      presentationSummary: json['presentation_summary'] ?? '',
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'filename': filename,
      'file_type': fileType,
      'total_pages': totalPages,
      'language': language,
      'presentation_summary': presentationSummary,
      'status': status,
      'message': message,
    };
  }

  bool get isSuccess => status.toLowerCase() == 'success';
  
  String get fileTypeInArabic {
    switch (fileType.toLowerCase()) {
      case '.pptx':
      case '.ppt':
        return 'عرض تقديمي';
      case '.pdf':
        return 'ملف PDF';
      case '.docx':
      case '.doc':
        return 'مستند Word';
      default:
        return 'مستند';
    }
  }
}

class SlideAnalysisResponse {
  final int pageNumber;
  final String title;
  final String originalText;
  final String explanation;
  final List<String> keyPoints;
  final String slideType;
  final String importanceLevel;
  final String imageData;
  final List<dynamic> paragraphs;
  final int wordCount;
  final int readingTime;

  SlideAnalysisResponse({
    required this.pageNumber,
    required this.title,
    required this.originalText,
    required this.explanation,
    required this.keyPoints,
    required this.slideType,
    required this.importanceLevel,
    required this.imageData,
    required this.paragraphs,
    required this.wordCount,
    required this.readingTime,
  });

  factory SlideAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return SlideAnalysisResponse(
      pageNumber: (json['page_number'] is num) ? (json['page_number'] as num).toInt() : 1,
      title: json['title'] ?? '',
      originalText: json['original_text'] ?? '',
      explanation: json['explanation'] ?? '',
      keyPoints: json['key_points'] != null 
          ? List<String>.from(json['key_points']) 
          : [],
      slideType: json['slide_type'] ?? 'content',
      importanceLevel: json['importance_level'] ?? 'medium',
      imageData: json['image_data'] ?? '',
      paragraphs: json['paragraphs'] ?? [],
      wordCount: (json['word_count'] is num) ? (json['word_count'] as num).toInt() : 0,
      readingTime: (json['reading_time'] is num) ? (json['reading_time'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_number': pageNumber,
      'title': title,
      'original_text': originalText,
      'explanation': explanation,
      'key_points': keyPoints,
      'slide_type': slideType,
      'importance_level': importanceLevel,
      'image_data': imageData,
      'paragraphs': paragraphs,
      'word_count': wordCount,
      'reading_time': readingTime,
    };
  }

  bool get hasImages => imageData.isNotEmpty;
  bool get hasText => originalText.isNotEmpty;
  bool get hasExplanation => explanation.isNotEmpty;
  bool get hasKeyPoints => keyPoints.isNotEmpty;
  
  String get slideText => originalText; // للتوافق مع الكود الحالي
  String get slideExplanation => explanation; // للتوافق مع الكود الحالي
  
  String get imagesCountInArabic {
    if (!hasImages) return 'لا توجد صور';
    return 'توجد صورة للشريحة';
  }
}

class DocumentSummaryResponse {
  final String sessionId;
  final String filename;
  final int totalPages;
  final String overallSummary;
  final List<String> keyTopics;
  final String language;
  final Map<String, dynamic>? metadata;

  DocumentSummaryResponse({
    required this.sessionId,
    required this.filename,
    required this.totalPages,
    required this.overallSummary,
    required this.keyTopics,
    required this.language,
    this.metadata,
  });

  factory DocumentSummaryResponse.fromJson(Map<String, dynamic> json) {
    return DocumentSummaryResponse(
      sessionId: json['session_id'] ?? '',
      filename: json['filename'] ?? '',
      totalPages: (json['total_pages'] is num) ? (json['total_pages'] as num).toInt() : 0,
      overallSummary: json['overall_summary'] ?? '',
      keyTopics: json['key_topics'] != null 
          ? List<String>.from(json['key_topics']) 
          : [],
      language: json['language'] ?? 'arabic',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'filename': filename,
      'total_pages': totalPages,
      'overall_summary': overallSummary,
      'key_topics': keyTopics,
      'language': language,
      'metadata': metadata,
    };
  }

  bool get hasKeyTopics => keyTopics.isNotEmpty;
  bool get hasSummary => overallSummary.isNotEmpty;
}

class NavigationResponse {
  final bool success;
  final int newPage;
  final String message;

  NavigationResponse({
    required this.success,
    required this.newPage,
    required this.message,
  });

  factory NavigationResponse.fromJson(Map<String, dynamic> json) {
    return NavigationResponse(
      success: json['success'] ?? false,
      newPage: (json['new_page'] is num) ? (json['new_page'] as num).toInt() : 1,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'new_page': newPage,
      'message': message,
    };
  }

  // للتوافق مع الكود الحالي
  int get targetPage => newPage;
} 