# دليل المطور Flutter - تطبيق قارئ النماذج

## نظرة عامة على المشروع

هذا المشروع عبارة عن تطبيق ذكي لقراءة وتعبئة النماذج للمكفوفين وضعاف البصر، يتكون من:
- **Backend API**: FastAPI يعمل على `http://127.0.0.1:8000`
- **Frontend UI**: Streamlit (للمرجع فقط - ستحتاج لإعادة بنائه في Flutter)

## الخدمات المتوفرة

### 1. خدمة Form Analyzer (الأساسية)
- **المسار**: `/form`
- **الوظيفة**: تحليل النماذج واستخراج الحقول القابلة للتعبئة
- **اللغات**: العربية والإنجليزية

### 2. خدمة Money Reader
- **المسار**: `/money`
- **الوظيفة**: قراءة العملات بالصوت

### 3. خدمة Document Reader
- **المسار**: `/document`
- **الوظيفة**: قراءة ملفات PowerPoint و PDF

---

## سير العمل في التطبيق (Form Analyzer)

### المرحلة 1: رفع الصورة وفحص الجودة
```
المستخدم يرفع صورة → فحص الجودة → كشف اللغة → إنشاء جلسة
```

**API Endpoint**: `POST /form/check-image`

**الطلب**:
```
Content-Type: multipart/form-data
file: [image file]
```

**الرد**:
```json
{
  "language_direction": "rtl", // أو "ltr"
  "quality_good": true,
  "quality_message": "Image quality is good",
  "image_width": 1200,
  "image_height": 800,
  "session_id": "uuid-string",
  "form_explanation": "هذا نموذج طلب..."
}
```

### المرحلة 2: تحليل النموذج
```
تحليل الصورة → استخراج الحقول → إنشاء خريطة الحقول
```

**API Endpoint**: `POST /form/analyze-form`

**الطلب**:
```
Content-Type: multipart/form-data
file: [image file]
session_id: [من المرحلة الأولى]
language_direction: [اختياري]
```

**الرد**:
```json
{
  "fields": [
    {
      "box_id": "field_1",
      "label": "الاسم الكامل",
      "type": "text",
      "box": [150.5, 200.3, 300.0, 40.0]
    },
    {
      "box_id": "field_2", 
      "label": "هل أنت متزوج؟",
      "type": "checkbox",
      "box": [150.5, 250.3, 20.0, 20.0]
    },
    {
      "box_id": "field_3",
      "label": "التوقيع",
      "type": "text",
      "box": [150.5, 300.3, 200.0, 50.0]
    }
  ],
  "form_explanation": "",
  "language_direction": "rtl",
  "image_width": 1200,
  "image_height": 800,
  "session_id": "uuid-string"
}
```

### المرحلة 3: ملء الحقول واحد تلو الآخر

**تدفق العمل**:
1. عرض الحقل الحالي
2. تشغيل الصوت (إرشادات)
3. انتظار إدخال المستخدم (صوت أو نص)
4. تأكيد البيانات
5. الانتقال للحقل التالي
6. تحديث المعاينة المباشرة

**أنواع الحقول**:
- **نص**: `"type": "text"` - إدخال نصي أو صوتي
- **خانة اختيار**: `"type": "checkbox"` - نعم/لا
- **توقيع**: يتم كشفه بالكلمات: "توقيع", "signature", "امضاء"

### المرحلة 4: المعاينة المباشرة
```
تحديث البيانات → إرسال للـ API → استقبال صورة محدثة
```

**API Endpoint**: `POST /form/annotate-image`

**الطلب**:
```json
{
  "original_image_b64": "base64-encoded-image",
  "texts_dict": {
    "field_1": "أحمد محمد",
    "field_2": true,
    "field_3": ""
  },
  "ui_fields": [/* array of fields */],
  "signature_image_b64": "base64-encoded-signature", // للتوقيع
  "signature_field_id": "field_3" // معرف حقل التوقيع
}
```

**الرد**: صورة PNG محدثة

### المرحلة 5: التحميل النهائي
- تحميل كـ PNG
- تحميل كـ PDF

---

## التفاصيل التقنية للتطبيق

### 1. إدارة الحالة (State Management)

**البيانات المطلوب تخزينها**:
```dart
class FormState {
  String? sessionId;
  String languageDirection; // "rtl" أو "ltr"
  List<FormField> fields;
  Map<String, dynamic> formData;
  int currentFieldIndex;
  String conversationStage; // "filling_fields", "confirmation", "review"
  Uint8List? originalImageBytes;
  String? annotatedImageB64;
  bool voiceEnabled;
  String? signatureB64;
  String? signatureFieldId;
}

class FormField {
  String boxId;
  String label;
  String type;
  List<double>? box; // [x, y, width, height]
}
```

### 2. إدارة الصوت

**Text-to-Speech (TTS)**:
```dart
// Package: flutter_tts
FlutterTts flutterTts = FlutterTts();

Future<void> speak(String text) async {
  await flutterTts.setLanguage("ar-SA"); // للعربية
  await flutterTts.speak(text);
}
```

**Speech-to-Text (STT)**:
```dart
// Package: speech_to_text
SpeechToText speech = SpeechToText();

Future<String?> listenForSpeech() async {
  if (await speech.initialize()) {
    return await speech.listen(
      localeId: "ar-SA", // للعربية
    );
  }
  return null;
}
```

**API للصوت**:
```dart
// تحويل النص لصوت
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
  }
  return null;
}

// تحويل الصوت لنص  
Future<String?> speechToText(Uint8List audioBytes, String langCode) async {
  var request = http.MultipartRequest(
    'POST', 
    Uri.parse('$baseUrl/form/speech-to-text')
  );
  
  request.files.add(
    http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav')
  );
  request.fields['language_code'] = langCode;
  
  var response = await request.send();
  if (response.statusCode == 200) {
    var responseData = await response.stream.toBytes();
    var result = jsonDecode(String.fromCharCodes(responseData));
    return result['text'];
  }
  return null;
}
```

### 3. رفع ومعالجة الصور

```dart
// Package: image_picker
final ImagePicker picker = ImagePicker();

Future<File?> pickImage() async {
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  return image != null ? File(image.path) : null;
}

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
  return null;
}

Future<Map<String, dynamic>?> analyzeForm(
  File imageFile, 
  String sessionId,
  String? languageDirection
) async {
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
  if (response.statusCode == 200) {
    var responseData = await response.stream.toBytes();
    return jsonDecode(String.fromCharCodes(responseData));
  }
  return null;
}
```

### 4. معالجة أنواع الحقول المختلفة

```dart
Widget buildFieldInput(FormField field) {
  switch (field.type) {
    case 'checkbox':
      return buildCheckboxField(field);
    case 'text':
      if (isSignatureField(field.label)) {
        return buildSignatureField(field);
      }
      return buildTextField(field);
    default:
      return buildTextField(field);
  }
}

bool isSignatureField(String label) {
  List<String> signatureKeywords = [
    'توقيع', 'التوقيع', 'امضاء', 'الامضاء',
    'signature', 'sign', 'signed'
  ];
  
  return signatureKeywords.any((keyword) => 
    label.toLowerCase().contains(keyword.toLowerCase())
  );
}

Widget buildSignatureField(FormField field) {
  return Column(
    children: [
      Text('ارفع صورة توقيعك هنا'),
      ElevatedButton(
        onPressed: () async {
          final image = await pickImage();
          if (image != null) {
            final bytes = await image.readAsBytes();
            final base64String = base64Encode(bytes);
            
            setState(() {
              signatureB64 = base64String;
              signatureFieldId = field.boxId;
            });
            
            await updateLiveImage();
          }
        },
        child: Text('رفع التوقيع'),
      ),
    ],
  );
}

Widget buildTextField(FormField field) {
  return Column(
    children: [
      Text(field.label),
      
      // زر الصوت
      ElevatedButton(
        onPressed: () => startVoiceInput(field),
        child: Text('اضغط للتحدث'),
      ),
      
      // إدخال نصي
      TextField(
        onChanged: (value) {
          formData[field.boxId] = value;
          updateLiveImage();
        },
        decoration: InputDecoration(
          hintText: 'أو اكتب هنا...',
        ),
      ),
    ],
  );
}

Widget buildCheckboxField(FormField field) {
  return Column(
    children: [
      Text('هل تريد تحديد خانة "${field.label}"؟'),
      
      // زر الصوت
      ElevatedButton(
        onPressed: () => startVoiceInputForCheckbox(field),
        child: Text('اضغط للتحدث'),
      ),
      
      // خانة اختيار
      CheckboxListTile(
        title: Text(field.label),
        value: formData[field.boxId] ?? false,
        onChanged: (value) {
          setState(() {
            formData[field.boxId] = value ?? false;
          });
          updateLiveImage();
        },
      ),
    ],
  );
}
```

### 5. تحديث المعاينة المباشرة

```dart
Future<void> updateLiveImage() async {
  if (originalImageBytes == null) return;
  
  final response = await http.post(
    Uri.parse('$baseUrl/form/annotate-image'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'original_image_b64': base64Encode(originalImageBytes!),
      'texts_dict': formData,
      'ui_fields': fields.map((f) => f.toJson()).toList(),
      'signature_image_b64': signatureB64,
      'signature_field_id': signatureFieldId,
    }),
  );
  
  if (response.statusCode == 200) {
    setState(() {
      annotatedImageB64 = base64Encode(response.bodyBytes);
    });
  }
}
```

---

## واجهة المستخدم (UI Design)

### الشاشات المطلوبة:

1. **شاشة البداية**
   - زر رفع الصورة
   - تبديل الصوت (enable/disable)

2. **شاشة فحص الجودة**
   - عرض نتائج فحص الجودة
   - زر المتابعة

3. **شاشة تحليل النموذج**
   - مؤشر التحميل
   - رسالة "جاري تحليل النموذج..."

4. **شاشة ملء الحقول**
   - عرض الحقل الحالي
   - زر الصوت
   - مدخل نصي
   - أزرار: حفظ ومتابعة / تخطي
   - معاينة النموذج

5. **شاشة التأكيد**
   - عرض ما تم سماعه
   - أزرار: تأكيد / إعادة المحاولة

6. **شاشة المراجعة النهائية**
   - المعاينة النهائية
   - أزرار التحميل (PNG/PDF)

### تخطيط الشاشة المقترح:

```
┌─────────────────────────────┐
│       Header (عنوان)        │
├─────────────────────────────┤
│                             │
│    معاينة النموذج           │
│    (النصف العلوي)           │
│                             │
├─────────────────────────────┤
│ الحقل الحالي: "الاسم الكامل" │
├─────────────────────────────┤
│  🎤 اضغط للتحدث            │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │   مدخل نصي             │ │
│ └─────────────────────────┘ │
├─────────────────────────────┤
│ [حفظ ومتابعة]  [تخطي]      │
└─────────────────────────────┘
```

---

## حالات الأخطاء والتعامل معها

### 1. أخطاء الشبكة
```dart
try {
  final response = await http.post(/* ... */);
  if (response.statusCode == 200) {
    // نجح
  } else if (response.statusCode == 429) {
    // تجاوز الحد الأقصى
    showError("تم تجاوز الحد الأقصى للاستخدام");
  } else {
    showError("خطأ في الخادم: ${response.statusCode}");
  }
} catch (e) {
  showError("خطأ في الاتصال: $e");
}
```

### 2. أخطاء الصوت
```dart
// إذا فشل STT
if (transcript == null || transcript.isEmpty) {
  showError("لم أتمكن من فهم الصوت. حاول مرة أخرى");
  return;
}

// إذا فشل TTS
if (audioBytes == null) {
  // تشغيل نص بديل أو تجاهل
  print("فشل في تشغيل الصوت");
}
```

### 3. أخطاء رفع الصور
```dart
if (imageFile == null) {
  showError("لم يتم اختيار صورة");
  return;
}

// فحص حجم الملف
if (await imageFile.length() > 10 * 1024 * 1024) { // 10MB
  showError("حجم الصورة كبير جداً");
  return;
}
```

---

## إعدادات التطبيق

### المتغيرات المطلوبة:
```dart
class AppConfig {
  static const String baseUrl = "http://127.0.0.1:8000";
  static const int sessionTimeout = 3600; // ثانية
  static const List<String> supportedImageTypes = [
    'jpg', 'jpeg', 'png', 'bmp', 'pdf'
  ];
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
}
```

### إعدادات الصوت:
```dart
class VoiceSettings {
  static const String arabicLocale = "ar-SA";
  static const String englishLocale = "en-US";
  static const double speechRate = 0.5;
  static const double speechVolume = 1.0;
}
```

---

## الحزم المطلوبة (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP requests
  http: ^1.1.0
  
  # Image handling
  image_picker: ^1.0.4
  image: ^4.1.3
  
  # Audio
  flutter_tts: ^3.8.5
  speech_to_text: ^6.6.0
  
  # File operations
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  
  # State management
  provider: ^6.1.1
  # أو
  bloc: ^8.1.2
  
  # UI
  flutter_staggered_animations: ^1.1.1
  
  # Utilities
  permission_handler: ^11.0.1
```

---

## نصائح للتطوير

### 1. إدارة الحالة
- استخدم Provider أو Bloc لإدارة حالة النموذج
- اعمل نسخ احتياطية من البيانات محلياً

### 2. تجربة المستخدم
- أضف مؤشرات تحميل واضحة
- قدم ردود فعل صوتية ونصية
- اعمل واجهة بسيطة ومفهومة

### 3. الأداء
- ضغط الصور قبل الإرسال
- اعمل cache للصوتيات المكررة
- استخدم الـ pagination للحقول الكثيرة

### 4. إمكانية الوصول
- أضف semantic labels لجميع العناصر
- اجعل جميع الوظائف متاحة بالصوت
- ادعم screen readers

### 5. الأمان
- لا تحفظ API keys في الكود
- استخدم HTTPS فقط
- اعمل validation للمدخلات

---

## مثال لكود أساسي

```dart
class FormFillerApp extends StatefulWidget {
  @override
  _FormFillerAppState createState() => _FormFillerAppState();
}

class _FormFillerAppState extends State<FormFillerApp> {
  final FormService _formService = FormService();
  FormState _formState = FormState();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قارئ النماذج'),
        actions: [
          Switch(
            value: _formState.voiceEnabled,
            onChanged: (value) {
              setState(() {
                _formState.voiceEnabled = value;
              });
            },
          ),
        ],
      ),
      body: _buildCurrentScreen(),
    );
  }
  
  Widget _buildCurrentScreen() {
    switch (_formState.conversationStage) {
      case 'start':
        return ImageUploadScreen(
          onImageSelected: _handleImageUpload,
        );
      case 'filling_fields':
        return FieldFillingScreen(
          formState: _formState,
          onFieldUpdate: _handleFieldUpdate,
        );
      case 'confirmation':
        return ConfirmationScreen(
          formState: _formState,
          onConfirm: _handleConfirmation,
        );
      case 'review':
        return ReviewScreen(
          formState: _formState,
          onDownload: _handleDownload,
        );
      default:
        return ImageUploadScreen(
          onImageSelected: _handleImageUpload,
        );
    }
  }
  
  Future<void> _handleImageUpload(File imageFile) async {
    // تنفيذ رفع وتحليل الصورة
  }
  
  // باقي الدوال...
}
```

---

هذا الدليل يغطي جميع جوانب المشروع التي تحتاجها لبناء تطبيق Flutter مطابق تماماً للـ Streamlit UI. كل API endpoint موثق بالتفصيل مع أمثلة الكود والتعامل مع الحالات المختلفة.
