import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

/// Widget لرفع صورة التوقيع
class SignatureUploadWidget extends StatefulWidget {
  final String fieldLabel;
  final String fieldId;
  final Function(Uint8List? signatureBytes, String fieldId) onSignatureSelected;
  final Uint8List? currentSignature;
  final String? languageDirection;

  const SignatureUploadWidget({
    super.key,
    required this.fieldLabel,
    required this.fieldId,
    required this.onSignatureSelected,
    this.currentSignature,
    this.languageDirection,
  });

  @override
  State<SignatureUploadWidget> createState() => _SignatureUploadWidgetState();
}

class _SignatureUploadWidgetState extends State<SignatureUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  /// رفع صورة التوقيع من المعرض
  Future<void> _pickSignatureFromGallery() async {
    setState(() => _isLoading = true);
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 400,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        widget.onSignatureSelected(bytes, widget.fieldId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.languageDirection == 'rtl' 
                ? 'تم رفع التوقيع بنجاح'
                : 'Signature uploaded successfully'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.languageDirection == 'rtl' 
              ? 'خطأ في رفع التوقيع: $e'
              : 'Error uploading signature: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// التقاط صورة التوقيع بالكاميرا
  Future<void> _takeSignaturePhoto() async {
    setState(() => _isLoading = true);
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 400,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        widget.onSignatureSelected(bytes, widget.fieldId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.languageDirection == 'rtl' 
                ? 'تم التقاط التوقيع بنجاح'
                : 'Signature captured successfully'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.languageDirection == 'rtl' 
              ? 'خطأ في التقاط التوقيع: $e'
              : 'Error capturing signature: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// حذف التوقيع الحالي
  void _clearSignature() {
    widget.onSignatureSelected(null, widget.fieldId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.languageDirection == 'rtl' 
          ? 'تم حذف التوقيع'
          : 'Signature cleared'
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.languageDirection == 'rtl';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الحقل
          Row(
            children: [
              Icon(
                Icons.draw,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fieldLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // رسالة إرشادية
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRtl 
                      ? 'يرجى رفع صورة واضحة للتوقيع'
                      : 'Please upload a clear signature image',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 14,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // أزرار الرفع
          if (widget.currentSignature == null) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickSignatureFromGallery,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_library),
                    label: Text(
                      isRtl ? 'من المعرض' : 'From Gallery',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _takeSignaturePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      isRtl ? 'التقاط صورة' : 'Take Photo',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // عرض التوقيع المرفوع
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    isRtl ? 'التوقيع المرفوع:' : 'Uploaded Signature:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 150,
                      maxWidth: 300,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        widget.currentSignature!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: _pickSignatureFromGallery,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          isRtl ? 'تغيير' : 'Change',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearSignature,
                        icon: const Icon(Icons.delete),
                        label: Text(
                          isRtl ? 'حذف' : 'Delete',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // نصائح
          Text(
            isRtl 
              ? 'نصائح: استخدم خلفية بيضاء وإضاءة جيدة'
              : 'Tips: Use white background and good lighting',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}
