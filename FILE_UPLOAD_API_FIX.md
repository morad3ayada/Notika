# تصحيح API رفع الملفات

## المواصفات الصحيحة من السيرفر

### Endpoint
```
POST /api/file/add
```

### Content-Type
```
multipart/form-data
```

### الحقول المطلوبة

| الحقل | النوع | مطلوب | مثال |
|-------|-------|-------|------|
| **LevelSubjectId** | uuid | ✅ | `2bef959b-16ea-4b1f-8907-76a21d073d18` |
| **LevelId** | uuid | ✅ | `7f959c2c-fac1-45f5-b47e-56b84b74a76a` |
| **ClassId** | uuid | ❌ | `9dce0fd8-2971-4a34-bab9-6a78a643eca5` |
| **FileClassificationId** | uuid | ✅ | `2040964d-7f2b-4f7e-8301-08de0b1bf445` |
| **Title** | string | ✅ | `Hello` |
| **FileType** | string | ✅ | `png` |
| **Path** | string | ❌ | فارغ `""` |
| **Note** | string | ❌ | `Hello png` |
| **File** | binary | ✅ | الملف نفسه |

## التغييرات في الكود

### 1. تغيير الـ Endpoint

```dart
// ❌ القديم (خطأ)
final url = Uri.parse('$baseUrl/api/pdf/upload');

// ✅ الجديد (صحيح)
final url = Uri.parse('$baseUrl/api/file/add');
```

### 2. إضافة التحقق من الوحدة

```dart
// ✅ الآن الوحدة مطلوبة
if (selectedFile == null ||
    selectedSchool == null ||
    selectedStage == null ||
    selectedSection == null ||
    selectedSubject == null ||
    selectedUnit == null) {  // ← إضافة!
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('يرجى اختيار جميع الحقول بما في ذلك الوحدة ورفع ملف')),
  );
  return;
}
```

### 3. الحصول على FileClassificationId

```dart
// الحصول على FileClassificationId من BLoC
final fileClassState = _fileClassificationBloc.state;
String? fileClassificationId;

if (fileClassState is FileClassificationsLoaded) {
  final selectedFileClass = fileClassState.fileClassifications
      .firstWhere(
        (fc) => fc.name == selectedUnit,
        orElse: () => throw Exception('لم يتم العثور على الوحدة المختارة'),
      );
  fileClassificationId = selectedFileClass.id;
} else {
  throw Exception('لم يتم تحميل قائمة الوحدات');
}
```

### 4. استخراج معلومات الملف

```dart
// الحصول على معلومات الملف
final fileName = selectedFile!.path.split('/').last;
final fileExtension = fileName.split('.').last.toLowerCase();
final title = detailsController.text.trim().isNotEmpty 
    ? detailsController.text.trim() 
    : fileName.replaceAll('.$fileExtension', '');
```

### 5. تغيير اسم حقل الملف

```dart
// ❌ القديم
request.files.add(http.MultipartFile.fromBytes(
  'file',  // حرف صغير
  fileBytes,
  filename: fileName,
));

// ✅ الجديد (حرف F كبير)
request.files.add(http.MultipartFile.fromBytes(
  'File',  // ← حرف F كبير!
  fileBytes,
  filename: fileName,
));
```

### 6. إضافة الحقول الصحيحة

```dart
// الحقول المطلوبة (✅)
request.fields['LevelSubjectId'] = matchingClass.levelSubjectId ?? '';
request.fields['LevelId'] = matchingClass.levelId ?? '';
request.fields['FileClassificationId'] = fileClassificationId;
request.fields['Title'] = title;
request.fields['FileType'] = fileExtension;

// الحقول الاختيارية (❌)
if (matchingClass.classId != null && matchingClass.classId!.isNotEmpty) {
  request.fields['ClassId'] = matchingClass.classId!;
}

request.fields['Path'] = ''; // فارغ

final note = detailsController.text.trim();
if (note.isNotEmpty) {
  request.fields['Note'] = note;
}
```

## مقارنة: القديم vs الجديد

### Endpoint

| الجانب | القديم ❌ | الجديد ✅ |
|--------|----------|----------|
| **URL** | `/api/pdf/upload` | `/api/file/add` |
| **Method** | `POST` | `POST` |

### الحقول

| الحقل | القديم ❌ | الجديد ✅ |
|-------|----------|----------|
| **File field** | `file` | `File` |
| **LevelSubjectId** | `levelSubjectId` | `LevelSubjectId` |
| **LevelId** | `levelId` | `LevelId` |
| **ClassId** | `classId` | `ClassId` |
| **FileClassificationId** | ❌ غير موجود | ✅ `FileClassificationId` |
| **Title** | ❌ غير موجود | ✅ `Title` |
| **FileType** | ❌ غير موجود | ✅ `FileType` |
| **Path** | ❌ غير موجود | ✅ `Path` (فارغ) |
| **Note** | `details` | `Note` |

### الحقول المحذوفة

❌ **تم إزالة**:
- `unit` (كان string، الآن نستخدم FileClassificationId)
- `audio` (الملف الصوتي لم يعد مطلوباً)

## Console Log المتوقع

```
════════════════════════════════════════════
📤 بدء عملية رفع الملف
════════════════════════════════════════════
📋 بيانات الإرسال:
   - المدرسة: مدرسة النور الأهلية
   - المرحلة: الصف الثالث الثانوي
   - الشعبة: 3/1
   - المادة: الرياضيات
   - الوحدة: الفصل الأول
   - LevelSubjectId: 2bef959b-16ea-4b1f-8907-76a21d073d18
   - LevelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a
   - ClassId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5
   - FileClassificationId: 2040964d-7f2b-4f7e-8301-08de0b1bf445
   - Title: درس المصفوفات
   - FileType: pdf
   - اسم الملف: math_lesson.pdf
   - حجم الملف: 1547823 bytes
   - Note: شرح مفصل للمصفوفات
🔑 التوكن: eyJhbGciOiJIUzI1NiIs...
🌐 URL: https://nouraleelemorg.runasp.net/api/file/add
📨 Headers:
   - Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
   - Accept: application/json
📎 تم إضافة الملف
📝 الحقول المرسلة:
   - LevelSubjectId: 2bef959b-16ea-4b1f-8907-76a21d073d18
   - LevelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a
   - ClassId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5
   - FileClassificationId: 2040964d-7f2b-4f7e-8301-08de0b1bf445
   - Title: درس المصفوفات
   - FileType: pdf
   - Path: 
   - Note: شرح مفصل للمصفوفات
🚀 جاري إرسال الطلب...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📥 استجابة السيرفر:
   - Status Code: 200
   - Status: نجح ✅
   - Response Body:
{
  "success": true,
  "message": "تم رفع الملف بنجاح",
  "fileId": "abc-123-def-456"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## خطوات الاختبار

### 1. اختيار البيانات
- ✅ اختر المدرسة
- ✅ اختر المرحلة
- ✅ اختر الشعبة
- ✅ اختر المادة ← **سيتم جلب الوحدات تلقائياً**
- ✅ اختر الوحدة ← **مطلوب الآن!**
- ✅ ارفع ملف

### 2. إضافة معلومات (اختياري)
- في حقل "التفاصيل": اكتب عنوان للملف (سيصبح Title)
- إذا تركته فارغاً: سيستخدم اسم الملف كـ Title

### 3. إرسال
- اضغط "إرسال"
- راقب الـ Console

### 4. النتيجة المتوقعة

#### نجاح ✅:
- Status Code: `200` أو `201`
- رسالة خضراء: "تم رفع الملف بنجاح!"
- مسح جميع الحقول

#### فشل ❌:
- Status Code غير `200/201`
- رسالة حمراء مع تفاصيل الخطأ
- البيانات تبقى موجودة للتصحيح

## معالجة الأخطاء الشائعة

### خطأ: "يرجى اختيار جميع الحقول بما في ذلك الوحدة"

**السبب**: لم تختر وحدة

**الحل**: 
1. اختر المادة أولاً
2. ثم اختر الوحدة من القائمة

### خطأ: "لم يتم العثور على الوحدة المختارة"

**السبب**: الوحدة المختارة غير موجودة في القائمة المحملة

**الحل**: 
1. اختر وحدة موجودة
2. أو أضف وحدة جديدة أولاً

### خطأ: "لم يتم تحميل قائمة الوحدات"

**السبب**: لم يتم جلب الوحدات من السيرفر

**الحل**:
1. اختر المادة مرة أخرى
2. انتظر حتى تُحمل الوحدات
3. تحقق من Console للتأكد

### خطأ: "معرف الوحدة غير صالح"

**السبب**: FileClassificationId فارغ أو null

**الحل**:
1. تأكد من اختيار وحدة صحيحة
2. تحقق من أن السيرفر أرجع IDs صحيحة

### Status Code 400: Bad Request

**الأسباب المحتملة**:
- حقل مطلوب مفقود
- نوع بيانات خاطئ
- UUID غير صالح

**الحل**: راجع الـ Console Log وتحقق من جميع الحقول

### Status Code 401: Unauthorized

**السبب**: التوكن منتهي أو غير صالح

**الحل**: سجل دخول مرة أخرى

## الملاحظات المهمة

### 1. أسماء الحقول Case-Sensitive

⚠️ **مهم جداً**: السيرفر يتوقع حرف أول كبير!

```dart
✅ 'LevelSubjectId'  // صحيح
❌ 'levelSubjectId'  // خطأ

✅ 'File'  // صحيح
❌ 'file'  // خطأ
```

### 2. FileClassificationId مطلوب

لا يمكن رفع ملف بدون FileClassificationId:
- يجب اختيار وحدة أولاً
- الوحدة يجب أن تكون موجودة في السيرفر
- ID الوحدة يُحصل عليه من `FileClassificationsLoaded` state

### 3. FileType من امتداد الملف

```dart
final fileName = 'document.pdf';
final fileExtension = fileName.split('.').last.toLowerCase(); // 'pdf'
request.fields['FileType'] = fileExtension;
```

### 4. Title تلقائي

إذا لم يكتب المستخدم Title:
```dart
final title = detailsController.text.trim().isNotEmpty 
    ? detailsController.text.trim()  // استخدم ما كتبه المستخدم
    : fileName.replaceAll('.$fileExtension', '');  // استخدم اسم الملف
```

### 5. Path فارغ دائماً

```dart
request.fields['Path'] = '';  // السيرفر يتعامل مع المسار
```

## الملخص

✅ **Endpoint صحيح**: `/api/file/add`  
✅ **جميع الحقول بأسماء صحيحة**: حرف أول كبير  
✅ **FileClassificationId مطلوب**: يتم الحصول عليه من الوحدة المختارة  
✅ **Title و FileType تلقائي**: من اسم وامتداد الملف  
✅ **Logging مفصل**: لتتبع كل خطوة  
✅ **معالجة أخطاء شاملة**: مع رسائل واضحة  

**جرب الآن ورفع الملف يجب أن يعمل!** 🚀
