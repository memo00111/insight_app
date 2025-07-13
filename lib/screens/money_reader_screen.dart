import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart' as widgets;
import '../models/currency_analysis_response.dart';

class MoneyReaderScreen extends StatefulWidget {
  const MoneyReaderScreen({super.key});

  @override
  State<MoneyReaderScreen> createState() => _MoneyReaderScreenState();
}

class _MoneyReaderScreenState extends State<MoneyReaderScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

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
                _buildTipsCard(),
                const SizedBox(height: 20),
                _buildImageSelector(),
                const SizedBox(height: 20),
                if (provider.isCurrencyAnalyzing) _buildLoadingWidget(),
                // تم إزالة عرض رسائل الخطأ
                if (provider.currencyAnalysisResult != null)
                  _buildResultsSection(provider.currencyAnalysisResult!),
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
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: AppTheme.secondaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'محلل العملات',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'قم برفع صورة عملة أو ورقة نقدية لتحليلها وتحديد نوعها وقيمتها',
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

  Widget _buildTipsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.warningColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'نصائح للحصول على أفضل النتائج',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem(Icons.camera_alt, 'تأكد من وضوح الصورة وجودة الإضاءة'),
            _buildTipItem(Icons.center_focus_strong, 'ضع العملة في منتصف الصورة'),
            _buildTipItem(Icons.straighten, 'اجعل العملة مستقيمة وغير مائلة'),
            _buildTipItem(Icons.zoom_out_map, 'تأكد من ظهور العملة كاملة في الصورة'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر صورة للتحليل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: widgets.AppButton(
                    text: 'التقط صورة',
                    icon: Icons.camera_alt,
                    onPressed: Provider.of<AppProvider>(context).isCurrencyAnalyzing
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: widgets.AppButton(
                    text: 'اختر من المعرض',
                    icon: Icons.photo_library,
                    onPressed: Provider.of<AppProvider>(context).isCurrencyAnalyzing
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: widgets.LoadingWidget(message: 'جاري تحليل العملة...'),
      ),
    );
  }

  Widget _buildResultsSection(CurrencyAnalysisResponse result) {
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
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    result.isSuccess ? Icons.check_circle : Icons.error_outline,
                    color: result.isSuccess ? AppTheme.successColor : AppTheme.errorColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'نتيجة التحليل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: result.isSuccess ? AppTheme.successColor.withOpacity(0.2) : AppTheme.errorColor.withOpacity(0.2),
                ),
              ),
              child: Text(
                result.analysis,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      // Call the provider to analyze the image
      _analyzeCurrency();
    }
  }

  Future<void> _analyzeCurrency() async {
    if (_selectedImage != null) {
      try {
        await Provider.of<AppProvider>(context, listen: false)
            .analyzeCurrency(_selectedImage!);
      } catch (e) {
        // عدم إظهار أي رسالة خطأ
      }
    }
  }
}