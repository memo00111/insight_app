# إعداد توقيع تطبيق Android

هذه تعليمات حول كيفية إنشاء واستخدام مفتاح التوقيع لتوقيع تطبيق Sa3dne.

## إنشاء مفتاح التوقيع (مرة واحدة)

استخدم الأمر التالي لإنشاء مفتاح توقيع جديد:

```bash
keytool -genkey -v -keystore sa3dne-key.keystore -alias sa3dne -keyalg RSA -keysize 2048 -validity 10000
```

سيُطلب منك إدخال كلمة مرور والإجابة على بعض الأسئلة.

## تكوين معلومات المفتاح

قم بإنشاء ملف `key.properties` في مجلد `android/`:

```
storePassword=<كلمة مرور مخزن المفاتيح>
keyPassword=<كلمة مرور المفتاح>
keyAlias=sa3dne
storeFile=<مسار مخزن المفاتيح، مثل: ../sa3dne-key.keystore>
```

## تعديل ملف build.gradle

قم بتعديل ملف `android/app/build.gradle.kts` لاستخدام مفتاح التوقيع:

```kotlin
// أضف هذا في بداية الملف
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    // ...
    
    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String
            keyPassword = keyProperties["keyPassword"] as String
            storeFile = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## ملاحظات هامة:

1. احتفظ بملف `key.properties` و `keystore` في مكان آمن ولا تقم أبدًا بتضمينهم في نظام التحكم في الإصدارات.
2. إذا فقدت مفتاح التوقيع، لن تتمكن من تحديث تطبيقك على Google Play.
3. يجب استخدام نفس مفتاح التوقيع لجميع تحديثات التطبيق.
