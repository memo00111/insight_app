import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/form_analysis_response.dart';
import 'image_quality_check_screen.dart';

class FormAnalyzerScreen extends StatefulWidget {
  const FormAnalyzerScreen({super.key});

  @override
  State<FormAnalyzerScreen> createState() => _FormAnalyzerScreenState();
}

class _FormAnalyzerScreenState extends State<FormAnalyzerScreen> {
  bool _isLoading = false;
  bool _voiceAssistantEnabled = false;
  String? _sessionId;
  String? _languageDirection;
  List<UIField> _formFields = [];
  File? _selectedImage;
  File? _selectedFile; // For PDF files
  Uint8List? _annotatedImage;
  Uint8List? _signatureImage; // For signature image
  int _currentFieldIndex = 0;
  String? _formExplanation;
  Map<String, dynamic> _formData = {};
  bool _isAnalyzing = false;
  bool _isPdfFile = false;
  String? _signatureFieldId; // ID of the field that requires signature
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // لا تعيّن اللغة افتراضياً هنا، اعتمد فقط على ما يأتي من arguments
    _loadVoiceAssistantState();
    _checkForPassedArguments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkForPassedArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is Map<String, dynamic>) {
        setState(() {
          _selectedImage = arguments['imageFile'] as File?;
          _sessionId = arguments['sessionId'] as String?;
          _languageDirection = arguments['languageDirection'] as String?;
        });
        if (_selectedImage != null && _sessionId != null) {
          _analyzeForm();
        }
      }
    });
  }

  Future<void> _loadVoiceAssistantState() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _voiceAssistantEnabled = appProvider.isVoiceAssistantEnabled;
    });
  }

  Future<void> _pickAndAnalyzeImage() async {
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Show dialog to choose between image and PDF
      final choice = await _showFileTypeDialog();
      if (choice == null) return;
      
      File? pickedFile;
      if (choice == 'image') {
        final imageFile = await appProvider.pickImage();
        if (imageFile != null) {
          pickedFile = File(imageFile.path);
          _isPdfFile = false;
        }
      } else if (choice == 'pdf') {
        final pdfFile = await appProvider.pickFile(allowedExtensions: ['pdf']);
        if (pdfFile != null && pdfFile.path != null) {
          pickedFile = File(pdfFile.path!);
          _isPdfFile = true;
        }
      }
      
      if (pickedFile != null && mounted) {
        setState(() {
          if (_isPdfFile) {
            _selectedFile = pickedFile;
          } else {
            _selectedImage = pickedFile;
          }
        });
        
        // Navigate to appropriate quality check screen based on file type
        if (_isPdfFile) {
          // For PDF files, directly analyze without quality check
          _analyzePdfFile();
        } else {
          // For images, use existing quality check
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageQualityCheckScreen(imageFile: pickedFile!),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('خطأ في اختيار الملف', e.toString());
      }
    }
  }

  Future<String?> _showFileTypeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text((_languageDirection ?? 'rtl') == 'rtl' ? 'اختر نوع الملف' : 'Choose File Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text((_languageDirection ?? 'rtl') == 'rtl' ? 'صورة' : 'Image'),
              subtitle: Text((_languageDirection ?? 'rtl') == 'rtl' ? 'JPG, PNG' : 'JPG, PNG'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text((_languageDirection ?? 'rtl') == 'rtl' ? 'ملف PDF' : 'PDF File'),
              subtitle: Text((_languageDirection ?? 'rtl') == 'rtl' ? 'مستندات PDF' : 'PDF Documents'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text((_languageDirection ?? 'rtl') == 'rtl' ? 'إلغاء' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeForm() async {
    if (_selectedImage == null || _sessionId == null) return;

    setState(() {
      _isLoading = true;
      _isAnalyzing = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);

      // Debug: اطبع اللغة قبل التحليل
      debugPrint('🔤 languageDirection before analyzeForm: ${_languageDirection ?? 'null'}');

      // تأكد أن اللغة إما rtl أو ltr فقط، وإلا أرسل rtl افتراضياً
      String langToSend = (_languageDirection == null || _languageDirection!.isEmpty)
          ? 'rtl'
          : _languageDirection!.toLowerCase();
      if (langToSend != 'rtl' && langToSend != 'ltr') {
        langToSend = 'rtl';
      }
      debugPrint('🔤 languageDirection sent to API: $langToSend');

      final analysisResponse = await appProvider.analyzeForm(
        imageFile: _selectedImage!,
        sessionId: _sessionId!,
        languageDirection: langToSend,
      );

      setState(() {
        _formFields = analysisResponse.fields;
        _formExplanation = analysisResponse.formExplanation;
        _isLoading = false;
        _isAnalyzing = false;
        _currentFieldIndex = 0;
        _formData = {};
      });

      // Show form explanation if available
      if (_formExplanation != null && _formExplanation!.isNotEmpty) {
        _showFormExplanation();
      }

      // Start field filling process
      if (_formFields.isNotEmpty) {
        _updateLivePreview();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isAnalyzing = false;
      });

      // Show more detailed error message
      String errorMessage = e.toString();
      if (errorMessage.contains('500')) {
        errorMessage = _languageDirection == 'rtl'
            ? 'خطأ في الخادم. يرجى المحاولة مرة أخرى.'
            : 'Server error. Please try again.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = _languageDirection == 'rtl'
            ? 'انتهت مهلة الاتصال. يرجى التحقق من الاتصال بالإنترنت.'
            : 'Connection timeout. Please check your internet connection.';
      }

      _showErrorDialog('خطأ في تحليل النموذج', errorMessage);
    }
  }

  Future<void> _analyzePdfFile() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isLoading = true;
      _isAnalyzing = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // First check PDF quality and get session
      final qualityResponse = await appProvider.apiService.checkPdfQuality(_selectedFile!);
      
      if (!qualityResponse['quality_good']) {
        setState(() {
          _isLoading = false;
          _isAnalyzing = false;
        });
        _showErrorDialog('جودة الملف', qualityResponse['quality_message'] ?? 'جودة الملف منخفضة');
        return;
      }
      
      final sessionId = qualityResponse['session_id'];
      final recommendedLanguage = qualityResponse['recommended_language'];
      
      // Analyze PDF form
      final analysisResponse = await appProvider.apiService.analyzePdfForm(
        sessionId: sessionId,
        languageDirection: recommendedLanguage,
      );
      
      setState(() {
        _sessionId = sessionId;
        _languageDirection = recommendedLanguage;
        // For multi-page PDFs, we'll use the first page with fields
        final firstPageWithFields = analysisResponse['pages']?.firstWhere(
          (page) => page['has_fields'] == true,
          orElse: () => analysisResponse['pages']?.first,
        );
        
        if (firstPageWithFields != null) {
          _formFields = (firstPageWithFields['fields'] as List?)
              ?.map((field) => UIField.fromJson(field))
              .toList() ?? [];
        }
        
        _formExplanation = analysisResponse['pdf_info']?['title'] ?? 'PDF Form';
        _isLoading = false;
        _isAnalyzing = false;
        _currentFieldIndex = 0;
        _formData = {};
      });

      // Show form explanation if available
      if (_formExplanation != null && _formExplanation!.isNotEmpty) {
        _showFormExplanation();
      }
      
      // Start field filling process
      if (_formFields.isNotEmpty) {
        _updateLivePreview();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isAnalyzing = false;
      });
      
      _showErrorDialog('خطأ في تحليل ملف PDF', e.toString());
    }
  }

  Future<void> _updateLivePreview() async {
    // Update annotated image
    final currentFile = _isPdfFile ? _selectedFile : _selectedImage;
    if (currentFile != null) {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        
        // Prepare signature data if available
        String? signatureImageB64;
        if (_signatureImage != null) {
          signatureImageB64 = base64Encode(_signatureImage!);
        }
        
        // Use the new annotateImage method with signature support
        final imageBytes = await currentFile.readAsBytes();
        final response = await appProvider.apiService.annotateImage(
          originalImageBytes: imageBytes,
          textsDict: _formData,
          uiFields: _formFields,
          signatureImageB64: signatureImageB64,
          signatureFieldId: _signatureFieldId,
        );
        
        setState(() => _annotatedImage = response);
      } catch (e) {
        // Handle error silently or show a toast
        // Show a non-blocking error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_languageDirection == 'rtl' 
                ? 'فشل في تحديث المعاينة المباشرة'
                : 'Failed to update live preview'
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleVoiceInput() async {
    try {
      setState(() => _isLoading = true);
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final audioFile = await appProvider.recordAudio();
      
      if (audioFile != null) {
        final transcript = await appProvider.apiService.speechToText(
          audioFile,
          _languageDirection == 'rtl' ? 'ar' : 'en'
        );

        setState(() {
          _isLoading = false;
        });

        if (_isSkipCommand(transcript)) {
          _moveToNextField();
        } else {
          _showConfirmationDialog(transcript);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showErrorDialog('خطأ في التسجيل الصوتي', e.toString());
    }
  }

  // Method to handle signature input
  Future<void> _handleSignatureInput() async {
    final currentField = _formFields[_currentFieldIndex];
    if (currentField.type == 'signature') {
      try {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final imageFile = await appProvider.pickImage();
        
        if (imageFile != null) {
          final imageBytes = await File(imageFile.path).readAsBytes();
          setState(() {
            _signatureImage = imageBytes;
            _signatureFieldId = currentField.boxId;
          });
          
          // Save signature and move to next field
          _formData[currentField.boxId] = 'signature_provided';
          _moveToNextField();
        }
      } catch (e) {
        _showErrorDialog('خطأ في إضافة التوقيع', e.toString());
      }
    }
  }

  bool _isSkipCommand(String text) {
    final skipCommands = ['تجاوز', 'تخطي', 'skip', 'next'];
    return skipCommands.any((cmd) => text.toLowerCase().contains(cmd.toLowerCase()));
  }

  void _showFormExplanation() {
    if (_formExplanation == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_languageDirection == 'rtl' ? 'شرح النموذج' : 'Form Explanation'),
        content: Text(_formExplanation!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startFormFilling();
            },
            child: Text(_languageDirection == 'rtl' ? 'متابعة' : 'Continue'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(String transcript) {
    if (!mounted) return;
    
    final field = _formFields[_currentFieldIndex];
    final displayText = field.type == 'checkbox'
        ? _getCheckboxDisplayValue(transcript)
        : transcript;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_languageDirection == 'rtl' ? 'تأكيد المدخلات' : 'Confirm Input'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_languageDirection == 'rtl' 
              ? 'سمعتك تقول: $displayText'
              : 'I heard you say: $displayText'
            ),
            const SizedBox(height: 16),
            Text(_languageDirection == 'rtl' 
              ? 'هل هذا صحيح؟'
              : 'Is this correct?'
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleVoiceInput(); // Try again
            },
            child: Text(_languageDirection == 'rtl' ? 'إعادة المحاولة' : 'Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveFieldValue(transcript);
            },
            child: Text(_languageDirection == 'rtl' ? 'تأكيد' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  String _getCheckboxDisplayValue(String transcript) {
    final positiveWords = ['نعم', 'أجل', 'حدد', 'صح', 'تمام', 'yes', 'check', 'ok', 'correct', 'right'];
    final isChecked = positiveWords.any((word) => transcript.toLowerCase().contains(word.toLowerCase()));
    return _languageDirection == 'rtl'
        ? (isChecked ? 'تحديد الخانة' : 'عدم تحديد الخانة')
        : (isChecked ? 'Checked' : 'Unchecked');
  }

  void _startFormFilling() {
    setState(() => _currentFieldIndex = 0);
    _speakCurrentFieldPrompt();
  }

  Future<void> _speakCurrentFieldPrompt() async {
    if (!_voiceAssistantEnabled || _formFields.isEmpty || _currentFieldIndex >= _formFields.length) return;

    final field = _formFields[_currentFieldIndex];
    String prompt;
    
    if (field.type == 'checkbox') {
      prompt = _getCheckboxPrompt(field.label);
    } else if (field.type == 'signature') {
      prompt = _getSignaturePrompt(field.label);
    } else {
      prompt = _getTextPrompt(field.label);
    }

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.apiService.textToSpeech(prompt);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('خطأ في المساعد الصوتي', e.toString());
    }
  }

  String _getCheckboxPrompt(String label) {
    return _languageDirection == 'rtl'
      ? "هل تريد تحديد خانة '$label'؟ قل نعم أو لا"
      : "Do you want to check the box for '$label'? Say yes or no";
  }

  String _getSignaturePrompt(String label) {
    return _languageDirection == 'rtl'
      ? "يرجى إضافة توقيعك في حقل '$label'"
      : "Please add your signature for '$label'";
  }

  String _getTextPrompt(String label) {
    return _languageDirection == 'rtl'
      ? "أدخل البيانات الخاصة بـ '$label'"
      : "Provide the information for '$label'";
  }

  void _moveToNextField() {
    if (_formFields.isEmpty) return;
    
    setState(() {
      if (_currentFieldIndex < _formFields.length - 1) {
        _currentFieldIndex++;
        _textController.clear(); // Clear text field for next input
        _speakCurrentFieldPrompt();
      } else {
        _showReviewDialog();
      }
    });
  }

  Future<void> _saveFieldValue(String value) async {
    if (_formFields.isEmpty || _currentFieldIndex >= _formFields.length) return;
    
    try {
      setState(() => _isLoading = true);
      
      final field = _formFields[_currentFieldIndex];
      if (field.type == 'checkbox') {
        final positiveWords = ['نعم', 'أجل', 'حدد', 'صح', 'تمام', 'yes', 'check', 'ok', 'correct', 'right'];
        final isChecked = positiveWords.any((word) => value.toLowerCase().contains(word.toLowerCase()));
        _formData[field.boxId] = isChecked.toString();
      } else {
        _formData[field.boxId] = value;
      }
      
      await _updateLivePreview();
      _moveToNextField();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('خطأ في حفظ البيانات', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_languageDirection == 'rtl' ? 'مراجعة النموذج' : 'Review Form'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_annotatedImage != null)
                Image.memory(_annotatedImage!),
              const SizedBox(height: 16),
              Text(
                _languageDirection == 'rtl'
                    ? 'يمكنك الآن تحميل النموذج كملف صورة (PNG) أو كملف (PDF)'
                    : 'You can now download the form as a PNG image or a PDF file'
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _downloadForm('PNG'),
            child: Text(_languageDirection == 'rtl' ? 'تنزيل كـ PNG' : 'Download as PNG'),
          ),
          TextButton(
            onPressed: () => _downloadForm('PDF'),
            child: Text(_languageDirection == 'rtl' ? 'تنزيل كـ PDF' : 'Download as PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadForm(String format) async {
    try {
      setState(() => _isLoading = true);
      
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Check if we have required data
      final currentFile = _isPdfFile ? _selectedFile : _selectedImage;
      if (currentFile == null) {
        _showErrorDialog('خطأ', 
          _languageDirection == 'rtl'
            ? 'لا يوجد ملف للتحميل'
            : 'No file to download'
        );
        return;
      }
      
      if (_formFields.isEmpty) {
        _showErrorDialog('خطأ', 
          _languageDirection == 'rtl'
            ? 'لا توجد حقول نموذج للحفظ'
            : 'No form fields to save'
        );
        return;
      }
      
      // Request storage permissions first
      final hasPermission = await appProvider.requestStoragePermissions();
      if (!hasPermission) {
        if (!mounted) return;
        _showErrorDialog('خطأ في الأذونات', 
          _languageDirection == 'rtl' 
            ? 'يجب السماح بالوصول للتخزين لحفظ الملف'
            : 'Storage permission is required to save the file'
        );
        return;
      }
      
      final filePath = await appProvider.apiService.downloadForm(
        currentFile,
        format.toLowerCase(),
        _formData,
        _formFields,
      );

      if (filePath.isNotEmpty) {
        if (!mounted) return;
        Navigator.pop(context); // Close review dialog
        _showSuccessDialog(filePath);
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString();
      
      // Handle specific error types
      if (errorMessage.contains('FormatException')) {
        errorMessage = _languageDirection == 'rtl'
          ? 'خطأ في تنسيق البيانات. يرجى المحاولة مرة أخرى.'
          : 'Data format error. Please try again.';
      } else if (errorMessage.contains('Invalid character')) {
        errorMessage = _languageDirection == 'rtl'
          ? 'خطأ في معالجة البيانات. يرجى التأكد من صحة البيانات المدخلة.'
          : 'Data processing error. Please check your input data.';
      } else if (errorMessage.contains('Connection')) {
        errorMessage = _languageDirection == 'rtl'
          ? 'خطأ في الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت.'
          : 'Connection error. Please check your internet connection.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = _languageDirection == 'rtl'
          ? 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.'
          : 'Connection timeout. Please try again.';
      }
      
      _showErrorDialog('خطأ في التحميل', errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog([String? filePath]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageDirection == 'rtl' ? 'تم بنجاح' : 'Success'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(_languageDirection == 'rtl' 
              ? 'تم حفظ النموذج بنجاح!'
              : 'Form saved successfully!'
            ),
            if (filePath != null) ...[
              const SizedBox(height: 8),
              Text(
                _languageDirection == 'rtl' 
                  ? 'موقع الملف:'
                  : 'File location:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                filePath,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: Text(_languageDirection == 'rtl' ? 'موافق' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedImage = null;
      _selectedFile = null;
      _annotatedImage = null;
      _signatureImage = null;
      _formFields = [];
      _formData = {};
      _currentFieldIndex = 0;
      _formExplanation = null;
      _sessionId = null;
      _signatureFieldId = null;
      _isPdfFile = false;
      _textController.clear();
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_languageDirection == 'rtl' ? 'موافق' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((_languageDirection ?? 'rtl') == 'rtl' ? 'محلل النماذج' : 'Form Analyzer'),
        actions: [
          Switch(
            value: _voiceAssistantEnabled,
            onChanged: (value) {
              setState(() => _voiceAssistantEnabled = value);
              Provider.of<AppProvider>(context, listen: false)
                  .setVoiceAssistantEnabled(value);
            },
          ),
          const SizedBox(width: 8),
          Text(
            (_languageDirection ?? 'rtl') == 'rtl' ? 'المساعد الصوتي' : 'Voice Assistant',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedImage == null && _selectedFile == null) ...[
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickAndAnalyzeImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text((_languageDirection ?? 'rtl') == 'rtl' 
                        ? 'اختر ملف النموذج'
                        : 'Choose Form File'
                      ),
                    ),
                  ),
                ] else ...[
                  if (_annotatedImage != null)
                    Image.memory(_annotatedImage!),
                  
                  if (_formFields.isNotEmpty && _currentFieldIndex < _formFields.length) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _formFields[_currentFieldIndex].label,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: _languageDirection == 'rtl' 
                                ? TextAlign.right 
                                : TextAlign.left,
                            ),
                            const SizedBox(height: 16),
                            
                            // Special handling for signature fields
                            if (_formFields[_currentFieldIndex].type == 'signature') ...[
                              // زر رفع صورة التوقيع
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleSignatureInput,
                                icon: const Icon(Icons.edit),
                                label: Text(_languageDirection == 'rtl'
                                  ? 'إضافة صورة التوقيع'
                                  : 'Add Signature Image'
                                ),
                              ),
                              const SizedBox(height: 12),
                              // عرض صورة التوقيع إذا تم رفعها
                              if (_signatureImage != null) ...[
                                Text(
                                  _languageDirection == 'rtl'
                                    ? 'تم رفع التوقيع بنجاح!'
                                    : 'Signature uploaded successfully!',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: _languageDirection == 'rtl' ? TextAlign.right : TextAlign.left,
                                ),
                                const SizedBox(height: 8),
                                Image.memory(_signatureImage!, width: 200, fit: BoxFit.contain),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _isLoading ? null : _handleSignatureInput,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(_languageDirection == 'rtl'
                                    ? 'تغيير التوقيع'
                                    : 'Change Signature'),
                                ),
                              ],
                            ] else ...[
                              if (_voiceAssistantEnabled)
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleVoiceInput,
                                  icon: Icon(_isLoading ? Icons.mic_off : Icons.mic),
                                  label: Text(_isLoading
                                    ? (_languageDirection == 'rtl' ? 'جاري التسجيل...' : 'Recording...')
                                    : (_languageDirection == 'rtl' ? 'اضغط للتحدث' : 'Click to Speak')
                                  ),
                                ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _textController,
                                decoration: InputDecoration(
                                  labelText: _languageDirection == 'rtl'
                                    ? 'أو، أدخل إجابتك هنا'
                                    : 'Or, type your answer here',
                                ),
                                textAlign: _languageDirection == 'rtl' 
                                  ? TextAlign.right 
                                  : TextAlign.left,
                                onFieldSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _saveFieldValue(value);
                                  }
                                },
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: _moveToNextField,
                                  child: Text(_languageDirection == 'rtl'
                                    ? 'تخطي'
                                    : 'Skip'
                                  ),
                                ),
                                if (_formFields[_currentFieldIndex].type != 'signature')
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_textController.text.isNotEmpty) {
                                        _saveFieldValue(_textController.text);
                                      }
                                    },
                                    child: Text(_languageDirection == 'rtl'
                                      ? 'حفظ والمتابعة'
                                      : 'Save & Continue'
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      (_languageDirection ?? 'rtl') == 'rtl'
                        ? 'جاري تحليل النموذج...'
                        : 'Analyzing form...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
