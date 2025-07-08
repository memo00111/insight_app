# دليل API المفصل - تطبيق قارئ النماذج

## معلومات عامة

**Base URL**: `http://127.0.0.1:8000` (محلي) أو `https://your-domain.com` (production)

**Content-Type**: 
- للملفات: `multipart/form-data`
- للـ JSON: `application/json`

---

## 🔗 Form Analyzer APIs

### 1. فحص جودة الصورة وكشف اللغة

**Endpoint**: `POST /form/check-image`

**الغرض**: 
- فحص جودة الصورة المرفوعة
- كشف اتجاه اللغة (عربي/إنجليزي)
- إنشاء session جديدة
- تقديم شرح أولي للنموذج

**الطلب**:
```http
POST /form/check-image
Content-Type: multipart/form-data

file: [binary data] (jpg, png, jpeg, bmp, pdf)
```

**الرد الناجح** (200):
```json
{
  "language_direction": "rtl",              // "rtl" للعربي، "ltr" للإنجليزي
  "quality_good": true,                     // جودة الصورة جيدة؟
  "quality_message": "Image quality is good", // رسالة الجودة
  "image_width": 1200,                      // عرض الصورة بالبكسل
  "image_height": 800,                      // ارتفاع الصورة بالبكسل
  "session_id": "abc123-def456-ghi789",     // معرف الجلسة للاستخدام اللاحق
  "form_explanation": "هذا نموذج طلب عمل يحتوي على..." // شرح النموذج
}
```

**أخطاء محتملة**:
- `500`: خطأ في معالجة الصورة
- `400`: ملف غير صالح

**استخدام في Flutter**:
```dart
Future<Map<String, dynamic>?> checkImageQuality(File imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/form/check-image'),
  );
  
  request.files.add(await http.MultipartFile.fromPath(
    'file',
    imageFile.path,
  ));
  
  var response = await request.send();
  if (response.statusCode == 200) {
    var responseData = await response.stream.toBytes();
    return jsonDecode(String.fromCharCodes(responseData));
  }
  throw Exception('Failed to check image quality: ${response.statusCode}');
}
```

---

### 2. تحليل النموذج الرئيسي

**Endpoint**: `POST /form/analyze-form`

**الغرض**:
- تحليل النموذج بالكامل
- استخراج جميع الحقول القابلة للتعبئة
- تحديد نوع كل حقل (نص، خانة اختيار، توقيع)
- إرجاع مواقع الحقول بالبكسل

**الطلب**:
```http
POST /form/analyze-form
Content-Type: multipart/form-data

file: [binary data]
session_id: "abc123-def456-ghi789"     // من check-image
language_direction: "rtl"              // اختياري، يأخذ من الجلسة إذا لم يُحدد
```

**الرد الناجح** (200):
```json
{
  "fields": [
    {
      "box_id": "field_1",                 // معرف فريد للحقل
      "label": "الاسم الكامل",             // نص الحقل
      "type": "text",                      // نوع الحقل: text, checkbox
      "box": [150.5, 200.3, 300.0, 40.0]  // [x_center, y_center, width, height]
    },
    {
      "box_id": "field_2",
      "label": "هل أنت متزوج؟",
      "type": "checkbox",
      "box": [150.5, 250.3, 20.0, 20.0]
    },
    {
      "box_id": "field_3",
      "label": "التوقيع هنا",
      "type": "text",                      // حقول التوقيع تُكتشف بالكلمات المفتاحية
      "box": [150.5, 300.3, 200.0, 50.0]
    }
  ],
  "form_explanation": "",                  // فارغ في هذا الـ endpoint
  "language_direction": "rtl",
  "image_width": 1200,
  "image_height": 800,
  "session_id": "abc123-def456-ghi789"
}
```

**أخطاء محتملة**:
- `400`: لم يتم العثور على حقول قابلة للتعبئة
- `500`: فشل في تحليل النموذج

**كشف حقول التوقيع**:
```dart
bool isSignatureField(String label) {
  List<String> signatureKeywords = [
    // عربي
    'توقيع', 'التوقيع', 'توقيعي', 'توقيعك', 
    'امضاء', 'الامضاء', 'امضائي', 'امضاؤك',
    'اعتماد', 'ختم', 'الختم',
    
    // إنجليزي
    'signature', 'signatures', 'signed', 'sign here',
    'sign by', 'autograph', 'endorsement'
  ];
  
  return signatureKeywords.any((keyword) => 
    label.toLowerCase().contains(keyword.toLowerCase())
  );
}
```

---

### 3. تحديث المعاينة المباشرة

**Endpoint**: `POST /form/annotate-image`

**الغرض**:
- إنشاء معاينة مباشرة للنموذج مع البيانات المدخلة
- عرض النصوص المكتوبة والخانات المحددة
- إضافة صورة التوقيع في المكان المناسب

**الطلب**:
```http
POST /form/annotate-image
Content-Type: application/json

{
  "original_image_b64": "base64-encoded-image-data",
  "texts_dict": {
    "field_1": "أحمد محمد علي",          // النصوص المدخلة
    "field_2": true,                     // خانات الاختيار (boolean)
    "field_3": ""                        // حقول فارغة
  },
  "ui_fields": [                         // نفس البيانات من analyze-form
    {
      "box_id": "field_1",
      "label": "الاسم الكامل",
      "type": "text",
      "box": [150.5, 200.3, 300.0, 40.0]
    }
  ],
  "signature_image_b64": "base64-signature-image", // صورة التوقيع (اختياري)
  "signature_field_id": "field_3"                  // معرف حقل التوقيع (اختياري)
}
```

**الرد الناجح** (200):
```
Content-Type: image/png
[binary image data]
```

**استخدام في Flutter**:
```dart
Future<Uint8List?> updateLiveImage({
  required Uint8List originalImageBytes,
  required Map<String, dynamic> formData,
  required List<Map<String, dynamic>> uiFields,
  String? signatureB64,
  String? signatureFieldId,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/form/annotate-image'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'original_image_b64': base64Encode(originalImageBytes),
      'texts_dict': formData,
      'ui_fields': uiFields,
      'signature_image_b64': signatureB64,
      'signature_field_id': signatureFieldId,
    }),
  );
  
  if (response.statusCode == 200) {
    return response.bodyBytes;
  }
  return null;
}
```

---

### 4. تحويل النص إلى كلام

**Endpoint**: `POST /form/text-to-speech`

**الغرض**: تحويل النصوص العربية/الإنجليزية إلى ملف صوتي

**الطلب**:
```http
POST /form/text-to-speech
Content-Type: application/json

{
  "text": "مرحباً بك في تطبيق قارئ النماذج",
  "provider": "gemini"                    // حالياً فقط "gemini"
}
```

**الرد الناجح** (200):
```
Content-Type: audio/wav
[binary audio data]
```

**أخطاء محتملة**:
- `429`: تجاوز الحد الأقصى لاستخدام الخدمة
- `500`: فشل في تحويل النص

**استخدام في Flutter**:
```dart
Future<Uint8List?> textToSpeech(String text) async {
  final response = await http.post(
    Uri.parse('$baseUrl/form/text-to-speech'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'text': text,
      'provider': 'gemini'
    }),
  );
  
  if (response.statusCode == 200) {
    return response.bodyBytes;
  } else if (response.statusCode == 429) {
    throw Exception('تم تجاوز الحد الأقصى لاستخدام خدمة تحويل النص إلى كلام');
  }
  return null;
}

// تشغيل الصوت
Future<void> playAudio(Uint8List audioBytes) async {
  // استخدم just_audio أو audioplayers
  final tempDir = await getTemporaryDirectory();
  final tempFile = File('${tempDir.path}/temp_audio.wav');
  await tempFile.writeAsBytes(audioBytes);
  
  final audioPlayer = AudioPlayer();
  await audioPlayer.setFilePath(tempFile.path);
  await audioPlayer.play();
}
```

---

### 5. تحويل الكلام إلى نص

**Endpoint**: `POST /form/speech-to-text`

**الغرض**: تحويل الملفات الصوتية إلى نص

**الطلب**:
```http
POST /form/speech-to-text
Content-Type: multipart/form-data

audio: [binary audio data] (wav format)
language_code: "ar"                      // "ar" للعربي، "en" للإنجليزي
```

**الرد الناجح** (200):
```json
{
  "text": "أحمد محمد علي السعيد"
}
```

**أخطاء محتملة**:
- `429`: تجاوز الحد الأقصى
- `500`: فشل في التحويل

**استخدام في Flutter**:
```dart
Future<String?> speechToText(Uint8List audioBytes, String languageCode) async {
  var request = http.MultipartRequest(
    'POST', 
    Uri.parse('$baseUrl/form/speech-to-text')
  );
  
  request.files.add(
    http.MultipartFile.fromBytes(
      'audio', 
      audioBytes, 
      filename: 'audio.wav',
      contentType: MediaType('audio', 'wav'),
    )
  );
  request.fields['language_code'] = languageCode;
  
  var response = await request.send();
  if (response.statusCode == 200) {
    var responseData = await response.stream.toBytes();
    var result = jsonDecode(String.fromCharCodes(responseData));
    return result['text'];
  }
  return null;
}
```

---

### 6. إدارة الجلسات

**إنهاء الجلسة**: `DELETE /form/session/{session_id}`

**الطلب**:
```http
DELETE /form/session/abc123-def456-ghi789
```

**الرد** (200):
```json
{
  "message": "Session abc123-def456-ghi789 deleted successfully"
}
```

**معلومات الجلسات**: `GET /form/session-info`

**الرد** (200):
```json
{
  "active_sessions": 5,
  "session_timeout": 3600
}
```

---

## 🔗 Money Reader APIs

### تحليل العملات

**Endpoint**: `POST /money/analyze-currency`

**الطلب**:
```http
POST /money/analyze-currency
Content-Type: multipart/form-data

file: [binary image data]
```

**الرد** (200):
```json
{
  "analysis": "هذه ورقة نقدية فئة مائة ريال سعودي",
  "status": "success"
}
```

---

## 🔗 Document Reader APIs

### 1. رفع مستند

**Endpoint**: `POST /document/upload`

**الطلب**:
```http
POST /document/upload
Content-Type: multipart/form-data

file: [binary data] (.pptx, .ppt, .pdf)
```

**الرد** (200):
```json
{
  "session_id": "doc_abc123",
  "filename": "presentation.pptx",
  "file_type": ".pptx",
  "total_pages": 25,
  "language": "arabic",
  "presentation_summary": "هذه محاضرة عن...",
  "status": "success",
  "message": "تم تحليل المستند بنجاح"
}
```

### 2. تحليل صفحة معينة

**Endpoint**: `GET /document/{session_id}/page/{page_number}`

**الرد** (200):
```json
{
  "page_number": 5,
  "title": "العنوان الخامس",
  "original_text": "النص الأصلي...",
  "explanation": "شرح محتوى الصفحة...",
  "key_points": ["النقطة الأولى", "النقطة الثانية"],
  "slide_type": "content",
  "importance_level": "high",
  "image_data": "base64-encoded-slide-image",
  "word_count": 150,
  "reading_time": 2.5
}
```

### 3. التنقل الصوتي

**Endpoint**: `POST /document/{session_id}/navigate`

**الطلب**:
```json
{
  "command": "اذهب للصفحة العاشرة",
  "current_page": 5
}
```

**الرد** (200):
```json
{
  "success": true,
  "new_page": 10,
  "message": "تم الانتقال للصفحة 10"
}
```

---

## مثال شامل - Flutter Service Class

```dart
class FormAnalyzerService {
  final String baseUrl;
  final http.Client httpClient;
  
  FormAnalyzerService({
    required this.baseUrl,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  // فحص جودة الصورة
  Future<ImageQualityResult> checkImageQuality(File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/form/check-image'),
    );
    
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    ));
    
    var response = await request.send();
    var responseData = await response.stream.toBytes();
    
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(String.fromCharCodes(responseData));
      return ImageQualityResult.fromJson(jsonData);
    } else {
      throw FormAnalyzerException(
        'Failed to check image quality: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  // تحليل النموذج
  Future<FormAnalysisResult> analyzeForm({
    required File imageFile,
    required String sessionId,
    String? languageDirection,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/form/analyze-form'),
    );
    
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    request.fields['session_id'] = sessionId;
    if (languageDirection != null) {
      request.fields['language_direction'] = languageDirection;
    }
    
    var response = await request.send();
    var responseData = await response.stream.toBytes();
    
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(String.fromCharCodes(responseData));
      return FormAnalysisResult.fromJson(jsonData);
    } else {
      throw FormAnalyzerException(
        'Failed to analyze form: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  // تحديث المعاينة
  Future<Uint8List> annotateImage({
    required Uint8List originalImageBytes,
    required Map<String, dynamic> textsDict,
    required List<UIField> uiFields,
    String? signatureImageB64,
    String? signatureFieldId,
  }) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/form/annotate-image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'original_image_b64': base64Encode(originalImageBytes),
        'texts_dict': textsDict,
        'ui_fields': uiFields.map((f) => f.toJson()).toList(),
        'signature_image_b64': signatureImageB64,
        'signature_field_id': signatureFieldId,
      }),
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw FormAnalyzerException(
        'Failed to annotate image: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  // تحويل النص لكلام
  Future<Uint8List> textToSpeech(String text) async {
    final response = await httpClient.post(
      Uri.parse('$baseUrl/form/text-to-speech'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'provider': 'gemini'
      }),
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else if (response.statusCode == 429) {
      throw QuotaExceededException('تم تجاوز الحد الأقصى لخدمة تحويل النص إلى كلام');
    } else {
      throw FormAnalyzerException(
        'Failed to convert text to speech: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  // تحويل الكلام لنص
  Future<String> speechToText(Uint8List audioBytes, String languageCode) async {
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/form/speech-to-text')
    );
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio', 
        audioBytes, 
        filename: 'audio.wav',
        contentType: MediaType('audio', 'wav'),
      )
    );
    request.fields['language_code'] = languageCode;
    
    var response = await request.send();
    var responseData = await response.stream.toBytes();
    
    if (response.statusCode == 200) {
      var result = jsonDecode(String.fromCharCodes(responseData));
      return result['text'] ?? '';
    } else if (response.statusCode == 429) {
      throw QuotaExceededException('تم تجاوز الحد الأقصى لخدمة تحويل الكلام إلى نص');
    } else {
      throw FormAnalyzerException(
        'Failed to convert speech to text: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  // حذف الجلسة
  Future<void> deleteSession(String sessionId) async {
    final response = await httpClient.delete(
      Uri.parse('$baseUrl/form/session/$sessionId'),
    );
    
    if (response.statusCode != 200) {
      throw FormAnalyzerException(
        'Failed to delete session: ${response.statusCode}',
        response.statusCode,
      );
    }
  }

  void dispose() {
    httpClient.close();
  }
}

// Data Models
class ImageQualityResult {
  final String languageDirection;
  final bool qualityGood;
  final String qualityMessage;
  final int imageWidth;
  final int imageHeight;
  final String sessionId;
  final String formExplanation;

  ImageQualityResult({
    required this.languageDirection,
    required this.qualityGood,
    required this.qualityMessage,
    required this.imageWidth,
    required this.imageHeight,
    required this.sessionId,
    required this.formExplanation,
  });

  factory ImageQualityResult.fromJson(Map<String, dynamic> json) {
    return ImageQualityResult(
      languageDirection: json['language_direction'],
      qualityGood: json['quality_good'],
      qualityMessage: json['quality_message'],
      imageWidth: json['image_width'],
      imageHeight: json['image_height'],
      sessionId: json['session_id'],
      formExplanation: json['form_explanation'] ?? '',
    );
  }
}

class FormAnalysisResult {
  final List<UIField> fields;
  final String formExplanation;
  final String languageDirection;
  final int imageWidth;
  final int imageHeight;
  final String sessionId;

  FormAnalysisResult({
    required this.fields,
    required this.formExplanation,
    required this.languageDirection,
    required this.imageWidth,
    required this.imageHeight,
    required this.sessionId,
  });

  factory FormAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FormAnalysisResult(
      fields: (json['fields'] as List)
          .map((f) => UIField.fromJson(f))
          .toList(),
      formExplanation: json['form_explanation'],
      languageDirection: json['language_direction'],
      imageWidth: json['image_width'],
      imageHeight: json['image_height'],
      sessionId: json['session_id'],
    );
  }
}

class UIField {
  final String boxId;
  final String label;
  final String type;
  final List<double>? box;

  UIField({
    required this.boxId,
    required this.label,
    required this.type,
    this.box,
  });

  factory UIField.fromJson(Map<String, dynamic> json) {
    return UIField(
      boxId: json['box_id'],
      label: json['label'],
      type: json['type'],
      box: json['box'] != null 
          ? List<double>.from(json['box'].map((x) => x.toDouble()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'box_id': boxId,
      'label': label,
      'type': type,
      'box': box,
    };
  }
}

// Exception Classes
class FormAnalyzerException implements Exception {
  final String message;
  final int statusCode;

  FormAnalyzerException(this.message, this.statusCode);

  @override
  String toString() => 'FormAnalyzerException: $message (Status: $statusCode)';
}

class QuotaExceededException extends FormAnalyzerException {
  QuotaExceededException(String message) : super(message, 429);
}
```

هذا الدليل يعطي تفاصيل كاملة لجميع الـ APIs مع أمثلة عملية لاستخدامها في Flutter. كل endpoint موثق بالكامل مع أنواع البيانات وطرق التعامل مع الأخطاء.
