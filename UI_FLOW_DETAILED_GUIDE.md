# مخطط سير العمل UI Flow - تطبيق قارئ النماذج

## نظرة عامة على مراحل التطبيق

```
البداية → رفع الصورة → فحص الجودة → تحليل النموذج → ملء الحقول → المراجعة → التحميل
   ↓           ↓            ↓             ↓            ↓           ↓          ↓
شاشة 1    شاشة 2      شاشة 3        شاشة 4     شاشة 5      شاشة 6    شاشة 7
```

---

## 📱 الشاشات بالتفصيل

### شاشة 1: البداية (Start Screen)

**الحالة**: `conversationStage = "start"`

**العناصر**:
```
┌─────────────────────────────────────┐
│            قارئ النماذج             │  ← Header
├─────────────────────────────────────┤
│  🔊 تفعيل المساعد الصوتي           │  ← Voice Toggle
│     [تفعيل] / [إيقاف]             │
├─────────────────────────────────────┤
│                                     │
│      📷 اختر صورة النموذج           │  ← Main Action
│                                     │
│    [📁 من المعرض] [📸 التقاط]      │  ← Image Picker Buttons
│                                     │
├─────────────────────────────────────┤
│ 💡 يمكنك رفع صور بصيغة:            │  ← Help Text
│    JPG, PNG, PDF, BMP              │
└─────────────────────────────────────┘
```

**الأكواد**:
```dart
class StartScreen extends StatefulWidget {
  final Function(File) onImageSelected;
  final bool voiceEnabled;
  final Function(bool) onVoiceToggle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قارئ النماذج'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Voice Toggle
            Card(
              child: SwitchListTile(
                title: Text('تفعيل المساعد الصوتي'),
                subtitle: Text('للاستماع للإرشادات صوتياً'),
                value: voiceEnabled,
                onChanged: onVoiceToggle,
                secondary: Icon(Icons.volume_up),
              ),
            ),
            
            SizedBox(height: 40),
            
            // Main Upload Area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'اختر صورة النموذج',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 40),
                    
                    // Upload Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: Icon(Icons.photo_library),
                            label: Text('من المعرض'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: Icon(Icons.camera),
                            label: Text('التقاط صورة'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Help Text
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك رفع صور بصيغة: JPG, PNG, PDF, BMP',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### شاشة 2: فحص الجودة (Quality Check Screen)

**الحالة**: `conversationStage = "quality_check"`

**العناصر**:
```
┌─────────────────────────────────────┐
│         فحص جودة الصورة             │
├─────────────────────────────────────┤
│  ⏳ جاري فحص الصورة...             │  ← Loading Indicator
├─────────────────────────────────────┤
│                                     │
│    [صورة معاينة صغيرة]              │  ← Image Preview
│                                     │
├─────────────────────────────────────┤
│ ✅ جودة الصورة جيدة                │  ← Quality Status
│ 🌐 تم كشف اللغة العربية            │
│                                     │
│ 📋 هذا نموذج طلب وظيفة يحتوي على   │  ← Form Explanation
│     الحقول التالية...              │
├─────────────────────────────────────┤
│          [متابعة التحليل]           │  ← Continue Button
└─────────────────────────────────────┘
```

**الأكواد**:
```dart
class QualityCheckScreen extends StatelessWidget {
  final File imageFile;
  final ImageQualityResult? qualityResult;
  final bool isLoading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('فحص جودة الصورة')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Loading or Image Preview
            if (isLoading) ...[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري فحص الصورة...'),
            ] else ...[
              // Image Preview
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            // Quality Results
            if (qualityResult != null) ...[
              // Quality Status
              Card(
                color: qualityResult!.qualityGood ? Colors.green[50] : Colors.red[50],
                child: ListTile(
                  leading: Icon(
                    qualityResult!.qualityGood ? Icons.check_circle : Icons.warning,
                    color: qualityResult!.qualityGood ? Colors.green : Colors.red,
                  ),
                  title: Text(qualityResult!.qualityMessage),
                  subtitle: Text(
                    'اللغة المكتشفة: ${qualityResult!.languageDirection == "rtl" ? "العربية" : "الإنجليزية"}'
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Form Explanation
              if (qualityResult!.formExplanation.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'وصف النموذج',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(qualityResult!.formExplanation),
                      ],
                    ),
                  ),
                ),
              ],
              
              Spacer(),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: Text('متابعة التحليل'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

### شاشة 3: تحليل النموذج (Form Analysis Screen)

**الحالة**: `conversationStage = "analyzing"`

**العناصر**:
```
┌─────────────────────────────────────┐
│           تحليل النموذج             │
├─────────────────────────────────────┤
│                                     │
│    🔄 جاري تحليل النموذج...         │  ← Loading Animation
│                                     │
│  ⚡ استخراج الحقول القابلة للتعبئة    │  ← Progress Text
│                                     │
│     [████████████░░░░] 75%          │  ← Progress Bar
│                                     │
│  💡 هذا قد يستغرق بضع ثواني...      │  ← Help Text
└─────────────────────────────────────┘
```

**الأكواد**:
```dart
class FormAnalysisScreen extends StatefulWidget {
  @override
  _FormAnalysisScreenState createState() => _FormAnalysisScreenState();
}

class _FormAnalysisScreenState extends State<FormAnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _animation = Tween(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تحليل النموذج')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Loading Icon
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animation.value * 2 * 3.14159,
                    child: Icon(
                      Icons.refresh,
                      size: 80,
                      color: Colors.blue,
                    ),
                  );
                },
              ),
              
              SizedBox(height: 32),
              
              Text(
                'جاري تحليل النموذج...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 16),
              
              Text(
                'استخراج الحقول القابلة للتعبئة',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Progress Bar (optional)
              LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              
              SizedBox(height: 16),
              
              Text(
                'هذا قد يستغرق بضع ثواني...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

---

### شاشة 4: ملء الحقول (Field Filling Screen)

**الحالة**: `conversationStage = "filling_fields"`

**تخطيط الشاشة**:
```
┌─────────────────────────────────────┐
│  🔄 الحقل 2 من 5                   │  ← Progress Header
├─────────────────────────────────────┤
│                                     │
│       [معاينة النموذج]              │  ← Live Preview (النصف العلوي)
│                                     │
├─────────────────────────────────────┤
│ 📋 الحقل الحالي: "الاسم الكامل"     │  ← Current Field Label
├─────────────────────────────────────┤
│   🎤 اضغط للتحدث                   │  ← Voice Input Button
│   [●] جاري التسجيل...               │  ← Recording State
├─────────────────────────────────────┤
│ ⌨️ أو اكتب هنا:                    │  ← Text Input Label
│ ┌─────────────────────────────────┐ │
│ │ أحمد محمد...                   │ │  ← Text Input Field
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ [حفظ ومتابعة]     [تخطي]           │  ← Action Buttons
└─────────────────────────────────────┘
```

**للحقول من نوع Checkbox**:
```
┌─────────────────────────────────────┐
│ ☑️ خانة اختيار: "هل أنت متزوج؟"     │  ← Checkbox Field
├─────────────────────────────────────┤
│   🎤 قل "نعم" أو "لا"               │  ← Voice Instructions
├─────────────────────────────────────┤
│   ☐ متزوج                          │  ← Checkbox
│   ☑ غير متزوج                      │
└─────────────────────────────────────┘
```

**للحقول من نوع التوقيع**:
```
┌─────────────────────────────────────┐
│ ✍️ حقل التوقيع                      │  ← Signature Field
├─────────────────────────────────────┤
│   📷 ارفع صورة توقيعك               │  ← Signature Upload
│                                     │
│   [📁 اختيار صورة]                 │  ← Upload Button
│                                     │
│   [معاينة التوقيع المرفوع]          │  ← Signature Preview
└─────────────────────────────────────┘
```

**الأكواد**:
```dart
class FieldFillingScreen extends StatefulWidget {
  final FormState formState;
  final Function(String, dynamic) onFieldUpdate;
  final Function() onNext;
  final Function() onSkip;

  @override
  Widget build(BuildContext context) {
    final currentField = formState.fields[formState.currentFieldIndex];
    final isLastField = formState.currentFieldIndex == formState.fields.length - 1;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('الحقل ${formState.currentFieldIndex + 1} من ${formState.fields.length}'),
        backgroundColor: Colors.blue[800],
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (formState.currentFieldIndex + 1) / formState.fields.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          
          // Live Preview
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              child: Card(
                child: formState.annotatedImageBytes != null
                    ? Image.memory(
                        formState.annotatedImageBytes!,
                        fit: BoxFit.contain,
                      )
                    : Center(child: Text('معاينة النموذج')),
              ),
            ),
          ),
          
          // Field Input Area
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field Label
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(_getFieldIcon(currentField.type), color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentField.label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Field Input Based on Type
                  Expanded(
                    child: _buildFieldInput(currentField),
                  ),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: onNext,
                          child: Text(isLastField ? 'إنهاء' : 'حفظ ومتابعة'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onSkip,
                          child: Text('تخطي'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInput(UIField field) {
    if (field.type == 'checkbox') {
      return _buildCheckboxInput(field);
    } else if (_isSignatureField(field.label)) {
      return _buildSignatureInput(field);
    } else {
      return _buildTextInput(field);
    }
  }

  Widget _buildTextInput(UIField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Input Button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startVoiceInput(field),
            icon: Icon(Icons.mic),
            label: Text('اضغط للتحدث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Text Input
        Text('أو اكتب هنا:'),
        SizedBox(height: 8),
        TextField(
          controller: TextEditingController(
            text: formState.formData[field.boxId] ?? '',
          ),
          onChanged: (value) => onFieldUpdate(field.boxId, value),
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'ادخل ${field.label}',
          ),
          maxLines: field.label.contains('عنوان') ? 3 : 1,
        ),
      ],
    );
  }

  Widget _buildCheckboxInput(UIField field) {
    final currentValue = formState.formData[field.boxId] ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Instructions
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.volume_up, color: Colors.orange),
              SizedBox(width: 8),
              Text('قل "نعم" أو "لا"'),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Voice Input Button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startVoiceInput(field),
            icon: Icon(Icons.mic),
            label: Text('اضغط للتحدث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Checkbox Options
        Card(
          child: Column(
            children: [
              CheckboxListTile(
                title: Text('نعم'),
                value: currentValue == true,
                onChanged: (value) => onFieldUpdate(field.boxId, true),
              ),
              CheckboxListTile(
                title: Text('لا'),
                value: currentValue == false,
                onChanged: (value) => onFieldUpdate(field.boxId, false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureInput(UIField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Signature Instructions
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.draw, color: Colors.purple),
              SizedBox(width: 8),
              Text('ارفع صورة توقيعك هنا'),
            ],
          ),
        ),
        
        SizedBox(height: 16),
        
        // Upload Button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _pickSignatureImage,
            icon: Icon(Icons.upload_file),
            label: Text('اختيار صورة التوقيع'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Signature Preview
        if (formState.signatureBytes != null) ...[
          Text('معاينة التوقيع:'),
          SizedBox(height: 8),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                formState.signatureBytes!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getFieldIcon(String type) {
    switch (type) {
      case 'checkbox':
        return Icons.check_box;
      case 'signature':
        return Icons.draw;
      default:
        return Icons.text_fields;
    }
  }
}
```

---

### شاشة 5: التأكيد (Confirmation Screen)

**الحالة**: `conversationStage = "confirmation"`

**العناصر**:
```
┌─────────────────────────────────────┐
│            تأكيد البيانات           │
├─────────────────────────────────────┤
│                                     │
│  🎤 سمعتك تقول:                    │  ← Heard Label
│                                     │
│  "أحمد محمد علي السعيد"             │  ← Transcribed Text
│                                     │
├─────────────────────────────────────┤
│ ❓ هل هذا صحيح؟                     │  ← Confirmation Question
├─────────────────────────────────────┤
│   [✅ تأكيد]      [🔄 إعادة]        │  ← Action Buttons
└─────────────────────────────────────┘
```

**الأكواد**:
```dart
class ConfirmationScreen extends StatelessWidget {
  final String transcribedText;
  final String fieldLabel;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('تأكيد البيانات')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heard Icon
            Icon(
              Icons.hearing,
              size: 80,
              color: Colors.blue,
            ),
            
            SizedBox(height: 24),
            
            // Heard Label
            Text(
              'سمعتك تقول:',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Transcribed Text
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                '"$transcribedText"',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            SizedBox(height: 32),
            
            // Confirmation Question
            Text(
              'هل هذا صحيح؟',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: Icon(Icons.check),
                    label: Text('تأكيد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: Icon(Icons.refresh),
                    label: Text('إعادة المحاولة'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
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
}
```

---

### شاشة 6: المراجعة النهائية (Review Screen)

**الحالة**: `conversationStage = "review"`

**العناصر**:
```
┌─────────────────────────────────────┐
│           المراجعة النهائية         │
├─────────────────────────────────────┤
│                                     │
│      [النموذج النهائي مكتمل]        │  ← Final Form Preview
│                                     │
├─────────────────────────────────────┤
│ ✅ تم إكمال جميع الحقول بنجاح       │  ← Success Message
├─────────────────────────────────────┤
│  [📥 تحميل PNG]  [📄 تحميل PDF]    │  ← Download Buttons
├─────────────────────────────────────┤
│         [🔄 تعديل البيانات]        │  ← Edit Button
└─────────────────────────────────────┘
```

**الأكواد**:
```dart
class ReviewScreen extends StatelessWidget {
  final Uint8List finalImageBytes;
  final Map<String, dynamic> formData;
  final List<UIField> fields;
  final Function(String) onDownload;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المراجعة النهائية'),
        backgroundColor: Colors.green[800],
      ),
      body: Column(
        children: [
          // Success Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم إكمال النموذج بنجاح!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        'يمكنك الآن تحميل النموذج المكتمل',
                        style: TextStyle(color: Colors.green[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Final Form Preview
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    finalImageBytes,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
          
          // Data Summary (Optional)
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملخص البيانات المدخلة:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: _buildDataSummary(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Download Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onDownload('PNG'),
                        icon: Icon(Icons.download),
                        label: Text('تحميل PNG'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => onDownload('PDF'),
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text('تحميل PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // Edit Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit),
                    label: Text('تعديل البيانات'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataSummary() {
    List<Widget> widgets = [];
    
    for (var field in fields) {
      var value = formData[field.boxId];
      if (value != null && value.toString().isNotEmpty) {
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  field.type == 'checkbox' 
                      ? Icons.check_box 
                      : Icons.text_fields,
                  size: 16,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    field.label + ':',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    _formatValue(value, field.type),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  String _formatValue(dynamic value, String type) {
    if (type == 'checkbox') {
      return value == true ? '✓ محدد' : '✗ غير محدد';
    }
    return value.toString();
  }
}
```

---

## 🔄 إدارة الانتقالات بين الشاشات

```dart
class FormFlowManager {
  static Widget getScreenForStage(String stage, FormState formState) {
    switch (stage) {
      case 'start':
        return StartScreen(
          onImageSelected: (file) => _handleImageUpload(file, formState),
          voiceEnabled: formState.voiceEnabled,
          onVoiceToggle: (enabled) => _updateVoiceSettings(enabled, formState),
        );
        
      case 'quality_check':
        return QualityCheckScreen(
          imageFile: formState.selectedImageFile!,
          qualityResult: formState.qualityResult,
          isLoading: formState.isCheckingQuality,
          onContinue: () => _startFormAnalysis(formState),
        );
        
      case 'analyzing':
        return FormAnalysisScreen();
        
      case 'filling_fields':
        return FieldFillingScreen(
          formState: formState,
          onFieldUpdate: (fieldId, value) => _updateField(fieldId, value, formState),
          onNext: () => _moveToNextField(formState),
          onSkip: () => _skipCurrentField(formState),
        );
        
      case 'confirmation':
        return ConfirmationScreen(
          transcribedText: formState.pendingTranscript!,
          fieldLabel: formState.currentField.label,
          onConfirm: () => _confirmTranscript(formState),
          onRetry: () => _retryVoiceInput(formState),
        );
        
      case 'review':
        return ReviewScreen(
          finalImageBytes: formState.finalImageBytes!,
          formData: formState.formData,
          fields: formState.fields,
          onDownload: (format) => _downloadForm(format, formState),
          onEdit: () => _editForm(formState),
        );
        
      default:
        return StartScreen(/* ... */);
    }
  }
}
```

هذا الدليل يوضح كل شاشة بالتفصيل مع الكود المطلوب وتخطيط العناصر. كل شاشة مصممة لتكون واضحة ومفهومة للمستخدمين المكفوفين وضعاف البصر مع دعم كامل للتفاعل الصوتي.
