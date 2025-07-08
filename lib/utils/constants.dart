class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://stunning-cod-wrr9gwrwq6xxh999x-8000.app.github.dev';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  
  // File Types
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'bmp', 'gif'];
  static const List<String> supportedDocumentTypes = ['pdf', 'pptx', 'ppt', 'docx', 'doc'];
  
  // Maximum file sizes (in MB)
  static const int maxImageSizeMB = 10;
  static const int maxDocumentSizeMB = 50;
  
  // Languages
  static const Map<String, String> supportedLanguages = {
    'arabic': 'العربية',
    'english': 'English',
  };
  
  // Form Analysis Languages
  static const Map<String, String> formLanguages = {
    'rtl': 'العربية',
    'ltr': 'English',
  };
  
  // Storage Keys
  static const String lastSelectedLanguageKey = 'last_selected_language';
  static const String lastSelectedFormLanguageKey = 'last_selected_form_language';
  static const String appVersionKey = 'app_version';
  static const String firstLaunchKey = 'first_launch';
  static const String lastUsedTabKey = 'last_used_tab';
  
  // App Info
  static const String appName = 'Insight';
  static const String appVersion = '1.0.0';
  static const String developerName = 'Mohamed';
  static const String appDescription = 'المساعد الذكي للتحليل والقراءة';
  
  // Error Messages
  static const String noInternetError = 'لا يوجد اتصال بالإنترنت';
  static const String serverError = 'خطأ في الخادم';
  static const String unknownError = 'خطأ غير متوقع';
  static const String fileNotFoundError = 'لم يتم العثور على الملف';
  static const String fileSizeError = 'حجم الملف كبير جداً';
  static const String fileTypeError = 'نوع الملف غير مدعوم';
  
  // Success Messages
  static const String uploadSuccessMessage = 'تم رفع الملف بنجاح';
  static const String analysisSuccessMessage = 'تم التحليل بنجاح';
  static const String operationSuccessMessage = 'تمت العملية بنجاح';
  
  // Loading Messages
  static const String uploadingMessage = 'جاري رفع الملف...';
  static const String analyzingMessage = 'جاري التحليل...';
  static const String processingMessage = 'جاري المعالجة...';
  static const String loadingMessage = 'جاري التحميل...';
  
  // Feature Descriptions
  static const String formAnalyzerDescription = 'تحليل النماذج واستخراج الحقول القابلة للتعبئة';
  static const String moneyReaderDescription = 'تحديد نوع وقيمة العملات والأوراق النقدية';
  static const String documentReaderDescription = 'قراءة وتحليل ملفات PDF و PowerPoint';
  
  // Tips
  static const List<String> imageTips = [
    'تأكد من وضوح الصورة وجودة الإضاءة',
    'ضع الصورة في منتصف الإطار',
    'تجنب الظلال والانعكاسات',
    'استخدم خلفية واضحة ومتباينة',
  ];
  
  static const List<String> documentTips = [
    'الحد الأقصى لحجم الملف هو 50 ميجابايت',
    'الصيغ المدعومة: PDF, PPTX, PPT, DOCX, DOC',
    'تأكد من أن الملف غير محمي بكلمة مرور',
    'للحصول على أفضل النتائج، استخدم ملفات عالية الجودة',
  ];
}