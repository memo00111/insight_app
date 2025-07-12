import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/form_analysis_response.dart';
import '../utils/signature_field_detector.dart';
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
  
  // Map to store signatures for multiple pages
  final Map<int, Map<String, Uint8List>> _pageSignatures = {}; // {pageNumber: {fieldId: signatureImage}}

  // متغيرات لدعم ملفات PDF متعددة الصفحات
  bool _isPdfMultiPage = false;
  int _currentPdfPage = 1;
  int _totalPdfPages = 1;
  List<int> _pdfPagesWithFields = [];
  Map<int, List<UIField>> _pdfPageFields = {};
  Map<int, Map<String, dynamic>> _pdfPageData = {};
  String? _pdfSessionId;

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
    // تفعيل المساعد الصوتي افتراضياً للنماذج
    if (!appProvider.isVoiceAssistantEnabled) {
      appProvider.setVoiceAssistantEnabled(true);
      debugPrint('🎤 تم تفعيل المساعد الصوتي افتراضياً');
    }
    setState(() {
      _voiceAssistantEnabled = appProvider.isVoiceAssistantEnabled;
    });
    debugPrint('🎤 حالة المساعد الصوتي: ${_voiceAssistantEnabled ? "مفعل" : "معطل"}');
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

  /// تحليل النموذج - مطابق تماماً لتدفق Python
  Future<void> _analyzeForm() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _isAnalyzing = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // Step 1: فحص جودة الصورة أولاً (مطابق للـ Python)
      debugPrint('📤 فحص جودة الصورة...');
      final qualityResponse = await appProvider.apiService.checkFormImageQuality(_selectedImage!);
      
      if (!qualityResponse['quality_good']) {
        setState(() {
          _isLoading = false;
          _isAnalyzing = false;
        });
        _showErrorDialog('جودة الصورة', qualityResponse['quality_message'] ?? 'جودة الصورة منخفضة');
        return;
      }
      
      final sessionId = qualityResponse['session_id'];
      final recommendedLanguage = qualityResponse['recommended_language'];
      
      // Step 2: تحليل النموذج باستخدام session_id (مطابق للـ Python)
      debugPrint('📝 تحليل النموذج...');
      final analysisResult = await appProvider.apiService.analyzeFormData(
        _selectedImage!,
        sessionId,
        languageDirection: recommendedLanguage,
      );

      // Step 3: استقبال البيانات من الخادم (مطابق للـ Python)
      setState(() {
        _formFields = analysisResult.fields;
        _formExplanation = analysisResult.formExplanation;
        _languageDirection = analysisResult.languageDirection;
        _sessionId = sessionId; // للاستخدام في التحديثات اللاحقة
        _isLoading = false;
        _isAnalyzing = false;
        _currentFieldIndex = 0;
        _formData = {};
      });

      // Step 4: تحديث المعاينة المباشرة للصورة (مطابق للـ Python)
      await _updateLivePreview();

      debugPrint('✅ تم تحليل النموذج بنجاح: ${_formFields.length} حقل');

      // Step 3: معالجة الحقول وكشف التوقيع
      _processFieldsWithSignatureDetection();

      // Step 4: عرض شرح النموذج (مطابق للـ Python conversation stage)
      if (_formExplanation != null && _formExplanation!.isNotEmpty) {
        _showFormExplanation();
      } else {
        // البدء مباشرة في تعبئة الحقول إذا لم يكن هناك شرح
        _startFormFilling();
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _isAnalyzing = false;
      });

      debugPrint('❌ خطأ في تحليل النموذج: $e');
      
      // معالجة أخطاء مفصلة مطابقة للـ Python
      String errorMessage = e.toString();
      if (errorMessage.contains('500')) {
        errorMessage = _languageDirection == 'rtl'
            ? 'خطأ في الخادم. يرجى المحاولة مرة أخرى.'
            : 'Server error. Please try again.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = _languageDirection == 'rtl'
            ? 'انتهت مهلة الاتصال. يرجى التحقق من الاتصال بالإنترنت.'
            : 'Connection timeout. Please check your internet connection.';
      } else if (errorMessage.contains('Connection')) {
        errorMessage = _languageDirection == 'rtl'
            ? 'لا يمكن الاتصال بالخادم. يرجى التحقق من الاتصال بالإنترنت.'
            : 'Could not connect to the analysis backend.';
      }

      _showErrorDialog(
        _languageDirection == 'rtl' ? 'خطأ في تحليل النموذج' : 'Form Analysis Error', 
        errorMessage
      );
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
      
      // 1. First check PDF quality and get session
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
      
      // 2. Explore PDF first - new step according to the API workflow
      await appProvider.apiService.explorePdf(_selectedFile!);
      debugPrint('📄 تم استكشاف ملف PDF بنجاح');
      
      // 3. Analyze PDF form structure 
      final analysisResponse = await appProvider.apiService.analyzePdfForm(
        sessionId: sessionId,
        languageDirection: recommendedLanguage,
      );
      
      // تحقق مما إذا كان PDF متعدد الصفحات
      final List<dynamic>? pages = analysisResponse['pages'];
      final bool isMultiPage = pages != null && pages.length > 1;
      
      setState(() {
        _sessionId = sessionId;
        _pdfSessionId = sessionId; // حفظ معرف الجلسة للاستخدام في تعبئة PDF
        _languageDirection = recommendedLanguage;
        
        // تحديث معلومات PDF متعدد الصفحات
        _isPdfMultiPage = isMultiPage;
        _totalPdfPages = pages?.length ?? 1;
        _currentPdfPage = 1;
        
        if (isMultiPage) {
          // معالجة كل الصفحات وتحديد الصفحات التي تحتوي على حقول
          _pdfPagesWithFields = [];
          _pdfPageFields = {};
          
          for (int i = 0; i < pages.length; i++) {
            final pageNum = i + 1; // الترقيم يبدأ من 1
            final page = pages[i];
            final hasFields = page['has_fields'] == true;
            final List<dynamic>? fields = page['fields'];
            
            if (hasFields && fields != null && fields.isNotEmpty) {
              _pdfPagesWithFields.add(pageNum);
              _pdfPageFields[pageNum] = fields.map((field) => UIField.fromJson(field)).toList();
            }
          }
          
          // تطبيق كشف حقول التوقيع على جميع صفحات PDF
          _processPdfFieldsWithSignatureDetection(_pdfPageFields);
          
          // ابدأ بأول صفحة تحتوي على حقول
          if (_pdfPagesWithFields.isNotEmpty) {
            _currentPdfPage = _pdfPagesWithFields.first;
            _formFields = _pdfPageFields[_currentPdfPage] ?? [];
          } else {
            _formFields = [];
          }
        } else {
          // للملفات ذات الصفحة الواحدة، استخدم الطريقة القديمة
          final firstPageWithFields = pages?.firstWhere(
            (page) => page['has_fields'] == true,
            orElse: () => pages.first,
          );
          
          if (firstPageWithFields != null) {
            _formFields = (firstPageWithFields['fields'] as List?)
                ?.map((field) => UIField.fromJson(field))
                .toList() ?? [];
          }
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
        setState(() => _isLoading = true); // إضافة حالة التحميل أثناء تحديث المعاينة
        
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        
        // Prepare signature data if available
        String? signatureImageB64;
        if (_signatureImage != null) {
          signatureImageB64 = base64Encode(_signatureImage!);
          debugPrint('📝 تم تحويل صورة التوقيع إلى base64 (${signatureImageB64.length} حرف)');
        }
        
        // طباعة معلومات تشخيصية للتوقيع
        if (_signatureFieldId != null) {
          debugPrint('🖊️ معرف حقل التوقيع: $_signatureFieldId');
          
          // البحث عن الحقل في قائمة الحقول للتأكد من وجوده
          final signatureField = _formFields.firstWhere(
            (field) => field.boxId == _signatureFieldId,
            orElse: () => UIField(boxId: 'not-found', label: 'Not Found', type: 'unknown'),
          );
          
          if (signatureField.boxId != 'not-found') {
            debugPrint('✅ تم العثور على حقل التوقيع: ${signatureField.label}');
          } else {
            debugPrint('⚠️ لم يتم العثور على حقل التوقيع برقم المعرف: $_signatureFieldId');
          }
        }
        
        // Use the new annotateImage method with signature support
        final imageBytes = await currentFile.readAsBytes();
        final response = await appProvider.apiService.annotateImage(
          originalImageBytes: imageBytes,
          textsDict: _formData,
          uiFields: _formFields,
          signatureImageB64: signatureImageB64,
          signatureFieldId: _signatureFieldId,
          languageDirection: _languageDirection,
        );
        
        if (mounted) {
          setState(() {
            _annotatedImage = response;
            _isLoading = false;
          });
          
          // إظهار رسالة تأكيد عندما يتم تحديث المعاينة بنجاح مع وجود توقيع
          if (_signatureImage != null && _signatureFieldId != null) {
            // تأخير بسيط لضمان ظهور المعاينة أولاً
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Text(
                          _languageDirection == 'rtl' 
                            ? 'تم تحديث المعاينة بنجاح مع التوقيع'
                            : 'Preview updated successfully with signature'
                        ),
                      ],
                    ),
                    backgroundColor: Colors.black87,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            });
          }
        }
      } catch (e) {
        // Handle error and provide more detailed logging
        debugPrint('❌ خطأ في تحديث المعاينة المباشرة: $e');
        
        // Show a non-blocking error message
        if (mounted) {
          setState(() => _isLoading = false);
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
      // إظهار مربع حوار تفاعلي للتسجيل
      await _showInteractiveRecordingDialog();
      
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showErrorDialog('خطأ في التسجيل الصوتي', e.toString());
    }
  }

  Future<void> _showInteractiveRecordingDialog() async {
    bool isRecording = false;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F37),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Text(
                _languageDirection == 'rtl' 
                  ? (isRecording ? 'جاري التسجيل...' : 'اضغط للتحدث') 
                  : (isRecording ? 'Recording...' : 'Press to Speak'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTapDown: (_) async {
                  if (!isRecording) {
                    setDialogState(() => isRecording = true);
                    try {
                      final appProvider = Provider.of<AppProvider>(context, listen: false);
                      await appProvider.recordAudio(); // فقط بدء التسجيل
                    } catch (e) {
                      setDialogState(() => isRecording = false);
                      debugPrint('خطأ في بدء التسجيل: $e');
                    }
                  }
                },
                onTapUp: (_) async {
                  if (isRecording) {
                    setDialogState(() => isRecording = false);
                    try {
                      final appProvider = Provider.of<AppProvider>(context, listen: false);
                      final finalFile = await appProvider.stopRecording();
                      
                      Navigator.pop(context); // إغلاق مربع الحوار
                      
                      if (finalFile != null) {
                        await _processAudioFile(finalFile);
                      }
                    } catch (e) {
                      debugPrint('خطأ في إيقاف التسجيل: $e');
                      Navigator.pop(context);
                      _showErrorDialog('خطأ في التسجيل', e.toString());
                    }
                  }
                },
                onTapCancel: () async {
                  if (isRecording) {
                    setDialogState(() => isRecording = false);
                    try {
                      final appProvider = Provider.of<AppProvider>(context, listen: false);
                      await appProvider.stopRecording(); // إيقاف التسجيل
                    } catch (e) {
                      debugPrint('خطأ في إلغاء التسجيل: $e');
                    }
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: (isRecording ? Colors.red : Colors.green).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRecording ? Colors.red : Colors.green, 
                      width: 3
                    ),
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 50,
                    color: isRecording ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _languageDirection == 'rtl' 
                  ? (isRecording ? 'اترك الزر لإيقاف التسجيل' : 'اضغط واستمر في الضغط للتحدث')
                  : (isRecording ? 'Release to stop recording' : 'Press and hold to speak'),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _languageDirection == 'rtl' ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processAudioFile(File audioFile) async {
    try {
      setState(() => _isLoading = true);
      
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // استخدام API الخاص بالفورم كما في Python (/form/speech-to-text)
      final audioBytes = await audioFile.readAsBytes();
      
      debugPrint('🎤 حجم الملف الصوتي: ${audioBytes.length} بايت');
      debugPrint('🎤 مسار الملف: ${audioFile.path}');
      
      final transcript = await appProvider.convertFormSpeechToText(
        audioBytes,
        _languageDirection == 'rtl' ? 'ar' : 'en'
      );

      setState(() => _isLoading = false);

      if (transcript.isNotEmpty) {
        // فحص أوامر التخطي كما في Python
        final skipWords = ['تجاوز', 'تخطي', 'skip', 'next'];
        final isSkipCommand = skipWords.any((word) => 
          transcript.toLowerCase().contains(word.toLowerCase()));
        
        if (isSkipCommand) {
          _moveToNextField();
        } else {
          _showConfirmationDialog(transcript);
        }
      } else {
        _showErrorDialog(
          'خطأ في التعرف على الصوت', 
          'لم أتمكن من فهم الصوت. من فضلك حاول مرة أخرى'
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ خطأ في معالجة الملف الصوتي: $e');
      _showErrorDialog('خطأ في التسجيل الصوتي', e.toString());
    }
  }

  // Method to handle signature input
  Future<void> _handleSignatureInput() async {
    final currentField = _formFields[_currentFieldIndex];
    if (currentField.type == 'signature') {
      try {
        setState(() => _isLoading = true);
        
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        final imageFile = await appProvider.pickImage();
        
        if (imageFile != null && mounted) {
          final imageBytes = await File(imageFile.path).readAsBytes();
          
          // تعيين صورة التوقيع ومعرف حقل التوقيع
          setState(() {
            _signatureImage = imageBytes;
            _signatureFieldId = currentField.boxId;
            
            // إضافة قيمة فارغة في formData لضمان تحديث الحقل
            _formData[currentField.boxId] = "signature_added";
            
            // تخزين التوقيع للصفحة الحالية
            if (_isPdfMultiPage) {
              // إنشاء قاموس للصفحة إذا لم يكن موجودًا
              if (!_pageSignatures.containsKey(_currentPdfPage)) {
                _pageSignatures[_currentPdfPage] = {};
              }
              // تخزين صورة التوقيع للصفحة والحقل
              _pageSignatures[_currentPdfPage]![currentField.boxId] = imageBytes;
              
              debugPrint('💾 تم تخزين التوقيع للصفحة $_currentPdfPage، حقل ${currentField.boxId}');
            }
          });
          
          // تحديث المعاينة المباشرة لعرض التوقيع
          await _updateLivePreview();
          
          // عرض معاينة لصورة التوقيع المضافة
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent),
                    const SizedBox(width: 10),
                    Text(
                      _languageDirection == 'rtl' 
                        ? 'تم إضافة التوقيع بنجاح' 
                        : 'Signature added successfully'
                    ),
                  ],
                ),
                backgroundColor: Colors.black87,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          _moveToNextField();
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          _showErrorDialog('خطأ في إضافة التوقيع', e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // عرض شرح للنموذج مع دعم شرح متتابع للصفحات
  void _showFormExplanation() {
    if (_formExplanation == null) return;
    
    // للصفحات المتعددة، نعرض شرح الصفحة الأولى ثم نتيح الانتقال للصفحات الأخرى
    if (_isPdfMultiPage && _pdfPagesWithFields.isNotEmpty) {
      _showPageExplanation(_pdfPagesWithFields.first, isFirstPage: true);
    } else {
      // للملفات ذات الصفحة الواحدة، نستخدم الشرح الكامل
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
  }
  
  // عرض شرح لصفحة معينة من النموذج
  void _showPageExplanation(int pageNumber, {bool isFirstPage = false}) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // نستخدم API للحصول على شرح الصفحة المحددة
    appProvider.apiService.explainPdfPage(
      sessionId: _pdfSessionId!,
      pageNumber: pageNumber,
      languageDirection: _languageDirection!,
    ).then((explainResponse) {
      if (mounted) {
        final pageExplanation = explainResponse['page_explanation'] ?? 
                               (_languageDirection == 'rtl' ? 'شرح الصفحة غير متاح' : 'Page explanation not available');
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(_languageDirection == 'rtl' 
                ? 'شرح الصفحة ${pageNumber} من ${_totalPdfPages}' 
                : 'Page ${pageNumber} of ${_totalPdfPages} Explanation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pageExplanation),
                const SizedBox(height: 8),
                if (_pdfPagesWithFields.length > 1)
                  Text(
                    _languageDirection == 'rtl'
                      ? 'عدد الصفحات التي تحتاج لتعبئة: ${_pdfPagesWithFields.length}'
                      : 'Number of pages requiring filling: ${_pdfPagesWithFields.length}',
                    style: TextStyle(
                      color: Colors.purple[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            actions: [
              if (!isFirstPage && _pdfPagesWithFields.indexOf(pageNumber) > 0)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final prevPageIndex = _pdfPagesWithFields.indexOf(pageNumber) - 1;
                    if (prevPageIndex >= 0) {
                      _showPageExplanation(_pdfPagesWithFields[prevPageIndex]);
                    }
                  },
                  child: Text(_languageDirection == 'rtl' ? 'السابق' : 'Previous'),
                ),
              if (_pdfPagesWithFields.indexOf(pageNumber) < _pdfPagesWithFields.length - 1)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final nextPageIndex = _pdfPagesWithFields.indexOf(pageNumber) + 1;
                    if (nextPageIndex < _pdfPagesWithFields.length) {
                      _showPageExplanation(_pdfPagesWithFields[nextPageIndex]);
                    }
                  },
                  child: Text(_languageDirection == 'rtl' ? 'التالي' : 'Next'),
                )
              else
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startFormFilling();
                  },
                  child: Text(_languageDirection == 'rtl' ? 'بدء التحليل' : 'Start Analysis'),
                ),
            ],
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(_languageDirection == 'rtl' ? 'خطأ في الشرح' : 'Explanation Error'),
            content: Text(error.toString()),
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
    });
  }

  // عرض مربع حوار الاستماع للصوت (مطابق لـ Python)
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
      // استخدام API الخاص بالفورم كما في Python (/form/text-to-speech)
      final audioBytes = await appProvider.convertFormTextToSpeech(prompt);
      
      // تشغيل الصوت مباشرة
      await appProvider.playAudioBytes(audioBytes);
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
        // الانتقال للحقل التالي في الصفحة الحالية
        _currentFieldIndex++;
        _textController.clear(); // مسح النص للإدخال التالي
        
        // التحقق مما إذا كان الحقل التالي هو حقل توقيع وإظهار مربع حوار لاختيار صورة التوقيع
        final nextField = _formFields[_currentFieldIndex];
        if (nextField.type == 'signature') {
          Future.delayed(const Duration(milliseconds: 300), () {
            _showSignatureInputDialog(nextField);
          });
        } else {
          _speakCurrentFieldPrompt();
        }
      } else {
        // وصلنا لنهاية الحقول في الصفحة الحالية
        
        // حفظ بيانات الصفحة الحالية
        if (_isPdfMultiPage) {
          _pdfPageData[_currentPdfPage] = Map<String, dynamic>.from(_formData);
          
          // التحقق مما إذا كانت هناك صفحة أخرى تحتوي على حقول لم تتم تعبئتها بعد
          int nextPageWithFields = _getNextPageWithFields();
          
          if (nextPageWithFields > 0) {
            // عرض رسالة انتقال للصفحة التالية
            _showNextPageDialog(nextPageWithFields);
          } else {
            // لا توجد صفحات أخرى للتعبئة، عرض ملخص النموذج
            _showReviewDialog();
          }
        } else {
          // لملفات الصفحة الواحدة، عرض المراجعة مباشرة
          _showReviewDialog();
        }
      }
    });
  }
  
  // إضافة مربع حوار مخصص لإدخال التوقيع
  // إضافة مربع حوار مخصص لإدخال التوقيع مع تحسينات لواجهة المستخدم
  void _showSignatureInputDialog(UIField field) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_languageDirection == 'rtl' ? 'إضافة توقيع' : 'Add Signature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة توضيحية للتوقيع
            Icon(
              Icons.draw,
              size: 40,
              color: Colors.purpleAccent[100],
            ),
            const SizedBox(height: 16),
            Text(
              _languageDirection == 'rtl'
                ? 'تم اكتشاف حقل توقيع: "${field.label}"'
                : 'Signature field detected: "${field.label}"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _languageDirection == 'rtl'
                ? 'يرجى إضافة صورة التوقيع الخاص بك لهذا الحقل'
                : 'Please add your signature image for this field',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            // إضافة زر كبير مع أيقونة لرفع صورة التوقيع
            InkWell(
              onTap: () {
                Navigator.pop(context);
                _handleSignatureInput();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purpleAccent),
                  color: Colors.purpleAccent.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _languageDirection == 'rtl' ? 'اختيار صورة' : 'Choose Image',
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // تخطي حقل التوقيع
              _moveToNextField(); 
            },
            child: Text(_languageDirection == 'rtl' ? 'تخطي هذا الحقل' : 'Skip this field'),
          ),
        ],
      ),
    );
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
      
      // For PDF pages, save the data to the current page data map
      if (_isPdfMultiPage && _isPdfFile) {
        _pdfPageData[_currentPdfPage] = Map<String, dynamic>.from(_formData);
        
        // Optional: Submit the field data for the current page immediately
        // This ensures the backend has the latest data for each field as it's filled
        if (_pdfSessionId != null) {
          final appProvider = Provider.of<AppProvider>(context, listen: false);
          try {
            await appProvider.apiService.fillPdfPage(
              sessionId: _pdfSessionId!,
              pageNumber: _currentPdfPage,
              textsDict: _formData,
              signatureImageB64: _signatureImage != null ? base64Encode(_signatureImage!) : null,
              signatureFieldId: _signatureFieldId,
            );
            debugPrint('✅ تم حفظ بيانات الحقل للصفحة $_currentPdfPage في الخادم');
          } catch (e) {
            debugPrint('⚠️ لم يتم حفظ البيانات على الخادم: $e');
            // Continue even if this fails - we'll retry during download
          }
        }
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
    // Count how many pages have been filled with data
    int filledPagesCount = _isPdfMultiPage ? _pdfPageData.keys.length : 1;
    int totalFieldsCount = 0;
    int filledFieldsCount = 0;
    
    // Calculate total fields and filled fields for PDF
    if (_isPdfMultiPage) {
      for (var pageNum in _pdfPagesWithFields) {
        if (_pdfPageFields.containsKey(pageNum)) {
          totalFieldsCount += _pdfPageFields[pageNum]!.length;
          
          if (_pdfPageData.containsKey(pageNum)) {
            filledFieldsCount += _pdfPageData[pageNum]!.length;
          }
        }
      }
    } else {
      totalFieldsCount = _formFields.length;
      filledFieldsCount = _formData.keys.length;
    }
    
    // Calculate completion percentage
    double completionPercentage = totalFieldsCount > 0 
        ? (filledFieldsCount / totalFieldsCount * 100)
        : 100.0;
    
    // Find missing pages (pages with fields but no data)
    List<int> missingPages = [];
    if (_isPdfMultiPage) {
      for (var pageNum in _pdfPagesWithFields) {
        if (!_pdfPageData.containsKey(pageNum) || _pdfPageData[pageNum]!.isEmpty) {
          missingPages.add(pageNum);
        }
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_languageDirection == 'rtl' ? 'مراجعة النموذج' : 'Review Form'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _languageDirection == 'rtl'
                  ? 'تم الانتهاء من تعبئة النموذج بنجاح!'
                  : 'Form has been filled successfully!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // معلومات إضافية حول PDF متعدد الصفحات
              if (_isPdfMultiPage)
                Column(
                  children: [
                    Text(
                      _languageDirection == 'rtl'
                        ? 'تم تعبئة $filledPagesCount صفحة من أصل $_totalPdfPages'
                        : 'Filled $filledPagesCount pages out of $_totalPdfPages',
                      style: TextStyle(
                        color: completionPercentage > 90 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _languageDirection == 'rtl'
                        ? 'تم تعبئة $filledFieldsCount من أصل $totalFieldsCount حقول (${completionPercentage.toStringAsFixed(1)}%)'
                        : 'Filled $filledFieldsCount out of $totalFieldsCount fields (${completionPercentage.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        color: Colors.grey[200],
                      ),
                    ),
                    
                    // Show warning if some pages are missing data
                    if (missingPages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _languageDirection == 'rtl' 
                                    ? 'تنبيه: بعض الصفحات غير مكتملة'
                                    : 'Warning: Some pages are incomplete',
                                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _languageDirection == 'rtl'
                                ? 'الصفحات غير المكتملة: ${missingPages.join(', ')}'
                                : 'Incomplete pages: ${missingPages.join(', ')}',
                              style: TextStyle(color: Colors.orange[100], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              
              Text(
                _languageDirection == 'rtl'
                  ? 'اختر تنسيق التنزيل:'
                  : 'Choose download format:',
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_languageDirection == 'rtl' ? 'إلغاء' : 'Cancel'),
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
            ? 'لا يوجد ملف لتحميله. يرجى اختيار ملف أولاً.'
            : 'No file to download. Please select a file first.');
        return;
      }
      
      if (_formFields.isEmpty) {
        _showErrorDialog('خطأ', 
          _languageDirection == 'rtl'
            ? 'لا توجد حقول لملء النموذج.'
            : 'No fields found to fill the form.');
        return;
      }
      
      // Request storage permissions first
      final hasPermission = await appProvider.requestStoragePermissions();
      if (!hasPermission) {
        if (!mounted) return;
        _showErrorDialog('خطأ في الأذونات', 
          _languageDirection == 'rtl'
            ? 'لم يتم منح إذن الوصول للتخزين. لا يمكن حفظ النموذج.'
            : 'Storage permission denied. Cannot save the form.');
        return;
      }
      
      // تحويل صورة التوقيع إلى base64 إذا كانت موجودة
      String? signatureImageB64;
      if (_signatureImage != null) {
        signatureImageB64 = base64Encode(_signatureImage!);
      }
      
      String filePath;
      
      // استخدم الطريقة الجديدة للتعامل مع ملفات PDF متعددة الصفحات
      if (_isPdfFile && format.toLowerCase() == 'pdf' && _isPdfMultiPage && _pdfSessionId != null) {
        // حفظ بيانات الصفحة الحالية أولاً
        _pdfPageData[_currentPdfPage] = Map<String, dynamic>.from(_formData);
        
        // جمع البيانات من جميع الصفحات التي تم تعبئتها
        List<int> filledPageNumbers = [];
        List<Map<String, dynamic>> pageDataList = [];
        List<UIField> allFields = [];
        
        // تحقق من الصفحات المتعددة وبياناتها
        if (_pdfPageData.isNotEmpty) {
          // حفظ البيانات الحالية أولاً للصفحة التي يشاهدها المستخدم
          _pdfPageData[_currentPdfPage] = Map<String, dynamic>.from(_formData);
          
          // جمع كل صفحات البيانات
          for (int pageNum in _pdfPagesWithFields) {
            if (_pdfPageData.containsKey(pageNum) && _pdfPageFields.containsKey(pageNum)) {
              filledPageNumbers.add(pageNum);
              pageDataList.add(_pdfPageData[pageNum]!);
              allFields.addAll(_pdfPageFields[pageNum]!);
            }
          }
          
          // استخدام الطريقة الجديدة لمعالجة PDF متعدد الصفحات
          filePath = await appProvider.apiService.processPdfDownload(
            _pdfSessionId!,
            filledPageNumbers, 
            pageDataList,
            allFields,
            signatureImageB64: signatureImageB64,
            signatureFieldId: _signatureFieldId
          );
        } else {
          _showErrorDialog('خطأ في البيانات', 
            _languageDirection == 'rtl'
              ? 'لم يتم العثور على بيانات مدخلة لأي صفحة.'
              : 'No input data found for any page.');
          setState(() => _isLoading = false);
          return;
        }
      } else {
        // استخدم الطريقة العادية للصور أو ملفات PDF ذات الصفحة الواحدة
        filePath = await appProvider.apiService.downloadForm(
          _isPdfFile ? _selectedFile! : _selectedImage!,
          format.toLowerCase(),
          _formData,
          _formFields,
          signatureImageB64: signatureImageB64,
          signatureFieldId: _signatureFieldId
        );
      }

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
          ? 'خطأ في معالجة البيانات. يرجى التحقق من البيانات المدخلة.'
          : 'Data processing error. Please check your input data.';
      } else if (errorMessage.contains('Connection')) {
        errorMessage = _languageDirection == 'rtl'
          ? 'خطأ في الاتصال. يرجى التحقق من اتصال الإنترنت.'
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

  // الحصول على رقم الصفحة السابقة
  int _getPreviousPdfPage() {
    final currentIndex = _pdfPagesWithFields.indexOf(_currentPdfPage);
    if (currentIndex > 0) {
      return _pdfPagesWithFields[currentIndex - 1];
    }
    return _currentPdfPage;
  }

  // الحصول على رقم الصفحة التالية
  int _getNextPdfPage() {
    final currentIndex = _pdfPagesWithFields.indexOf(_currentPdfPage);
    if (currentIndex < _pdfPagesWithFields.length - 1) {
      return _pdfPagesWithFields[currentIndex + 1];
    }
    return _currentPdfPage;
  }

  // الانتقال إلى صفحة معينة من PDF
  Future<void> _navigateToPdfPage(int pageNumber) async {
    // حفظ البيانات المدخلة للصفحة الحالية
    if (_isPdfMultiPage) {
      _pdfPageData[_currentPdfPage] = Map<String, dynamic>.from(_formData);
      
      // طباعة تأكيد لتسجيل الحدث
      debugPrint('📝 تم حفظ بيانات الصفحة $_currentPdfPage: ${_formData.length} حقول');
    }
    
    setState(() {
      _isLoading = true; // بدء تحميل الصفحة الجديدة
    });
    
    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      
      // تحديث رقم الصفحة الحالية
      _currentPdfPage = pageNumber;
      
      // 1. طلب شرح للصفحة الجديدة - خطوة جديدة وفقا لترتيب API
      if (_pdfSessionId != null && _languageDirection != null) {
        final explainResponse = await appProvider.apiService.explainPdfPage(
          sessionId: _pdfSessionId!,
          pageNumber: pageNumber,
          languageDirection: _languageDirection!,
        );
        
        // يمكن تحديث الشرح إذا كان متاحًا
        if (explainResponse.containsKey('explanation')) {
          _formExplanation = explainResponse['explanation'] as String?;
        }
      }
      
      // 2. تحليل الصفحة الحالية - خطوة جديدة وفقا لترتيب API
      if (_pdfSessionId != null && _languageDirection != null) {
        final pageAnalysisResponse = await appProvider.apiService.analyzePdfPage(
          sessionId: _pdfSessionId!,
          pageNumber: pageNumber,
          languageDirection: _languageDirection!,
        );
        
        // تحديث حقول الصفحة من التحليل الجديد
        if (pageAnalysisResponse.containsKey('fields')) {
          final List<dynamic> fields = pageAnalysisResponse['fields'] as List<dynamic>;
          _formFields = fields.map((field) => UIField.fromJson(field)).toList();
          _pdfPageFields[pageNumber] = List<UIField>.from(_formFields);
          debugPrint('📄 تم تحليل وتحميل ${_formFields.length} حقل من الصفحة $pageNumber');
        } else {
          // استخدم الحقول المخزنة مسبقًا إذا كانت متاحة
          if (_pdfPageFields.containsKey(pageNumber)) {
            _formFields = _pdfPageFields[pageNumber]!;
            debugPrint('📄 تم تحميل ${_formFields.length} حقل مخزن من الصفحة $pageNumber');
          } else {
            _formFields = [];
            debugPrint('⚠️ لا توجد حقول في الصفحة $pageNumber');
          }
        }
      } else {
        // الطريقة القديمة للتوافق الخلفي
        if (_pdfPageFields.containsKey(pageNumber)) {
          _formFields = _pdfPageFields[pageNumber]!;
          debugPrint('📄 تم تحميل ${_formFields.length} حقل من الصفحة $pageNumber');
        } else {
          _formFields = [];
          debugPrint('⚠️ لا توجد حقول في الصفحة $pageNumber');
        }
      }
      
      // استعادة البيانات المدخلة سابقاً للصفحة إذا وجدت
      if (_pdfPageData.containsKey(pageNumber)) {
        _formData = Map<String, dynamic>.from(_pdfPageData[pageNumber]!);
        debugPrint('🔄 تم استعادة ${_formData.length} قيمة مخزنة للصفحة $pageNumber');
      } else {
        _formData = {};
      }
      
      // استعادة التوقيع للصفحة الحالية إذا وجد
      _signatureImage = null;
      _signatureFieldId = null;
      if (_pageSignatures.containsKey(pageNumber)) {
        final pageSignatures = _pageSignatures[pageNumber]!;
        if (pageSignatures.isNotEmpty) {
          // البحث عن حقول التوقيع في الصفحة الحالية
          final signatureField = _formFields.firstWhere(
            (field) => field.type == 'signature' && pageSignatures.containsKey(field.boxId),
            orElse: () => UIField(boxId: '', label: '', type: ''),
          );
          
          if (signatureField.boxId.isNotEmpty) {
            _signatureImage = pageSignatures[signatureField.boxId];
            _signatureFieldId = signatureField.boxId;
            debugPrint('🔄 تم استعادة التوقيع للصفحة $pageNumber، حقل ${signatureField.boxId}');
          }
        }
      }
      
      // إعادة ضبط مؤشر الحقل الحالي
      _currentFieldIndex = 0;
      
      // تحديث المعاينة المباشرة للصفحة الجديدة
      await _updateLivePreview();
      
    } catch (e) {
      debugPrint('❌ خطأ في الانتقال للصفحة $pageNumber: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // تحديد الصفحة التالية التي تحتوي على حقول لتعبئتها
  int _getNextPageWithFields() {
    if (!_isPdfMultiPage || _pdfPagesWithFields.isEmpty) return -1;
    
    // البحث عن الصفحة التالية في قائمة الصفحات التي تحتوي على حقول
    int currentPageIndex = _pdfPagesWithFields.indexOf(_currentPdfPage);
    if (currentPageIndex >= 0 && currentPageIndex < _pdfPagesWithFields.length - 1) {
      return _pdfPagesWithFields[currentPageIndex + 1];
    }
    
    return -1;
  }

  // عرض مربع حوار للانتقال إلى الصفحة التالية في النموذج
  void _showNextPageDialog(int nextPage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_languageDirection == 'rtl' 
          ? 'الانتقال للصفحة التالية' 
          : 'Moving to Next Page'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _languageDirection == 'rtl'
                ? 'تم الانتهاء من تعبئة حقول الصفحة الحالية بنجاح!'
                : 'Current page fields completed successfully!',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _languageDirection == 'rtl'
                ? 'الانتقال للصفحة $nextPage من $_totalPdfPages'
                : 'Moving to page $nextPage of $_totalPdfPages',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPdfPage(nextPage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(_languageDirection == 'rtl' ? 'الانتقال للصفحة التالية' : 'Go to Next Page'),
          ),
        ],
      ),
    );
  }

  // إنشاء widget لعرض حقل الإدخال بناءً على نوع الحقل
  Widget _buildInputField() {
    final field = _formFields[_currentFieldIndex];
    
    if (field.type == 'signature') {
      return _buildSignatureField(field);
    } else if (field.type == 'checkbox') {
      return _buildCheckboxField(field);
    } else {
      return _buildTextInputField(field);
    }
  }
  
  // إنشاء widget مخصص لحقول التوقيع مع عرض الصورة
  Widget _buildSignatureField(UIField field) {
    final bool hasSignature = _signatureImage != null && _signatureFieldId == field.boxId;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSignature ? Colors.green : Colors.purpleAccent,
          width: 2,
        ),
        color: hasSignature 
          ? Colors.green.withOpacity(0.1) 
          : Colors.purpleAccent.withOpacity(0.05),
      ),
      child: Column(
        children: [
          if (hasSignature) ...[
            // عرض صورة التوقيع إذا كانت موجودة
            Container(
              height: 150,
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.5)),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _signatureImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // شريط تأكيد إضافة التوقيع
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _languageDirection == 'rtl'
                      ? 'تم إضافة التوقيع بنجاح'
                      : 'Signature added successfully',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // زر لإضافة التوقيع إذا لم يكن موجوداً
            InkWell(
              onTap: _handleSignatureInput,
              borderRadius: BorderRadius.circular(12),
              splashColor: Colors.purpleAccent.withOpacity(0.3),
              highlightColor: Colors.purpleAccent.withOpacity(0.1),
              child: Container(
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.3),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: Colors.purpleAccent[100],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _languageDirection == 'rtl' 
                        ? 'اضغط هنا لإضافة صورة توقيعك' 
                        : 'Tap here to add your signature',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _languageDirection == 'rtl' 
                        ? 'يمكنك التقاط صورة أو اختيار صورة من المعرض' 
                        : 'You can take a photo or choose from gallery',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // زر لتغيير التوقيع إذا كان موجوداً
          if (hasSignature) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _handleSignatureInput,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(_languageDirection == 'rtl' ? 'تغيير التوقيع' : 'Change Signature'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // إنشاء widget لحقول الاختيار
  Widget _buildCheckboxField(UIField field) {
    final bool isChecked = _formData[field.boxId] == 'true';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
        color: Colors.purpleAccent.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: (value) {
              _formData[field.boxId] = (value ?? false).toString();
              setState(() {});
              _updateLivePreview();
            },
            activeColor: Colors.purpleAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              field.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // إنشاء widget لحقول النص العادية
  Widget _buildTextInputField(UIField field) {
    return TextField(
      controller: _textController,
      decoration: InputDecoration(
        labelText: field.label,
        hintText: field.label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.purpleAccent.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.purpleAccent.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.purpleAccent),
        ),
        filled: true,
        fillColor: Colors.purpleAccent.withOpacity(0.05),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      style: const TextStyle(color: Colors.white),
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          _saveFieldValue(value.trim());
        }
      },
    );
  }

  /// معالجة الحقول وتطبيق كشف التوقيع باستخدام SignatureFieldDetector
  void _processFieldsWithSignatureDetection() {
    for (int i = 0; i < _formFields.length; i++) {
      final field = _formFields[i];
      
      // تطبيق كشف التوقيع على كل حقل
      if (SignatureFieldDetector.isSignatureField(field.label)) {
        // تغيير نوع الحقل إلى signature إذا تم كشفه كحقل توقيع
        _formFields[i] = UIField(
          boxId: field.boxId,
          label: field.label,
          type: 'signature', // تحديث النوع إلى signature
          box: field.box,
          value: field.value,
        );
        
        debugPrint('🔍 تم كشف حقل توقيع: ${field.label} (ID: ${field.boxId})');
      }
    }
    
    // إجراء إضافي: طباعة تقرير عن حقول التوقيع المكتشفة
    final signatureFields = _formFields.where((field) => field.type == 'signature').toList();
    debugPrint('📊 إجمالي حقول التوقيع المكتشفة: ${signatureFields.length}');
    
    for (final field in signatureFields) {
      debugPrint('  - ${field.label} (ID: ${field.boxId})');
    }
  }

  /// معالجة حقول PDF وتطبيق كشف التوقيع
  void _processPdfFieldsWithSignatureDetection(Map<int, List<UIField>> pdfPageFields) {
    pdfPageFields.forEach((pageNumber, fields) {
      for (int i = 0; i < fields.length; i++) {
        final field = fields[i];
        
        // تطبيق كشف التوقيع على كل حقل في الصفحة
        if (SignatureFieldDetector.isSignatureField(field.label)) {
          // تغيير نوع الحقل إلى signature إذا تم كشفه كحقل توقيع
          pdfPageFields[pageNumber]![i] = UIField(
            boxId: field.boxId,
            label: field.label,
            type: 'signature', // تحديث النوع إلى signature
            box: field.box,
            value: field.value,
          );
          
          debugPrint('🔍 تم كشف حقل توقيع في الصفحة $pageNumber: ${field.label} (ID: ${field.boxId})');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      appBar: AppBar(
        title: Text(
          _languageDirection == 'rtl' ? 'تحليل النماذج' : 'Form Analyzer',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1F37),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زر تبديل المساعد الصوتي
          IconButton(
            icon: Icon(
              _voiceAssistantEnabled ? Icons.mic : Icons.mic_off,
              color: _voiceAssistantEnabled ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              final newState = !_voiceAssistantEnabled;
              appProvider.setVoiceAssistantEnabled(newState);
              setState(() {
                _voiceAssistantEnabled = newState;
              });
              
              // إظهار رسالة تأكيد
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _languageDirection == 'rtl' 
                      ? (newState ? 'تم تفعيل المساعد الصوتي' : 'تم إيقاف المساعد الصوتي')
                      : (newState ? 'Voice Assistant Enabled' : 'Voice Assistant Disabled'),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: newState ? Colors.green : Colors.orange,
                ),
              );
            },
            tooltip: _languageDirection == 'rtl' 
              ? (_voiceAssistantEnabled ? 'إيقاف المساعد الصوتي' : 'تفعيل المساعد الصوتي')
              : (_voiceAssistantEnabled ? 'Disable Voice Assistant' : 'Enable Voice Assistant'),
          ),
          if (_formFields.isNotEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _showReviewDialog,
              tooltip: _languageDirection == 'rtl' ? 'تحميل النموذج' : 'Download Form',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // عنوان الصفحة للملفات متعددة الصفحات
              if (_isPdfMultiPage && _pdfPagesWithFields.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E2340), Color(0xFF252A4A)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _languageDirection == 'rtl' 
                          ? 'الصفحة $_currentPdfPage من $_totalPdfPages'
                          : 'Page $_currentPdfPage of $_totalPdfPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _languageDirection == 'rtl'
                          ? 'عدد الحقول: ${_formFields.length}'
                          : 'Fields: ${_formFields.length}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // أزرار التنقل لملفات PDF متعددة الصفحات
              if (_isPdfMultiPage && _pdfPagesWithFields.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E2340), Color(0xFF252A4A)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      // Previous button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _currentPdfPage != _pdfPagesWithFields.first
                              ? () => _navigateToPdfPage(_getPreviousPdfPage())
                              : null,
                          icon: Icon(_languageDirection == 'rtl' ? Icons.arrow_forward : Icons.arrow_back),
                          label: Text(_languageDirection == 'rtl' ? 'السابق' : 'Previous'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent.withOpacity(0.8),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Current page indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
                        ),
                        child: Text(
                          '$_currentPdfPage',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Next button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _currentPdfPage != _pdfPagesWithFields.last
                              ? () => _navigateToPdfPage(_getNextPdfPage())
                              : null,
                          icon: Icon(_languageDirection == 'rtl' ? Icons.arrow_back : Icons.arrow_forward),
                          label: Text(_languageDirection == 'rtl' ? 'التالي' : 'Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent.withOpacity(0.8),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading || _isAnalyzing
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1E2340), Color(0xFF252A4A)],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isAnalyzing
                                    ? (_languageDirection == 'rtl' ? 'جارٍ تحليل النموذج...' : 'Analyzing form...')
                                    : (_languageDirection == 'rtl' ? 'جارٍ التحميل...' : 'Loading...'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _formFields.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFF1E2340), Color(0xFF252A4A)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.document_scanner,
                                        size: 64,
                                        color: Colors.purpleAccent[100],
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        _languageDirection == 'rtl'
                                            ? 'اختر ملف لتحليله'
                                            : 'Select a file to analyze',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _languageDirection == 'rtl'
                                            ? 'يمكنك اختيار صورة أو ملف PDF'
                                            : 'You can choose an image or PDF file',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _pickAndAnalyzeImage,
                                        icon: const Icon(Icons.upload_file),
                                        label: Text(_languageDirection == 'rtl' ? 'اختيار ملف' : 'Choose File'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purpleAccent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // بطاقة الحقل الحالي
                              if (_currentFieldIndex < _formFields.length)
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: Colors.purpleAccent.withOpacity(0.4), width: 1),
                                  ),
                                  color: const Color(0xFF1A1F37),
                                  elevation: 8,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _languageDirection == 'rtl'
                                              ? 'الحقل ${_currentFieldIndex + 1} من ${_formFields.length}'
                                              : 'Field ${_currentFieldIndex + 1} of ${_formFields.length}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formFields[_currentFieldIndex].label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildInputField(),
                                        const SizedBox(height: 16),
                                        // إظهار رسالة توضيحية إذا كان المساعد الصوتي معطل أو كان الحقل توقيع
                                        if (!_voiceAssistantEnabled || _formFields[_currentFieldIndex].type == 'signature')
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _formFields[_currentFieldIndex].type == 'signature' 
                                                    ? Icons.info 
                                                    : Icons.mic_off,
                                                  size: 16,
                                                  color: Colors.orange,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _formFields[_currentFieldIndex].type == 'signature'
                                                      ? (_languageDirection == 'rtl' 
                                                          ? 'حقل التوقيع يتطلب صورة - استخدم زر "إضافة توقيع"' 
                                                          : 'Signature field requires image - use "Add Signature" button')
                                                      : (_languageDirection == 'rtl' 
                                                          ? 'المساعد الصوتي معطل - اضغط على زر المايك في الأعلى لتفعيله' 
                                                          : 'Voice Assistant disabled - tap mic icon above to enable'),
                                                    style: const TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            if (_voiceAssistantEnabled && _formFields[_currentFieldIndex].type != 'signature') 
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: _handleVoiceInput,
                                                  icon: const Icon(Icons.mic, size: 20),
                                                  label: Text(_languageDirection == 'rtl' ? 'اضغط للتحدث' : 'Press to Speak'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green.withOpacity(0.8),
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            if (_voiceAssistantEnabled && _formFields[_currentFieldIndex].type != 'signature') 
                                              const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _formFields[_currentFieldIndex].type == 'signature'
                                                    ? _handleSignatureInput()
                                                    : _saveFieldValue(_textController.text),
                                                icon: Icon(_formFields[_currentFieldIndex].type == 'signature'
                                                    ? Icons.image
                                                    : Icons.save),
                                                label: Text(_formFields[_currentFieldIndex].type == 'signature'
                                                    ? (_languageDirection == 'rtl' ? 'إضافة توقيع' : 'Add Signature')
                                                    : (_languageDirection == 'rtl' ? 'حفظ' : 'Save')),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.purpleAccent,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: _moveToNextField,
                                                icon: const Icon(Icons.skip_next, size: 20),
                                                label: Text(_languageDirection == 'rtl' ? 'تخطي' : 'Skip'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange.withOpacity(0.8),
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // معاينة النموذج
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                                    color: const Color(0xFF1A1F37),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: _annotatedImage != null
                                        ? Image.memory(
                                            _annotatedImage!,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.preview,
                                                  size: 48,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  _languageDirection == 'rtl'
                                                      ? 'معاينة النموذج ستظهر هنا'
                                                      : 'Form preview will appear here',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
      // مؤشر حالة المساعد الصوتي
      bottomNavigationBar: _formFields.isNotEmpty ? Container(
        height: 40,
        color: _voiceAssistantEnabled ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _voiceAssistantEnabled ? Icons.mic : Icons.mic_off,
              size: 16,
              color: _voiceAssistantEnabled ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              _languageDirection == 'rtl' 
                ? (_voiceAssistantEnabled ? 'المساعد الصوتي مفعل' : 'المساعد الصوتي معطل')
                : (_voiceAssistantEnabled ? 'Voice Assistant Active' : 'Voice Assistant Disabled'),
              style: TextStyle(
                color: _voiceAssistantEnabled ? Colors.green : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ) : null,
    );
  }
}
