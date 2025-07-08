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

class AppProvider extends ChangeNotifier {
  final InsightApiService _apiService = InsightApiService();
  final ImagePicker _picker = ImagePicker();
  late final AudioRecorder _audioRecorder;
  
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
  
  void setVoiceAssistantEnabled(bool value) {
    _isVoiceAssistantEnabled = value;
    notifyListeners();
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
    pingMoneyReader(); // Check service status on startup
  }

  // Method to ping the Money Reader service
  Future<void> pingMoneyReader() async {
    try {
      final response = await _apiService.pingMoneyReader();
      print('Money Reader Service Status: ${response['status']}');
    } catch (e) {
      print('Error pinging Money Reader service: $e');
      _currencyErrorMessage = 'فشل في الاتصال بخدمة تحليل العملات';
      notifyListeners();
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
      _currencyErrorMessage = e.toString();
    } finally {
      _isCurrencyAnalyzing = false;
      notifyListeners();
    }
  }
  
  void clearCurrencyAnalysis() {
    _currencyAnalysisResult = null;
    _currencyErrorMessage = null;
    notifyListeners();
  }

  void clearDocumentAnalysis() {
    _documentUploadResult = null;
    _currentSlideAnalysis = null;
    _documentErrorMessage = null;
    _currentSessionId = null;
    _currentPageNumber = 1;
    notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
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
        notifyListeners();
      }
    } catch (e) {
      _documentErrorMessage = e.toString();
      notifyListeners();
    }
  }

  // Document validation and utility methods
  Future<void> navigateToPage(int pageNumber) async {
    if (!hasActiveDocument) {
      _documentErrorMessage = 'لا توجد جلسة مستند نشطة';
      notifyListeners();
      return;
    }
    
    if (pageNumber < 1 || pageNumber > _documentUploadResult!.totalPages) {
      _documentErrorMessage = 'رقم الصفحة غير صحيح. يجب أن يكون بين 1 و ${_documentUploadResult!.totalPages}';
      notifyListeners();
      return;
    }
    
    await _analyzeSlide(pageNumber);
  }

  void clearDocumentError() {
    _documentErrorMessage = null;
    notifyListeners();
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
      final tempPath = '${tempDir.path}/temp_audio.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: tempPath,
      );

      // Wait for user to stop recording (this should be handled by UI)
      await Future.delayed(const Duration(seconds: 10));

      // Stop recording
      final path = await _audioRecorder.stop();
      
      if (path == null) {
        throw Exception('Failed to save audio recording');
      }

      return File(path);
    } catch (e) {
      debugPrint('Error recording audio: $e');
      return null;
    }
  }

  // Form Image Quality Check
  Future<Map<String, dynamic>> checkFormImageQuality(File imageFile) async {
    // تأجيل notifyListeners إلى ما بعد البناء
    _isFormAnalyzing = true;
    _formErrorMessage = null;
    await Future.delayed(Duration.zero);
    notifyListeners();

    try {
      final result = await _apiService.checkFormImageQuality(imageFile);
      _formSessionId = result['session_id'];
      return result;
    } catch (e) {
      _formErrorMessage = e.toString();
      throw e;
    } finally {
      _isFormAnalyzing = false;
      notifyListeners();
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
    notifyListeners();

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
      notifyListeners();
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
      notifyListeners();
      throw e;
    }
  }

  // 4. Text to Speech for Forms
  Future<Uint8List> convertFormTextToSpeech(String text) async {
    try {
      return await _apiService.formTextToSpeech(text);
    } catch (e) {
      _formErrorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }

  // 5. Speech to Text for Forms
  Future<String> convertFormSpeechToText(Uint8List audioBytes, String languageCode) async {
    try {
      return await _apiService.formSpeechToText(audioBytes, languageCode);
    } catch (e) {
      _formErrorMessage = e.toString();
      notifyListeners();
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
      notifyListeners();
    } catch (e) {
      _formErrorMessage = e.toString();
      notifyListeners();
      throw e;
    }
  }

  // 7. Get Session Info
  Future<Map<String, dynamic>> getFormSessionInfo() async {
    try {
      return await _apiService.getFormSessionInfo();
    } catch (e) {
      _formErrorMessage = e.toString();
      notifyListeners();
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
    notifyListeners();
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
    super.dispose();
  }
}