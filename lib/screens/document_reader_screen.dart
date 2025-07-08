import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart' as widgets;
import '../models/document_response.dart';
import '../services/speech_service.dart';

class DocumentReaderScreen extends StatefulWidget {
  const DocumentReaderScreen({super.key});

  @override
  State<DocumentReaderScreen> createState() => _DocumentReaderScreenState();
}

class _DocumentReaderScreenState extends State<DocumentReaderScreen> {
  File? _selectedDocument;
  String _selectedLanguage = 'arabic';
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildLanguageSelector(),
                const SizedBox(height: 20),
                _buildDocumentSelector(),
                const SizedBox(height: 20),
                if (provider.isDocumentUploading) _buildUploadingWidget(),
                if (provider.documentErrorMessage != null) 
                  _buildErrorWidget(provider.documentErrorMessage!),
                if (provider.documentUploadResult != null)
                  _buildDocumentInfoCard(provider.documentUploadResult!),
                if (provider.currentSlideAnalysis != null)
                  _buildSlideAnalysisSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قارئ المستندات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'قم برفع ملف PowerPoint أو PDF لقراءته وتحليل محتواه',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر لغة التحليل:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLanguageOption('arabic', 'العربية', Icons.language),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLanguageOption('english', 'English', Icons.translate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String value, String label, IconData icon) {
    final isSelected = _selectedLanguage == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentColor.withOpacity(0.1)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.accentColor
                : AppTheme.textSecondaryColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppTheme.accentColor
                  : AppTheme.textSecondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? AppTheme.accentColor
                    : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر المستند:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Health Check Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkServerHealth,
                icon: const Icon(Icons.health_and_safety),
                label: const Text('اختبار حالة الخادم'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_selectedDocument != null) 
              _buildSelectedDocument()
            else
              _buildDocumentPlaceholder(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.file_upload),
                    label: const Text('اختر مستند'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                    ),
                  ),
                ),
                if (_selectedDocument != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _uploadDocument,
                      icon: const Icon(Icons.analytics),
                      label: const Text('تحليل المستند'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDocument() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(_selectedDocument!.path),
              color: AppTheme.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFileName(_selectedDocument!.path),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileSize(_selectedDocument!),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedDocument = null),
            icon: const Icon(
              Icons.close,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textSecondaryColor.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: AppTheme.textSecondaryColor,
          ),
          SizedBox(height: 12),
          Text(
            'اختر ملف المستند',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'PDF, PPTX, PPT, DOCX',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingWidget() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: widgets.LoadingWidget(message: 'جاري رفع وتحليل المستند...'),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: widgets.ErrorWidget(
          message: error,
          onRetry: _selectedDocument != null ? _uploadDocument : null,
        ),
      ),
    );
  }

  Widget _buildDocumentInfoCard(DocumentResponse result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'تم رفع المستند بنجاح',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('اسم الملف', result.filename, Icons.description),
            _buildInfoRow('نوع الملف', result.fileTypeInArabic, Icons.category),
            _buildInfoRow('عدد الصفحات', '${result.totalPages} صفحة', Icons.pages),
            _buildInfoRow('اللغة', result.language == 'arabic' ? 'العربية' : 'الإنجليزية', Icons.language),
            if (result.presentationSummary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ملخص المحتوى:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _speakText(result.presentationSummary),
                          icon: const Icon(Icons.volume_up, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.presentationSummary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showFullDocumentSummary(),
                        icon: const Icon(Icons.summarize, size: 16),
                        label: const Text('عرض الملخص الشامل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlideAnalysisSection(AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildNavigationCard(provider),
        const SizedBox(height: 16),
        _buildSlideContentCard(provider.currentSlideAnalysis!),
      ],
    );
  }

  Widget _buildNavigationCard(AppProvider provider) {
    final canGoPrevious = provider.currentPageNumber > 1;
    final canGoNext = provider.documentUploadResult != null && 
                     provider.currentPageNumber < provider.documentUploadResult!.totalPages;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الصفحة ${provider.currentPageNumber} من ${provider.documentUploadResult?.totalPages ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (provider.isDocumentAnalyzing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Voice Navigation Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.record_voice_over,
                    color: AppTheme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isListening ? 'جاري الاستماع... قل رقم الصفحة' : 'استخدم الصوت للتنقل',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleVoiceNavigation,
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : AppTheme.accentColor,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isListening 
                          ? Colors.red.withOpacity(0.1) 
                          : AppTheme.accentColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canGoPrevious && !provider.isDocumentAnalyzing
                        ? () => provider.navigateToPreviousPage()
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('السابق'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canGoNext && !provider.isDocumentAnalyzing
                        ? () => provider.navigateToNextPage()
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('التالي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContentCard(SlideAnalysisResponse slide) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.content_copy,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'محتوى الصفحة ${slide.pageNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                // Text-to-Speech button
                IconButton(
                  onPressed: () => _speakPageContent(slide),
                  icon: const Icon(Icons.volume_up),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                ),
                // Ask Question button
                IconButton(
                  onPressed: () => _showQuestionDialog(slide.pageNumber),
                  icon: const Icon(Icons.help_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (slide.hasText) ...[
              _buildSectionHeader('النص المستخرج', Icons.text_fields),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.slideText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'عدد الكلمات: ${slide.wordCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'وقت القراءة: ${slide.readingTime} دقيقة',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (slide.hasExplanation) ...[
              _buildSectionHeader('الشرح والتحليل', Icons.psychology),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  slide.slideExplanation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (slide.hasImages) ...[
              _buildSectionHeader('الصور (${slide.imagesCountInArabic})', Icons.image),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحتوي هذه الصفحة على ${slide.imagesCountInArabic}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _loadPageImage(slide.pageNumber),
                      icon: const Icon(Icons.image, size: 16),
                      label: const Text('عرض صورة الصفحة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.accentColor,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String path) {
    String extension = path.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow;
      case 'docx':
      case 'doc':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileName(String path) {
    return path.split('/').last;
  }

  String _getFileSize(File file) {
    int bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes بايت';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} كيلوبايت';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت';
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'pptx', 'ppt', 'docx', 'doc'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedDocument = File(result.files.single.path!);
        });
        // Clear previous results
        if (mounted) {
          context.read<AppProvider>().clearDocumentAnalysis();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('فشل في اختيار المستند: $e');
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedDocument == null) return;
    
    // حفظ reference للـ provider قبل العملية async
    final provider = context.read<AppProvider>();
    
    try {
      await provider.uploadDocument(
        _selectedDocument!.path,
        language: _selectedLanguage,
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('فشل في رفع المستند: $e');
      }
    }
  }

  Future<void> _checkServerHealth() async {
    final provider = context.read<AppProvider>();
    
    try {
      _showInfoSnackBar('جاري فحص الخادم...');
      
      final health = await provider.apiService.checkSystemHealth();
      
      if (health['status'] == 'healthy' || health.containsKey('services')) {
        _showSuccessSnackBar('✅ الخادم يعمل بشكل طبيعي');
      } else {
        _showErrorSnackBar('❌ الخادم غير متاح حالياً');
      }
    } catch (e) {
      _showErrorSnackBar('❌ فشل في الاتصال بالخادم: $e');
    }
  }

  Future<void> _toggleVoiceNavigation() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      // Check permission first
      final hasPermission = await _speechService.checkPermission();
      if (!hasPermission) {
        final granted = await _speechService.requestPermission();
        if (!granted) {
          _showErrorSnackBar('❌ يجب منح إذن الميكروفون لاستخدام هذه الميزة');
          return;
        }
      }

      setState(() {
        _isListening = true;
      });

      await _speechService.startListening(
        onResult: _handleVoiceNavigationResult,
        localeId: 'ar_SA',
        timeout: const Duration(seconds: 10),
      );
    }
  }

  void _handleVoiceNavigationResult(String text) {
    setState(() {
      _isListening = false;
    });

    print('🎤 نتيجة الصوت: $text');
    
    if (text.isNotEmpty) {
      final provider = context.read<AppProvider>();
      if (provider.currentSessionId != null) {
        _showInfoSnackBar('🔍 جاري معالجة الأمر الصوتي...');
        
        // استخدام الـ API الجديد للتنقل الصوتي
        provider.navigateWithVoice(text).then((_) {
          if (provider.documentErrorMessage != null) {
            _showErrorSnackBar(provider.documentErrorMessage!);
          } else {
            _showSuccessSnackBar('📄 تم التنقل بنجاح إلى الصفحة ${provider.currentPageNumber}');
          }
        }).catchError((error) {
          _showErrorSnackBar('❌ فشل في التنقل: $error');
        });
      } else {
        _showErrorSnackBar('❌ لا توجد جلسة مستند نشطة');
      }
    } else {
      _showErrorSnackBar('❌ لم أتمكن من سماع أي شيء. جرب مرة أخرى');
    }
  }

  // New methods for enhanced document interaction
  
  Future<void> _speakPageContent(SlideAnalysisResponse slide) async {
    try {
      String textToSpeak = '';
      
      if (slide.hasText) {
        textToSpeak += slide.originalText;
      }
      
      if (slide.hasExplanation) {
        if (textToSpeak.isNotEmpty) textToSpeak += '\n\n';
        textToSpeak += slide.explanation;
      }
      
      if (textToSpeak.isEmpty) {
        _showInfoSnackBar('لا يوجد نص لقراءته في هذه الصفحة');
        return;
      }
      
      _showInfoSnackBar('🔊 جاري تحويل النص إلى صوت...');
      
      final provider = context.read<AppProvider>();
      await provider.apiService.documentTextToSpeech(textToSpeak);
      
      _showSuccessSnackBar('✅ تم تشغيل الصوت بنجاح');
    } catch (e) {
      _showErrorSnackBar('❌ فشل في تحويل النص إلى صوت: $e');
    }
  }

  void _showQuestionDialog(int pageNumber) {
    final TextEditingController questionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اسأل عن محتوى الصفحة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ماذا تريد أن تعرف عن الصفحة $pageNumber؟',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: questionController,
              decoration: const InputDecoration(
                hintText: 'مثال: ما هي النقاط الرئيسية في هذه الصفحة؟',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _askPageQuestion(pageNumber, questionController.text);
            },
            child: const Text('اسأل'),
          ),
        ],
      ),
    );
  }

  Future<void> _askPageQuestion(int pageNumber, String question) async {
    if (question.trim().isEmpty) {
      _showErrorSnackBar('يجب كتابة سؤال أولاً');
      return;
    }
    
    try {
      _showInfoSnackBar('🤔 جاري البحث عن الإجابة...');
      
      final provider = context.read<AppProvider>();
      final sessionId = provider.currentSessionId;
      
      if (sessionId == null) {
        _showErrorSnackBar('❌ لا توجد جلسة مستند نشطة');
        return;
      }
      
      final response = await provider.apiService.askPageQuestion(
        sessionId, 
        pageNumber, 
        question,
      );
      
      _showQuestionAnswerDialog(question, response['answer'] ?? 'لم أتمكن من العثور على إجابة');
    } catch (e) {
      _showErrorSnackBar('❌ فشل في الحصول على الإجابة: $e');
    }
  }

  void _showQuestionAnswerDialog(String question, String answer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الإجابة'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'السؤال:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الإجابة:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      answer,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _speakText(answer);
            },
            icon: const Icon(Icons.volume_up, size: 16),
            label: const Text('استمع للإجابة'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPageImage(int pageNumber) async {
    try {
      _showInfoSnackBar('🖼️ جاري تحميل صورة الصفحة...');
      
      final provider = context.read<AppProvider>();
      final sessionId = provider.currentSessionId;
      
      if (sessionId == null) {
        _showErrorSnackBar('❌ لا توجد جلسة مستند نشطة');
        return;
      }
      
      final imageBytes = await provider.apiService.getPageImage(sessionId, pageNumber);
      
      _showPageImageDialog(pageNumber, imageBytes);
    } catch (e) {
      _showErrorSnackBar('❌ فشل في تحميل صورة الصفحة: $e');
    }
  }

  void _showPageImageDialog(int pageNumber, List<int> imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'صورة الصفحة $pageNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Image.memory(
                    Uint8List.fromList(imageBytes),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _speakText(String text) async {
    try {
      _showInfoSnackBar('🔊 جاري تحويل النص إلى صوت...');
      
      final provider = context.read<AppProvider>();
      await provider.apiService.documentTextToSpeech(text);
      
      _showSuccessSnackBar('✅ تم تشغيل الصوت بنجاح');
    } catch (e) {
      _showErrorSnackBar('❌ فشل في تحويل النص إلى صوت: $e');
    }
  }

  Future<void> _showFullDocumentSummary() async {
    try {
      _showInfoSnackBar('📑 جاري تحميل الملخص الشامل...');
      
      final provider = context.read<AppProvider>();
      final sessionId = provider.currentSessionId;
      
      if (sessionId == null) {
        _showErrorSnackBar('❌ لا توجد جلسة مستند نشطة');
        return;
      }
      
      final summary = await provider.apiService.getDocumentSummary(sessionId);
      
      _showDocumentSummaryDialog(summary);
    } catch (e) {
      _showErrorSnackBar('❌ فشل في تحميل الملخص الشامل: $e');
    }
  }

  void _showDocumentSummaryDialog(DocumentSummaryResponse summary) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.summarize, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'الملخص الشامل للمستند',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _speakText(summary.overallSummary),
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryInfoRow('اسم الملف:', summary.filename),
                      _buildSummaryInfoRow('إجمالي الصفحات:', '${summary.totalPages} صفحة'),
                      _buildSummaryInfoRow('اللغة:', summary.language == 'arabic' ? 'العربية' : 'الإنجليزية'),
                      const SizedBox(height: 16),
                      const Text(
                        'الملخص:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          summary.overallSummary,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimaryColor,
                            height: 1.6,
                          ),
                        ),
                      ),
                      if (summary.hasKeyTopics) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'الموضوعات الرئيسية:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...summary.keyTopics.map((topic) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.accentColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    topic,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}