import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/image_quality_response.dart';

class ImageQualityCheckScreen extends StatefulWidget {
  final File imageFile;
  
  const ImageQualityCheckScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<ImageQualityCheckScreen> createState() => _ImageQualityCheckScreenState();
}

class _ImageQualityCheckScreenState extends State<ImageQualityCheckScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoading = true;
  ImageQualityResponse? _qualityResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
    
    _checkImageQuality();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkImageQuality() async {
    try {
      debugPrint('🔍 فحص جودة الصورة للملف: ${widget.imageFile.path}');
      final provider = Provider.of<AppProvider>(context, listen: false);
      final result = await provider.checkFormImageQuality(widget.imageFile);
      
      debugPrint('✅ نتيجة فحص الجودة: $result');
      
      setState(() {
        _qualityResult = ImageQualityResponse.fromJson(result);
        _isLoading = false;
      });
      
      debugPrint('📊 جودة جيدة: ${_qualityResult!.qualityGood}');
      debugPrint('🆔 معرف الجلسة: ${_qualityResult!.sessionId}');
      debugPrint('🔤 اتجاه اللغة: ${_qualityResult!.languageDirection}');
      
      _animationController.stop();
    } catch (e) {
      debugPrint('❌ خطأ في فحص الجودة: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _animationController.stop();
    }
  }

  void _continueToAnalysis() {
    if (_qualityResult != null) {
      debugPrint('🚀 الانتقال لتحليل النموذج مع البيانات:');
      debugPrint('📂 ملف الصورة: ${widget.imageFile.path}');
      debugPrint('🆔 معرف الجلسة: ${_qualityResult!.sessionId}');
      debugPrint('🔤 اتجاه اللغة: ${_qualityResult!.languageDirection}');
      
      Navigator.pushReplacementNamed(
        context,
        '/form_analyzer',
        arguments: {
          'imageFile': widget.imageFile,
          'sessionId': _qualityResult!.sessionId,
          'languageDirection': _qualityResult!.languageDirection,
          'qualityResult': _qualityResult,
        },
      );
    } else {
      debugPrint('❌ لا يمكن المتابعة - نتيجة الجودة فارغة');
    }
  }

  void _retryImageSelection() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'فحص جودة الصورة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Progress indicator
              if (_isLoading) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _animation.value * 2 * 3.14159,
                              child: const Icon(
                                Icons.refresh,
                                size: 64,
                                color: Color(0xFF0F3460),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'جاري فحص الصورة...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'يتم فحص جودة الصورة وكشف اللغة',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Error state
              if (_errorMessage != null) ...[
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'حدث خطأ في فحص الصورة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _retryImageSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F3460),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('اختيار صورة أخرى'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Success state
              if (_qualityResult != null) ...[
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image preview
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[600]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    widget.imageFile,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Quality status
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _qualityResult!.qualityGood 
                                      ? const Color(0xFF2E7D32).withOpacity(0.2)
                                      : const Color(0xFFD32F2F).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _qualityResult!.qualityGood 
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE57373),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _qualityResult!.qualityGood 
                                              ? Icons.check_circle
                                              : Icons.warning,
                                          color: _qualityResult!.qualityGood 
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFE57373),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _qualityResult!.qualityGood 
                                              ? 'جودة الصورة جيدة'
                                              : 'جودة الصورة ضعيفة',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _qualityResult!.qualityGood 
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFE57373),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_qualityResult!.qualityMessage.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _qualityResult!.qualityMessage,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[300],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Language detection
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16213E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[600]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.language,
                                          color: Color(0xFF0F3460),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'تم كشف اللغة: ${_qualityResult!.languageDirection == 'rtl' ? 'العربية' : 'الإنجليزية'}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'الأبعاد: ${_qualityResult!.imageWidth} × ${_qualityResult!.imageHeight} بكسل',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Form explanation
                              if (_qualityResult!.formExplanation.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16213E),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[600]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.description,
                                            color: Color(0xFF0F3460),
                                            size: 24,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'وصف النموذج',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _qualityResult!.formExplanation,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[300],
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _retryImageSelection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'اختيار صورة أخرى',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _qualityResult!.qualityGood ? _continueToAnalysis : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _qualityResult!.qualityGood 
                                      ? const Color(0xFF0F3460)
                                      : Colors.grey[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  _qualityResult!.qualityGood 
                                      ? 'متابعة التحليل'
                                      : 'الجودة غير كافية',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
