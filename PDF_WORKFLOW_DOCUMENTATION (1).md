# دليل التطوير الشامل - معالجة ملفات PDF متعددة الصفحات

## نظرة عامة
هذا المستند يوضح التدفق الكامل لمعالجة ملفات PDF متعددة الصفحات في تطبيق Form Reader، بما يشمل جميع الـ endpoints والبيانات المرسلة والمستقبلة في كل مرحلة.

---

## المراحل الأساسية (5 مراحل)

### المرحلة 1: الاستكشاف (Explore)
### المرحلة 2: الشرح (Explain) 
### المرحلة 3: التحليل (Analyze)
### المرحلة 4: التعبئة (Fill)
### المرحلة 5: التحميل (Download)

---

## التدفق التفصيلي

## 🔹 المرحلة 1: استكشاف PDF

### الهدف
رفع ملف PDF والتحقق من صحته وتحويل جميع الصفحات إلى صور للمعالجة.

### Endpoint
```http
POST /form/explore-pdf
```

### Request
```javascript
// Form Data
const formData = new FormData();
formData.append('file', pdfFile); // ملف PDF
```

### Response (Success - 200)
```json
{
  "session_id": "uuid-string",
  "total_pages": 5,
  "filename": "contract.pdf", 
  "title": "عقد العمل",
  "message": "تم العثور على مستند PDF يحتوي على 5 صفحة. سنقوم أولاً بشرح محتوى كل صفحة، ثم تحليل وتعبئة النماذج.",
  "stage": "explore",
  "ready_for_explanation": true
}
```

### Response (Error)
```json
{
  "detail": "يجب أن يكون الملف من نوع PDF"
}
```

### ما يحدث في الخادم
1. فحص نوع الملف (يجب أن يكون PDF)
2. التحقق من صحة PDF
3. تحويل جميع الصفحات إلى صور
4. إنشاء جلسة جديدة وحفظ البيانات
5. إرجاع معلومات PDF الأساسية

---

## 🔹 المرحلة 2: شرح محتوى الصفحات

### الهدف
شرح محتوى كل صفحة على حدة للمستخدم بدون تحليل الحقول.

### Endpoint
```http
POST /form/explain-pdf-page
```

### Request
```javascript
// Form Data
const data = {
  session_id: "uuid-string",
  page_number: 1  // رقم الصفحة المطلوب شرحها
};
```

### Response (Success - 200)
```json
{
  "session_id": "uuid-string",
  "page_number": 1,
  "total_pages": 5,
  "explanation": "هذه الوثيقة هي مذكرة تفاهم بين طرفين، الطرف الأول والطرف الثاني، تحدد التزاماتهما المتبادلة. تتضمن المذكرة بنوداً رئيسية مثل التزام الطرف الثاني بإعداد حقائب تدريبية...",
  "language_direction": "rtl",
  "quality_good": true,
  "quality_message": "جودة الصورة جيدة",
  "has_next_page": true,
  "next_page_number": 2,
  "all_pages_explained": false,
  "image_width": 1063,
  "image_height": 1280
}
```

### كيفية الاستخدام
1. استدعي هذا الـ endpoint لكل صفحة من 1 إلى total_pages
2. اعرض الشرح للمستخدم
3. كرر للصفحة التالية حتى `all_pages_explained = true`
4. بعد الانتهاء من جميع الصفحات، انتقل للمرحلة التالية

### مثال تدفق الشرح
```javascript
// شرح الصفحة 1
POST /form/explain-pdf-page
Data: { session_id, page_number: 1 }

// شرح الصفحة 2  
POST /form/explain-pdf-page
Data: { session_id, page_number: 2 }

// ... وهكذا حتى آخر صفحة
```

---

## 🔹 المرحلة 3: تحليل الحقول القابلة للتعبئة

### الهدف
تحليل كل صفحة للبحث عن الحقول القابلة للتعبئة (مربعات النص، خانات الاختيار، إلخ).

### Endpoint  
```http
POST /form/analyze-pdf-page
```

### Request
```javascript
const data = {
  session_id: "uuid-string",
  page_number: 1
};
```

### Response - صفحة بها حقول (Success - 200)
```json
{
  "session_id": "uuid-string", 
  "page_number": 1,
  "total_pages": 5,
  "has_fields": true,
  "fields": [
    {
      "box_id": "page_1_field_1",
      "label": "الاسم الكامل", 
      "type": "text",
      "coordinates": [100, 200, 300, 230],
      "page_number": 1
    },
    {
      "box_id": "page_1_field_2",
      "label": "العنوان",
      "type": "text", 
      "coordinates": [100, 250, 300, 280],
      "page_number": 1
    },
    {
      "box_id": "page_1_field_3",
      "label": "موافق على الشروط",
      "type": "checkbox",
      "coordinates": [100, 300, 120, 320], 
      "page_number": 1
    }
  ],
  "language_direction": "rtl",
  "image_width": 1063,
  "image_height": 1280,
  "has_next_page": true,
  "next_page_number": 2,
  "all_pages_analyzed": false,
  "field_count": 3
}
```

### Response - صفحة بدون حقول
```json
{
  "session_id": "uuid-string",
  "page_number": 2, 
  "total_pages": 5,
  "has_fields": false,
  "fields": [],
  "message": "لا توجد حقول قابلة للتعبئة في هذه الصفحة",
  "has_next_page": true,
  "next_page_number": 3,
  "all_pages_analyzed": false,
  "language_direction": "rtl"
}
```

### منطق التعامل مع النتائج
```javascript
if (response.has_fields) {
  // انتقل لمرحلة التعبئة لهذه الصفحة
  startFillingPage(response.fields);
} else {
  // لا توجد حقول، انتقل للصفحة التالية
  if (response.has_next_page) {
    analyzeNextPage(response.next_page_number);
  } else {
    // انتهت جميع الصفحات
    proceedToCompletion();
  }
}
```

---

## 🔹 المرحلة 4: تعبئة الحقول

### الهدف
تعبئة الحقول التي تم اكتشافها في صفحة محددة وحفظ النتيجة.

### مرحلة فرعية: جمع البيانات من المستخدم
هذه المرحلة تحدث في التطبيق (Frontend) حيث:
1. تعرض الحقول المكتشفة للمستخدم
2. تجمع الإدخالات (نص، خانات اختيار، توقيع)
3. تحضر البيانات للإرسال

### Endpoint للتعبئة النهائية
```http
POST /form/fill-pdf-page
```

### Request
```javascript
const formData = new FormData();
formData.append('session_id', 'uuid-string');
formData.append('page_number', '1');
formData.append('texts_dict', JSON.stringify({
  'page_1_field_1': 'محمد أحمد علي',
  'page_1_field_2': 'الرياض، السعودية', 
  'page_1_field_3': 'true'  // للخانات: "true" أو "false"
}));
formData.append('signature_image_b64', base64SignatureImage); // اختياري
formData.append('signature_field_id', 'page_1_field_4'); // اختياري
```

### Response (Success - 200)
```
Content-Type: image/png
Headers:
  X-Session-ID: uuid-string
  X-Page-Number: 1
  X-Total-Pages: 5  
  X-Has-Next-Page: true
  X-Next-Page-Number: 2
  X-All-Pages-Filled: false
  X-Ready-For-Download: false

Body: [PNG image bytes] // الصفحة المعبأة كصورة
```

### منطق ما بعد التعبئة
```javascript
// قراءة الـ headers
const hasNextPage = response.headers.get('X-Has-Next-Page') === 'true';
const nextPageNumber = response.headers.get('X-Next-Page-Number');
const allPagesFilled = response.headers.get('X-All-Pages-Filled') === 'true';

if (allPagesFilled) {
  // جميع الصفحات تمت تعبئتها، انتقل للتحميل
  proceedToDownload();
} else if (hasNextPage) {
  // انتقل لتحليل الصفحة التالية
  analyzeNextPage(nextPageNumber);
} else {
  // تمت معالجة جميع الصفحات
  proceedToDownload();
}
```

---

## 🔹 المرحلة 5: تحميل PDF النهائي

### الهدف
دمج جميع الصفحات المعبأة في ملف PDF واحد وتحميله.

### Endpoint
```http
GET /form/download-filled-pdf/{session_id}
```

### Request
```javascript
const sessionId = "uuid-string";
const response = await fetch(`/form/download-filled-pdf/${sessionId}`);
```

### Response (Success - 200)
```
Content-Type: application/pdf
Headers:
  Content-Disposition: attachment; filename=contract_filled.pdf
  Content-Length: 1048576
  X-Session-ID: uuid-string
  X-Total-Pages: 5
  X-Filled-Pages: 3
  X-Original-Filename: contract.pdf

Body: [PDF file bytes]
```

### Response (Error - 400)
```json
{
  "detail": "لا توجد صفحات معبأة للتحميل"
}
```

---

## 🔹 Endpoints إضافية للمراقبة والإدارة

### 1. فحص حالة الجلسة
```http
GET /form/pdf-session-status/{session_id}
```

**Response:**
```json
{
  "session_id": "uuid-string",
  "filename": "contract.pdf",
  "total_pages": 5,
  "current_stage": "fill", 
  "current_page": 3,
  "explained_pages": 5,
  "analyzed_pages": 3,
  "filled_pages": 2,
  "language_direction": "rtl",
  "ready_for_download": false
}
```

### 2. حذف الجلسة
```http
DELETE /form/pdf-session/{session_id}
```

**Response:**
```json
{
  "message": "تم حذف جلسة PDF uuid-string بنجاح",
  "session_id": "uuid-string", 
  "had_pages": 5
}
```

---

## 🔄 مخطط التدفق الكامل

```
1. POST /form/explore-pdf
   ↓ (store session_id, total_pages)
   
2. Loop: POST /form/explain-pdf-page (for each page 1..N)
   ↓ (display explanations to user)
   
3. Loop: POST /form/analyze-pdf-page (for each page 1..N)
   ↓ (if has_fields → collect user input)
   ↓ (if no fields → skip to next page)
   
4. POST /form/fill-pdf-page (for pages with fields)
   ↓ (repeat for all pages with fields)
   
5. GET /form/download-filled-pdf/{session_id}
   ↓ (download complete PDF)
   
6. DELETE /form/pdf-session/{session_id} (cleanup)
```

---

## 🎯 نصائح مهمة للمطور

### 1. إدارة الحالة (State Management)
```javascript
const pdfState = {
  sessionId: null,
  currentStage: 'explore', // explore|explain|analyze|fill|download
  currentPage: 1,
  totalPages: 0,
  explainedPages: [],
  analyzedPages: [],
  filledPages: {},
  userInputs: {} // بيانات المستخدم لكل صفحة
};
```

### 2. معالجة الأخطاء
```javascript
try {
  const response = await api.call();
  if (response.status === 200) {
    // نجح
  } else {
    showError(response.data.detail);
  }
} catch (error) {
  showError('خطأ في الاتصال بالخادم');
}
```

### 3. أنواع الحقول المدعومة
- `text`: مربع نص
- `checkbox`: خانة اختيار  
- `signature`: حقل توقيع

### 4. التحقق من البيانات
```javascript
// للحقول النصية
if (fieldType === 'text' && value.trim().length === 0) {
  // حقل فارغ
}

// لخانات الاختيار  
if (fieldType === 'checkbox') {
  value = userChecked ? 'true' : 'false';
}

// للتوقيع
if (fieldType === 'signature' && hasSignatureImage) {
  // تحويل الصورة إلى base64
}
```

### 5. Progress Tracking
```javascript
const progress = {
  explained: explainedPages.length / totalPages * 100,
  analyzed: analyzedPages.length / totalPages * 100, 
  filled: Object.keys(filledPages).length / totalPages * 100
};
```

---

## 🚨 حالات الخطأ الشائعة

### 1. ملف غير صالح
```json
{
  "detail": "يجب أن يكون الملف من نوع PDF"
}
```

### 2. جلسة منتهية الصلاحية
```json
{
  "detail": "جلسة PDF غير موجودة أو منتهية الصلاحية"
}
```

### 3. صفحة غير صحيحة
```json
{
  "detail": "رقم صفحة غير صحيح. يجب أن يكون بين 1 و 5"
}
```

### 4. لا توجد صفحات للتحميل
```json
{
  "detail": "لا توجد صفحات معبأة للتحميل"
}
```

---

## 📝 مثال كود Flutter أساسي

```dart
class PDFProcessor {
  String? sessionId;
  int totalPages = 0;
  int currentPage = 1;
  String currentStage = 'explore';
  
  // المرحلة 1: الاستكشاف
  Future<bool> explorePDF(File pdfFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/form/explore-pdf'));
    request.files.add(await http.MultipartFile.fromPath('file', pdfFile.path));
    
    var response = await request.send();
    if (response.statusCode == 200) {
      var data = json.decode(await response.stream.bytesToString());
      sessionId = data['session_id'];
      totalPages = data['total_pages'];
      currentStage = 'explain';
      return true;
    }
    return false;
  }
  
  // المرحلة 2: الشرح
  Future<String?> explainPage(int pageNumber) async {
    var response = await http.post(
      Uri.parse('$baseUrl/form/explain-pdf-page'),
      body: {
        'session_id': sessionId!,
        'page_number': pageNumber.toString(),
      }
    );
    
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['explanation'];
    }
    return null;
  }
  
  // المرحلة 3: التحليل
  Future<List<dynamic>?> analyzePage(int pageNumber) async {
    var response = await http.post(
      Uri.parse('$baseUrl/form/analyze-pdf-page'),
      body: {
        'session_id': sessionId!,
        'page_number': pageNumber.toString(),
      }
    );
    
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['has_fields']) {
        return data['fields'];
      }
    }
    return null;
  }
  
  // المرحلة 4: التعبئة
  Future<Uint8List?> fillPage(int pageNumber, Map<String, String> texts) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/form/fill-pdf-page'));
    request.fields['session_id'] = sessionId!;
    request.fields['page_number'] = pageNumber.toString();
    request.fields['texts_dict'] = json.encode(texts);
    
    var response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.toBytes();
    }
    return null;
  }
  
  // المرحلة 5: التحميل
  Future<Uint8List?> downloadPDF() async {
    var response = await http.get(
      Uri.parse('$baseUrl/form/download-filled-pdf/$sessionId')
    );
    
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }
}
```

---

## ✅ Checklist للمطور

- [ ] تنفيذ المراحل الخمس بالترتيب الصحيح
- [ ] إدارة session_id بشكل صحيح
- [ ] معالجة الأخطاء في كل endpoint
- [ ] عرض progress indicator للمستخدم
- [ ] تخزين بيانات المستخدم محلياً قبل الإرسال
- [ ] التحقق من صحة البيانات قبل الإرسال
- [ ] تنظيف الجلسة بعد الانتهاء
- [ ] دعم أنواع الحقول المختلفة (text, checkbox, signature)
- [ ] التعامل مع الصفحات التي لا تحتوي على حقول
- [ ] عرض معاينة للصفحات المعبأة

---

هذا المستند يحتوي على جميع المعلومات اللازمة لتطوير تطبيق Flutter يتعامل مع معالجة PDF متعددة الصفحات. في حالة وجود أي استفسارات إضافية، يرجى الرجوع إلى كود `ui.py` و `form_analyzer.py` للتفاصيل الإضافية.

---

## 🖥️ واجهة المستخدم (UI) - ما يراه المستخدم

### 📱 المرحلة 1: رفع الملف وبدء الاستكشاف

**ما يراه المستخدم:**
```
┌─────────────────────────────────┐
│  📄 رفع ملف PDF للتحليل        │
├─────────────────────────────────┤
│  [اختر ملف PDF]  📁           │
│                                 │
│  ✅ الملف المختار:              │
│  📄 contract.pdf (2.5 MB)      │
│                                 │
│  [🚀 بدء المعالجة]             │
└─────────────────────────────────┘
```

**أثناء المعالجة:**
```
┌─────────────────────────────────┐
│  ⏳ جاري استكشاف ملف PDF...    │
│                                 │
│  🔄 [██████████████████] 100%  │
│                                 │
│  ✅ تم العثور على 5 صفحات     │
│  📋 سنبدأ بشرح كل صفحة أولاً   │
└─────────────────────────────────┘
```

---

### 📱 المرحلة 2: شرح الصفحات

**ما يراه المستخدم:**
```
┌─────────────────────────────────┐
│  📖 مرحلة الشرح                │
│  الصفحة 1 من 5                │
├─────────────────────────────────┤
│  💡 شرح المحتوى:               │
│                                 │
│  "هذه الوثيقة هي مذكرة تفاهم   │
│   بين طرفين، الطرف الأول       │
│   والطرف الثاني، تحدد التزاماتهما │
│   المتبادلة..."                │
│                                 │
│  🔊 [تشغيل صوتي] 📢            │
│                                 │
│  [➡️ الصفحة التالية]           │
└─────────────────────────────────┘
```

**بعد شرح جميع الصفحات:**
```
┌─────────────────────────────────┐
│  ✅ تم شرح جميع الصفحات        │
├─────────────────────────────────┤
│  📊 ملخص:                      │
│  • الصفحة 1: مذكرة تفاهم       │
│  • الصفحة 2: بنود الاتفاقية    │
│  • الصفحة 3: الالتزامات        │
│  • الصفحة 4: شروط التعديل      │
│  • الصفحة 5: التوقيعات         │
│                                 │
│  [🔍 بدء تحليل الحقول]         │
└─────────────────────────────────┘
```

---

### 📱 المرحلة 3: تحليل الحقول

**أثناء التحليل:**
```
┌─────────────────────────────────┐
│  🔍 تحليل الصفحة 1 من 5        │
├─────────────────────────────────┤
│  ⏳ جاري البحث عن الحقول...    │
│                                 │
│  🔄 [████████░░░░░░░] 60%       │
│                                 │
│  📋 تقدم التحليل:              │
│  ✅ صفحة 1: 3 حقول            │
│  ✅ صفحة 2: لا توجد حقول       │
│  🔄 صفحة 3: جاري التحليل...    │
└─────────────────────────────────┘
```

**نتائج التحليل:**
```
┌─────────────────────────────────┐
│  📋 تم العثور على حقول قابلة   │
│      للتعبئة في الصفحة 1       │
├─────────────────────────────────┤
│  🏷️ الحقول المكتشفة:           │
│                                 │
│  1️⃣ الاسم الكامل              │
│  2️⃣ المسمى الوظيفي            │
│  3️⃣ ☑️ موافق على الشروط      │
│  4️⃣ ✍️ التوقيع               │
│                                 │
│  [📝 بدء التعبئة]              │
└─────────────────────────────────┘
```

---

### 📱 المرحلة 4: تعبئة الحقول

**واجهة التعبئة:**
```
┌─────────────────────────────────┐
│  📝 تعبئة الصفحة 1 من 5        │
│  الحقل 1 من 4                 │
├─────────────────────────────────┤
│  🏷️ الاسم الكامل:              │
│                                 │
│  🎤 [تسجيل صوتي] أو اكتب:      │
│  ┌─────────────────────────────┐ │
│  │ محمد أحمد علي               │ │
│  └─────────────────────────────┘ │
│                                 │
│  🔊 سمعتك تقول: "محمد أحمد علي" │
│                                 │
│  [✅ تأكيد] [🔄 إعادة المحاولة] │
│  [⏭️ تخطي هذا الحقل]           │
└─────────────────────────────────┘
```

**تعبئة خانة اختيار:**
```
┌─────────────────────────────────┐
│  📝 تعبئة الصفحة 1 من 5        │
│  الحقل 3 من 4                 │
├─────────────────────────────────┤
│  ☑️ موافق على الشروط:          │
│                                 │
│  🎤 هل تريد تحديد هذه الخانة؟   │
│      قل "نعم" أو "لا"          │
│                                 │
│  🔊 سمعتك تقول: "نعم"          │
│                                 │
│  ✅ سيتم تحديد الخانة           │
│                                 │
│  [✅ تأكيد] [🔄 إعادة المحاولة] │
└─────────────────────────────────┘
```

**تعبئة التوقيع:**
```
┌─────────────────────────────────┐
│  📝 تعبئة الصفحة 1 من 5        │
│  الحقل 4 من 4                 │
├─────────────────────────────────┤
│  ✍️ حقل التوقيع:               │
│                                 │
│  📷 ارفع صورة توقيعك:          │
│  [📁 اختيار صورة]               │
│                                 │
│  أو                             │
│                                 │
│  ✏️ ارسم توقيعك:               │
│  ┌─────────────────────────────┐ │
│  │        [منطقة الرسم]        │ │
│  │                             │ │
│  └─────────────────────────────┘ │
│  [🗑️ مسح] [✅ حفظ التوقيع]     │
└─────────────────────────────────┘
```

**مراجعة قبل الحفظ:**
```
┌─────────────────────────────────┐
│  👀 مراجعة البيانات - الصفحة 1  │
├─────────────────────────────────┤
│  📝 البيانات المدخلة:           │
│                                 │
│  • الاسم: محمد أحمد علي         │
│  • المسمى: مطور برمجيات         │
│  • موافق على الشروط: ✅ نعم    │
│  • التوقيع: ✍️ تم الرفع        │
│                                 │
│  [✅ حفظ وإنهاء هذه الصفحة]     │
│  [✏️ تعديل البيانات]           │
└─────────────────────────────────┘
```

---

### 📱 المرحلة 5: التحميل والانتهاء

**حالة الانتهاء من جميع الصفحات:**
```
┌─────────────────────────────────┐
│  🎉 تم الانتهاء من جميع الصفحات │
├─────────────────────────────────┤
│  📊 ملخص العمل:                │
│                                 │
│  ✅ صفحات تمت تعبئتها: 3       │
│  📄 صفحات بدون حقول: 2         │
│  📝 إجمالي الحقول: 8           │
│                                 │
│  🔄 جاري إنشاء ملف PDF...       │
│                                 │
│  [██████████████████] 100%      │
│                                 │
│  [📥 تحميل PDF المعبأ]          │
└─────────────────────────────────┘
```

**بعد التحميل بنجاح:**
```
┌─────────────────────────────────┐
│  ✅ تم تحميل الملف بنجاح!       │
├─────────────────────────────────┤
│  📄 اسم الملف:                 │
│  contract_filled.pdf            │
│                                 │
│  💾 تم الحفظ في مجلد التحميل   │
│                                 │
│  [🔄 معالجة ملف جديد]           │
│  [🏠 العودة للرئيسية]          │
└─────────────────────────────────┘
```

---

## 🔊 التفاعل الصوتي (Voice Interaction)

### ما يسمعه المستخدم في كل مرحلة:

**🔊 المرحلة 1 - الاستكشاف:**
```
"تم العثور على مستند PDF يحتوي على 5 صفحة. سنقوم أولاً بشرح محتوى كل صفحة، ثم تحليل وتعبئة النماذج."
```

**🔊 المرحلة 2 - الشرح:**
```
"هذه الوثيقة هي مذكرة تفاهم بين طرفين، الطرف الأول والطرف الثاني، تحدد التزاماتهما المتبادلة. تتضمن المذكرة بنوداً رئيسية..."
```

**🔊 المرحلة 3 - التحليل:**
```
"تم العثور على 3 حقول قابلة للتعبئة في هذه الصفحة. سنبدأ الآن بتعبئتها واحداً تلو الآخر."
```

**🔊 المرحلة 4 - التعبئة:**
```
"أدخل البيانات الخاصة بـ 'الاسم الكامل'"
"سمعتك تقول 'محمد أحمد علي'. هل هذا صحيح؟"
"تم حفظ البيانات. الانتقال للحقل التالي."
```

**🔊 المرحلة 5 - الانتهاء:**
```
"تم الانتهاء من جميع الصفحات. يمكنك الآن تحميل ملف PDF الكامل المعبأ."
```

---

## 📱 شاشات الأخطاء والتحذيرات

**خطأ في رفع الملف:**
```
┌─────────────────────────────────┐
│  ❌ خطأ في رفع الملف           │
├─────────────────────────────────┤
│  🚫 يجب أن يكون الملف من نوع    │
│     PDF فقط                    │
│                                 │
│  💡 تأكد من أن الملف:          │
│  • بصيغة PDF                   │
│  • حجمه أقل من 50 ميجابايت     │
│  • غير تالف                    │
│                                 │
│  [🔄 المحاولة مرة أخرى]        │
└─────────────────────────────────┘
```

**مشكلة في جودة الصورة:**
```
┌─────────────────────────────────┐
│  ⚠️ تحذير - جودة منخفضة        │
├─────────────────────────────────┤
│  📸 جودة الصورة في هذه الصفحة  │
│     منخفضة، قد يؤثر على دقة     │
│     التحليل                     │
│                                 │
│  🤔 هل تريد المتابعة؟          │
│                                 │
│  [✅ نعم، متابعة]               │
│  [📷 تحسين الجودة]             │
└─────────────────────────────────┘
```

**انقطاع الاتصال:**
```
┌─────────────────────────────────┐
│  🌐 مشكلة في الاتصال           │
├─────────────────────────────────┤
│  📡 لا يمكن الوصول للخادم      │
│                                 │
│  🔄 جاري إعادة المحاولة...     │
│                                 │
│  ⏳ المحاولة 2 من 3            │
│                                 │
│  [🔄 إعادة المحاولة يدوياً]    │
│  [💾 حفظ التقدم محلياً]        │
└─────────────────────────────────┘
```

---

## 🎮 عناصر التحكم والتنقل

### أزرار التحكم الأساسية:
```
🏠 [الرئيسية]     🔙 [رجوع]      ⏸️ [إيقاف مؤقت]
🔊 [تشغيل صوتي]   🔇 [كتم الصوت]   ⚙️ [الإعدادات]
📱 [وضع الهاتف]   🖥️ [وضع الحاسوب] 🌙 [الوضع الليلي]
```

### شريط التقدم العام:
```
┌─────────────────────────────────┐
│  📊 التقدم العام:              │
│                                 │
│  🔍 الاستكشاف   ✅ مكتمل        │
│  📖 الشرح       ✅ مكتمل        │
│  🔍 التحليل     🔄 جاري العمل   │
│  📝 التعبئة     ⏳ في الانتظار  │
│  📥 التحميل     ⏳ في الانتظار  │
│                                 │
│  [████████████░░░░░] 60%        │
└─────────────────────────────────┘
```

---

## 🎯 إرشادات للمطور - جانب UI

### 1. تصميم الواجهات (Responsive Design)
```dart
// شاشة صغيرة (موبايل)
if (screenWidth < 600) {
  return MobileLayout();
}
// شاشة متوسطة (تابلت)
else if (screenWidth < 1200) {
  return TabletLayout(); 
}
// شاشة كبيرة (حاسوب)
else {
  return DesktopLayout();
}
```

### 2. إدارة التفاعل الصوتي
```dart
class VoiceManager {
  bool voiceEnabled = true;
  
  Future<void> speak(String text) async {
    if (voiceEnabled) {
      await tts.speak(text);
    }
  }
  
  Future<String?> listen() async {
    if (hasPermission) {
      return await stt.listen();
    }
    return null;
  }
}
```

### 3. حفظ التقدم محلياً
```dart
class ProgressManager {
  Future<void> saveProgress(PDFSession session) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString('current_session', json.encode(session.toJson()));
    });
  }
  
  Future<PDFSession?> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString('current_session');
    if (sessionData != null) {
      return PDFSession.fromJson(json.decode(sessionData));
    }
    return null;
  }
}
```

### 4. معالجة الحالات الاستثنائية في UI
```dart
Widget buildErrorWidget(String error) {
  return Card(
    color: Colors.red[50],
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error, color: Colors.red, size: 48),
          SizedBox(height: 16),
          Text(error, style: TextStyle(color: Colors.red)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => retry(),
            child: Text("إعادة المحاولة"),
          ),
        ],
      ),
    ),
  );
}
```

### 5. مؤشرات التحميل والتقدم
```dart
Widget buildProgressIndicator(double progress, String stage) {
  return Column(
    children: [
      LinearProgressIndicator(value: progress),
      SizedBox(height: 8),
      Text("$stage - ${(progress * 100).toInt()}%"),
      if (progress == 1.0) 
        Icon(Icons.check_circle, color: Colors.green),
    ],
  );
}
```

---

## 🔗 ربط UI مع Backend

### نموذج تدفق البيانات:
```
UI Layer ↔️ State Manager ↔️ API Service ↔️ Backend
    ↓              ↓              ↓           ↓
 Widgets    Provider/Bloc    HTTP Client   FastAPI
```

### مثال ربط كامل:
```dart
class PDFFormScreen extends StatefulWidget {
  @override
  _PDFFormScreenState createState() => _PDFFormScreenState();
}

class _PDFFormScreenState extends State<PDFFormScreen> {
  final PDFProcessor processor = PDFProcessor();
  String currentStage = 'upload';
  
  @override
  Widget build(BuildContext context) {
    switch (currentStage) {
      case 'upload':
        return buildUploadUI();
      case 'explore':
        return buildExploreUI();
      case 'explain':
        return buildExplainUI();
      case 'analyze':
        return buildAnalyzeUI();
      case 'fill':
        return buildFillUI();
      case 'download':
        return buildDownloadUI();
      default:
        return buildErrorUI();
    }
  }
  
  Widget buildUploadUI() {
    return Column(
      children: [
        Text("رفع ملف PDF للتحليل"),
        ElevatedButton(
          onPressed: pickAndUploadFile,
          child: Text("اختر ملف PDF"),
        ),
      ],
    );
  }
  
  Future<void> pickAndUploadFile() async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (file != null) {
      setState(() => currentStage = 'explore');
      final success = await processor.explorePDF(File(file.files.first.path!));
      if (success) {
        setState(() => currentStage = 'explain');
      }
    }
  }
}
```

---
