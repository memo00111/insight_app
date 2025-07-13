import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/insight_api_service.dart';
import '../models/currency_analysis_response.dart';
import '../models/document_response.dart';
import '../models/form_analysis_response.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/connection_manager.dart';

class AppProvider extends ChangeNotifier {
  final InsightApiService _apiService = InsightApiService();
  final ImagePicker _picker = ImagePicker();
  late final AudioRecorder _audioRecorder;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Helper method to safely call notifyListeners
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  
  // Connection status
  final ConnectionManager _connectionManager = ConnectionManager();
  bool _isOnline = true;
  StreamSubscription<bool>? _connectionSubscription;
  
  // Loading states
  bool _isCurrencyAnalyzing = false;
  bool _isDocumentUploading = false;
  bool _isDocumentAnalyzing = false;
  
  // Current tab index
  int _currentTabIndex = 0;
  
  // Currency analysis data
  CurrencyAnalysisResponse? _currencyAnalysisResult;
  String? _currencyErrorMessage;
  
  // Document analysis data
  DocumentResponse? _documentUploadResult;
  SlideAnalysisResponse? _currentSlideAnalysis;
  String? _documentErrorMessage;
  String? _currentSessionId;
  int _currentPageNumber = 1;
  
  // Voice assistant state
  bool _isVoiceAssistantEnabled = false;
  bool get isVoiceAssistantEnabled => _isVoiceAssistantEnabled;
  bool get isOnline => _isOnline;
  
  void setVoiceAssistantEnabled(bool value) {
    _isVoiceAssistantEnabled = value;
    _safeNotifyListeners();
  }

  // Method to play audio from bytes
  Future<void> playAudioBytes(Uint8List audioBytes) async {
    try {
      // Create a temporary file for the audio
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(audioBytes);
      
      // Play audio using just_audio
      final player = AudioPlayer();
      await player.setFilePath(tempPath);
      await player.play();
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل الصوت: $e');
      rethrow; // Re-throw the exception so it can be handled by the caller
    }
  }
  
  // Getters
  InsightApiService get apiService => _apiService;
  bool get isCurrencyAnalyzing => _isCurrencyAnalyzing;
  bool get isDocumentUploading => _isDocumentUploading;
  bool get isDocumentAnalyzing => _isDocumentAnalyzing;
  
  int get currentTabIndex => _currentTabIndex;
  
  CurrencyAnalysisResponse? get currencyAnalysisResult => _currencyAnalysisResult;
  String? get currencyErrorMessage => _currencyErrorMessage;
  
  DocumentResponse? get documentUploadResult => _documentUploadResult;
  SlideAnalysisResponse? get currentSlideAnalysis => _currentSlideAnalysis;
  String? get documentErrorMessage => _documentErrorMessage;
  String? get currentSessionId => _currentSessionId;
  int get currentPageNumber => _currentPageNumber;

  // Form Analyzer data
  bool _isFormAnalyzing = false;
  String? _formSessionId;
  String? _formErrorMessage;
  
  // Form Analyzer getters
  bool get isFormAnalyzing => _isFormAnalyzing;
  String? get formSessionId => _formSessionId;
  String? get formErrorMessage => _formErrorMessage;

  AppProvider() {
    _audioRecorder = AudioRecorder();
    // تأجيل عمليات التهيئة لتجنب استدعاء notifyListeners أثناء البناء
    Future.microtask(() {
      _initConnectionManager();
      pingMoneyReader(); // Check service status on startup
    });
  }

  // Initialize connection manager
  Future<void> _initConnectionManager() async {
    await _connectionManager.initialize();
    _isOnline = _connectionManager.hasConnection;
    
    _connectionSubscription = _connectionManager.connectionStream.listen((isConnected) {
      _isOnline = isConnected;
      
      // تأجيل notifyListeners لتجنب استدعائه أثناء البناء
      _safeNotifyListeners();
      
      if (isConnected) {
        debugPrint('🌐 تم استعادة الاتصال بالإنترنت، جارٍ تحديث الحالة');
        // Optionally refresh data when connection is restored
        Future.microtask(() => pingMoneyReader());
      } else {
        debugPrint('🔌 تم فقد الاتصال بالإنترنت');
      }
    });
  }

  // Method to ping the Money Reader service
  Future<void> pingMoneyReader() async {
    try {
      final response = await _apiService.pingMoneyReader();
      print('Money Reader Service Status: ${response['status']}');
    } catch (e) {
      print('Error pinging Money Reader service: $e');
      _currencyErrorMessage = 'فشل في الاتصال بخدمة تحليل العملات';
      
      // تأجيل notifyListeners لتجنب استدعائه أثناء البناء
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Health check for document service
  Future<bool> checkDocumentServiceHealth() async {
    try {
      final health = await _apiService.checkSystemHealth();
      return health['status'] == 'healthy' || health.containsKey('services');
    } catch (e) {
      print('Error checking document service health: $e');
      return false;
    }
  }

  // Method to analyze currency from an image
  Future<void> analyzeCurrency(File imageFile) async {
    _isCurrencyAnalyzing = true;
    _currencyErrorMessage = null;
    _currencyAnalysisResult = null;
    notifyListeners();

    try {
      final result = await _apiService.analyzeMoney(imageFile);
      _currencyAnalysisResult = result;
    } catch (e) {
      // عدم حفظ أي رسالة خطأ
      debugPrint('Error analyzing currency: $e');
    } finally {
      _isCurrencyAnalyzing = false;
      notifyListeners();
    }
  }
  
  void clearCurrencyAnalysis() {
    _currencyAnalysisResult = null;
    _currencyErrorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void clearDocumentAnalysis() {
    _documentUploadResult = null;
    _currentSlideAnalysis = null;
    _documentErrorMessage = null;
    _currentSessionId = null;
    _currentPageNumber = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Additional utility methods
  bool get hasActiveDocument => _currentSessionId != null && _documentUploadResult != null;
  
  bool get canNavigateNext => hasActiveDocument && 
      _currentPageNumber < _documentUploadResult!.totalPages;
      
  bool get canNavigatePrevious => hasActiveDocument && _currentPageNumber > 1;
  
  String get documentStatusMessage {
    if (_isDocumentUploading) return 'جاري رفع المستند...';
    if (_isDocumentAnalyzing) return 'جاري تحليل الصفحة...';
    if (_documentErrorMessage != null) return _documentErrorMessage!;
    if (hasActiveDocument) return 'المستند جاهز للتصفح';
    return 'لم يتم رفع أي مستند';
  }

  // Setters
  void setCurrentTabIndex(int index) {
    _currentTabIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
  
  // Image picking methods
  Future<XFile?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // File picking method for PDFs
  Future<PlatformFile?> pickFile({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['pdf'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }
  
  // Document upload and analysis methods
  Future<void> uploadDocument(String filePath, {String language = 'arabic'}) async {
    _isDocumentUploading = true;
    _documentErrorMessage = null;
    _documentUploadResult = null;
    _currentSlideAnalysis = null;
    _currentSessionId = null;
    _currentPageNumber = 1;
    notifyListeners();

    try {
      final result = await _apiService.uploadDocument(filePath, language: language);
      _documentUploadResult = result;
      _currentSessionId = result.sessionId;
      
      // Automatically analyze the first page
      if (result.isSuccess && result.totalPages > 0) {
        await _analyzeSlide(1);
      }
    } catch (e) {
      _documentErrorMessage = e.toString();
    } finally {
      _isDocumentUploading = false;
      notifyListeners();
    }
  }

  Future<void> _analyzeSlide(int pageNumber) async {
    if (_currentSessionId == null) return;
    
    _isDocumentAnalyzing = true;
    _documentErrorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getPageAnalysis(_currentSessionId!, pageNumber);
      _currentSlideAnalysis = result;
      _currentPageNumber = pageNumber;
    } catch (e) {
      _documentErrorMessage = e.toString();
    } finally {
      _isDocumentAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> navigateToNextPage() async {
    if (_documentUploadResult != null && 
        _currentPageNumber < _documentUploadResult!.totalPages) {
      await _analyzeSlide(_currentPageNumber + 1);
    }
  }

  Future<void> navigateToPreviousPage() async {
    if (_currentPageNumber > 1) {
      await _analyzeSlide(_currentPageNumber - 1);
    }
  }

  Future<void> navigateWithVoice(String voiceCommand) async {
    if (_currentSessionId == null) {
      _documentErrorMessage = 'لا توجد جلسة مستند نشطة';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }

    try {
      final result = await _apiService.navigateDocument(_currentSessionId!, voiceCommand, currentPage: _currentPageNumber);
      if (result.targetPage > 0 && 
          _documentUploadResult != null &&
          result.targetPage <= _documentUploadResult!.totalPages) {
        await _analyzeSlide(result.targetPage);
      } else {
        _documentErrorMessage = result.message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      _documentErrorMessage = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Document validation and utility methods
  Future<void> navigateToPage(int pageNumber) async {
    if (!hasActiveDocument) {
      _documentErrorMessage = 'لا توجد جلسة مستند نشطة';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }
    
    if (pageNumber < 1 || pageNumber > _documentUploadResult!.totalPages) {
      _documentErrorMessage = 'رقم الصفحة غير صحيح. يجب أن يكون بين 1 و ${_documentUploadResult!.totalPages}';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      return;
    }
    
    await _analyzeSlide(pageNumber);
  }

  void clearDocumentError() {
    _documentErrorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> retryLastOperation() async {
    if (_currentSessionId != null && _currentPageNumber > 0) {
      await _analyzeSlide(_currentPageNumber);
    }
  }
  
  // Audio recording methods
  Future<File?> recordAudio() async {
    try {
      // Request microphone permission
      if (!await _audioRecorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Get temporary directory for saving audio file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/temp_audio.wav'; // تغيير إلى WAV

      // Start recording with WAV format
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav, // تغيير إلى WAV
          sampleRate: 16000, // تحديد معدل العينة المناسب
          bitRate: 128000,
        ),
        path: tempPath,
      );

      // Return the path immediately - the UI will handle stopping
      return File(tempPath);
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
      return null;
    }
  }

  Future<File?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path == null) {
        throw Exception('Failed to save audio recording');
      }
      return File(path);
    } catch (e) {
      debugPrint('Error stopping audio recording: $e');
      return null;
    }
  }

  // Play audio from API
  Future<void> playAudio(String audioUrl) async {
    try {
      // Stop any ongoing playback
      await _audioPlayer.stop();
      
      // Set the audio source to the provided URL
      await _audioPlayer.setUrl(audioUrl);
      
      // Play the audio
      _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  // Form Image Quality Check
  Future<Map<String, dynamic>> checkFormImageQuality(File imageFile) async {
    _isFormAnalyzing = true;
    _formErrorMessage = null;
    
    // تأجيل notifyListeners إلى ما بعد البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final result = await _apiService.checkFormImageQuality(imageFile);
      _formSessionId = result['session_id'];
      return result;
    } catch (e) {
      _formErrorMessage = e.toString();
      throw e;
    } finally {
      _isFormAnalyzing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // 2. Analyze Form
  Future<FormAnalysisResponse> analyzeForm({
    required File imageFile,
    required String sessionId,
    String? languageDirection,
  }) async {
    _isFormAnalyzing = true;
    _formErrorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final result = await _apiService.analyzeFormData(
        imageFile,
        sessionId,
        languageDirection: languageDirection,
      );
      return result;
    } catch (e) {
      _formErrorMessage = e.toString();
      throw e;
    } finally {
      _isFormAnalyzing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // 3. Annotate Image (Live Preview)
  Future<Uint8List> getFormAnnotatedImage({
    required Uint8List originalImageBytes,
    required Map<String, dynamic> textsDict,
    required List<UIField> uiFields,
    String? signatureImageB64,
    String? signatureFieldId,
  }) async {
    try {
      return await _apiService.annotateImage(
        originalImageBytes: originalImageBytes,
        textsDict: textsDict,
        uiFields: uiFields,
        signatureImageB64: signatureImageB64,
        signatureFieldId: signatureFieldId,
      );
    } catch (e) {
      _formErrorMessage = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      throw e;
    }
  }

  // 4. Text to Speech for Forms
  Future<Uint8List> convertFormTextToSpeech(String text) async {
    try {
      return await _apiService.formTextToSpeech(text);
    } catch (e) {
      _formErrorMessage = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      throw e;
    }
  }

  // 5. Speech to Text for Forms
  Future<String> convertFormSpeechToText(Uint8List audioBytes, String languageCode) async {
    try {
      return await _apiService.formSpeechToText(audioBytes, languageCode);
    } catch (e) {
      _formErrorMessage = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      throw e;
    }
  }

  // 6. Delete Form Session
  Future<void> deleteFormSession(String sessionId) async {
    try {
      await _apiService.deleteFormSession(sessionId);
      if (_formSessionId == sessionId) {
        _formSessionId = null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _formErrorMessage = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      throw e;
    }
  }

  // 7. Get Session Info
  Future<Map<String, dynamic>> getFormSessionInfo() async {
    try {
      return await _apiService.getFormSessionInfo();
    } catch (e) {
      _formErrorMessage = e.toString();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      throw e;
    }
  }

  // Helper method for signature field detection
  static bool isSignatureField(String label) {
    return InsightApiService.isSignatureField(label);
  }

  // Clear form error
  void clearFormError() {
    _formErrorMessage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // Request storage permissions
  Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        final manageStorageStatus = await Permission.manageExternalStorage.request();
        
        return storageStatus.isGranted || manageStorageStatus.isGranted;
      } else {
        // For iOS, storage permission is handled differently
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _connectionSubscription?.cancel();
    _connectionManager.dispose();
    super.dispose();
  }
}