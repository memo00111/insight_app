# Insight - تطبيق التحليل الذكي 🚀

<div align="center">

![Insight Logo](assets/images/logo.png)

**المساعد الذكي للتحليل والقراءة**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![API](https://img.shields.io/badge/API-Insight-green?style=for-the-badge)](https://new-reader-gsd0.onrender.com)

</div>

## 📱 نظرة عامة

**Insight** هو تطبيق فلاتر ذكي يوفر ثلاث خدمات رئيسية للتحليل والقراءة باستخدام الذكاء الاصطناعي:

### 🔍 الميزات الرئيسية

| الميزة | الوصف | الأيقونة |
|--------|---------|----------|
| **تحليل النماذج** | تحليل النماذج واستخراج الحقول القابلة للتعبئة | 📋 |
| **تحليل العملات** | تحديد نوع وقيمة العملات والأوراق النقدية | 💰 |
| **قراءة المستندات** | قراءة وتحليل ملفات PDF و PowerPoint | 📄 |

---

## 🎨 التصميم والواجهة

- ✨ **Dark Mode**: تصميم داكن احترافي
- 🌐 **RTL Support**: دعم كامل للغة العربية
- 📱 **Responsive**: واجهة متجاوبة مع جميع أحجام الشاشات
- 🎯 **Material 3**: تصميم حديث باستخدام Material Design 3
- 🔥 **Animations**: انيميشن سلس وتفاعلي

---

## 🛠️ التقنيات المستخدمة

### Frontend (Flutter)
- **Flutter 3.24+**: إطار عمل تطوير التطبيقات
- **Dart 3.1+**: لغة البرمجة
- **Provider**: إدارة الحالة
- **Dio**: HTTP client للاتصال بـ API
- **Material 3**: نظام التصميم

### المكتبات الرئيسية
```yaml
dependencies:
  dio: ^5.3.2                    # HTTP client
  provider: ^6.1.1               # State management
  image_picker: ^1.0.4           # اختيار الصور
  file_picker: ^6.1.1            # اختيار الملفات
  shared_preferences: ^2.2.2     # التخزين المحلي
  just_audio: ^0.9.36           # تشغيل الصوت
  record: ^5.0.4                # تسجيل الصوت
  path: ^1.8.3                  # التعامل مع المسارات
```

---

## 📁 هيكل المشروع

```
lib/
├── main.dart                    # نقطة دخول التطبيق
├── models/                      # نماذج البيانات
│   ├── form_analysis_response.dart
│   ├── currency_analysis_response.dart
│   └── document_response.dart
├── providers/                   # إدارة الحالة
│   └── app_provider.dart
├── screens/                     # شاشات التطبيق
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── form_analyzer_screen.dart
│   ├── money_reader_screen.dart
│   └── document_reader_screen.dart
├── services/                    # خدمات API
│   └── insight_api_service.dart
├── utils/                       # أدوات مساعدة
│   ├── app_theme.dart
│   ├── constants.dart
│   ├── storage_helper.dart
│   ├── network_helper.dart
│   └── file_helper.dart
└── widgets/                     # واجهات مشتركة
    └── common_widgets.dart
```

---

## 🚀 كيفية التشغيل

### المتطلبات الأساسية
- Flutter SDK 3.24 أو أحدث
- Dart SDK 3.1 أو أحدث
- Android Studio / VS Code
- جهاز أندرويد أو محاكي

### خطوات التشغيل

1. **استنساخ المشروع**
```bash
git clone https://github.com/your-username/insight_version_8.git
cd insight_version_8
```

2. **تثبيت المكتبات**
```bash
flutter pub get
```

3. **تشغيل التطبيق**
```bash
flutter run
```

### للنشر
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 📡 API Integration

التطبيق يتصل بـ **Insight API** المتوفر على:
- **Base URL**: `https://new-reader-gsd0.onrender.com`
- **Documentation**: [API Docs](https://new-reader-gsd0.onrender.com/docs)

### نقاط النهاية الرئيسية:

| الخدمة | النقطة | الوصف |
|--------|---------|---------|
| تحليل النماذج | `POST /form/analyze` | تحليل صورة نموذج |
| تحليل العملات | `POST /money/analyze` | تحليل صورة عملة |
| رفع مستند | `POST /document/upload` | رفع وتحليل مستند |
| تحليل صفحة | `GET /document/{id}/page/{num}` | تحليل صفحة محددة |

---

## 🔐 الصلاحيات المطلوبة

### Android
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS
```xml
<key>NSCameraUsageDescription</key>
<string>هذا التطبيق يحتاج إلى الكاميرا لتحليل النماذج والعملات</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>هذا التطبيق يحتاج إلى الوصول للمعرض لاختيار الصور</string>
<key>NSMicrophoneUsageDescription</key>
<string>هذا التطبيق يحتاج إلى الميكروفون لتحويل الكلام إلى نص</string>
```

---

## 📸 لقطات الشاشة

<div align="center">

| الشاشة الرئيسية | تحليل النماذج | تحليل العملات |
|----------------|---------------|---------------|
| ![Home](screenshots/home.png) | ![Forms](screenshots/forms.png) | ![Money](screenshots/money.png) |

| قراءة المستندات | النتائج | الإعدادات |
|-----------------|---------|----------|
| ![Documents](screenshots/documents.png) | ![Results](screenshots/results.png) | ![Settings](screenshots/settings.png) |

</div>

---

## 🔧 التكوين والإعدادات

### تخصيص الألوان
يمكنك تعديل ألوان التطبيق في `lib/utils/app_theme.dart`:

```dart
static const Color primaryColor = Color(0xFF6C63FF);
static const Color secondaryColor = Color(0xFF2ECC71);
static const Color accentColor = Color(0xFFFF6B6B);
```

### تخصيص الثوابت
تعديل الثوابت في `lib/utils/constants.dart`:

```dart
static const String baseUrl = 'https://your-api-url.com';
static const int maxImageSizeMB = 10;
static const int maxDocumentSizeMB = 50;
```

---

## 🐛 استكشاف الأخطاء

### مشاكل شائعة وحلولها

1. **خطأ في تحميل المكتبات**
```bash
flutter clean
flutter pub get
```

2. **مشاكل في الصلاحيات**
- تأكد من إضافة جميع الصلاحيات المطلوبة
- اختبر على جهاز حقيقي وليس محاكي

3. **مشاكل في الاتصال بـ API**
- تحقق من اتصال الإنترنت
- تأكد من أن API يعمل: `curl https://new-reader-gsd0.onrender.com/health`

4. **مشاكل في رفع الملفات**
- تحقق من حجم الملف (أقل من 50 ميجابايت)
- تأكد من نوع الملف المدعوم

---

## 📈 الأداء والتحسين

### نصائح لتحسين الأداء:
- ✅ استخدام `const` widgets حيثما أمكن
- ✅ ضغط الصور قبل الرفع
- ✅ إدارة الذاكرة بشكل صحيح
- ✅ استخدام lazy loading للقوائم الطويلة

### مقاييس الأداء:
- ⚡ وقت بدء التطبيق: < 3 ثواني
- 📊 استهلاك الذاكرة: < 100 ميجابايت
- 🌐 وقت الاستجابة: < 5 ثواني

---

## 🤝 المساهمة

نرحب بمساهماتكم! إليكم طريقة المساهمة:

1. Fork المشروع
2. إنشاء branch للميزة الجديدة (`git checkout -b feature/amazing-feature`)
3. Commit التغييرات (`git commit -m 'Add amazing feature'`)
4. Push إلى Branch (`git push origin feature/amazing-feature`)
5. إنشاء Pull Request

### إرشادات المساهمة:
- اتبع Flutter style guide
- أضف tests للميزات الجديدة
- وثق الكود باللغة العربية
- تأكد من عمل CI/CD

---

## 📄 الترخيص

هذا المشروع مرخص تحت رخصة MIT - انظر ملف [LICENSE](LICENSE) للتفاصيل.

---

## 👨‍💻 المطور

**Mohamed** - مطور التطبيق

- 📧 Email: [your-email@example.com](mailto:your-email@example.com)
- 💼 LinkedIn: [your-linkedin](https://linkedin.com/in/your-profile)
- 🐙 GitHub: [your-github](https://github.com/your-username)

---

## 🙏 شكر وتقدير

- Flutter Team لإطار العمل الرائع
- Material Design للتصميم الجميل
- Insight API للخدمات الذكية
- المجتمع العربي للمطورين

---

## 📞 الدعم والمساعدة

هل تحتاج مساعدة؟

- 📖 [الوثائق](docs/)
- 🐛 [تقرير خطأ](https://github.com/your-username/insight_version_8/issues)
- 💡 [طلب ميزة جديدة](https://github.com/your-username/insight_version_8/issues)
- ❓ [الأسئلة الشائعة](FAQ.md)

---

<div align="center">

**صُنع بـ ❤️ في مصر**

⭐ إذا أعجبك المشروع، لا تنس إعطاؤه نجمة!

</div>
#   i n s i g h t _ a p p  
 