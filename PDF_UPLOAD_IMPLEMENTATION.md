# تنفيذ رفع الملفات في شاشة PDF

## المشكلة السابقة ❌

دالة `submit()` كانت **لا ترسل أي شيء للسيرفر**:

```dart
void submit() {
  // ... validation ...
  
  // هنا يمكنك تنفيذ رفع الملف فعلياً ❌ مجرد تعليق!
  String details = detailsController.text.trim();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('تم رفع الملف بنجاح!')), // رسالة وهمية!
  );
  // فقط مسح البيانات!
}
```

**النتيجة**: المستخدم يرى رسالة "تم رفع الملف بنجاح!" لكن **لا شيء يُرسل للسيرفر**!

## الحل الجديد ✅

### 1. تحويل الدالة إلى async

```dart
Future<void> submit() async {
  // الآن يمكنها إرسال طلبات HTTP
}
```

### 2. Logging مفصل

```dart
print('════════════════════════════════════════════');
print('📤 بدء عملية رفع الملف');
print('════════════════════════════════════════════');

print('📋 بيانات الإرسال:');
print('   - المدرسة: $selectedSchool');
print('   - المرحلة: $selectedStage');
print('   - الشعبة: $selectedSection');
print('   - المادة: $selectedSubject');
print('   - الوحدة: ${selectedUnit ?? "غير محدد"}');
print('   - اسم الملف: ${selectedFile!.path.split('/').last}');
print('   - حجم الملف: ${selectedFile!.lengthSync()} bytes');
```

### 3. الحصول على IDs من TeacherClass

```dart
final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
  classes,
  selectedSchool!,
  selectedStage!,
  selectedSection!,
  selectedSubject!,
);

print('   - LevelSubjectId: ${matchingClass.levelSubjectId}');
print('   - LevelId: ${matchingClass.levelId}');
print('   - ClassId: ${matchingClass.classId}');
```

### 4. إنشاء MultipartRequest

```dart
final baseUrl = await AuthService.getOrganizationUrl();
final url = Uri.parse('$baseUrl/api/pdf/upload');

final request = http.MultipartRequest('POST', url);

// Headers
request.headers['Authorization'] = 'Bearer $token';
request.headers['Accept'] = 'application/json';

print('🌐 URL: $url');
print('🔑 التوكن: ${token.substring(0, 20)}...');
```

### 5. إضافة الملف الرئيسي

```dart
final fileBytes = await selectedFile!.readAsBytes();
request.files.add(http.MultipartFile.fromBytes(
  'file', // اسم الحقل في API
  fileBytes,
  filename: selectedFile!.path.split('/').last,
));

print('📎 تم إضافة الملف الرئيسي');
```

### 6. إضافة الملف الصوتي (اختياري)

```dart
if (selectedAudio != null) {
  final audioBytes = await selectedAudio!.readAsBytes();
  request.files.add(http.MultipartFile.fromBytes(
    'audio',
    audioBytes,
    filename: selectedAudio!.path.split('/').last,
  ));
  print('🎵 تم إضافة الملف الصوتي');
}
```

### 7. إضافة البيانات النصية

```dart
request.fields['levelSubjectId'] = matchingClass.levelSubjectId ?? '';
request.fields['levelId'] = matchingClass.levelId ?? '';
request.fields['classId'] = matchingClass.classId ?? '';
if (selectedUnit != null) {
  request.fields['unit'] = selectedUnit!;
}
if (details.isNotEmpty) {
  request.fields['details'] = details;
}

print('📝 الحقول المرسلة:');
request.fields.forEach((key, value) {
  print('   - $key: $value');
});
```

### 8. إرسال الطلب

```dart
print('🚀 جاري إرسال الطلب...');
final streamedResponse = await request.send();
final response = await http.Response.fromStream(streamedResponse);

print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
print('📥 استجابة السيرفر:');
print('   - Status Code: ${response.statusCode}');
print('   - Status: ${response.statusCode >= 200 && response.statusCode < 300 ? "نجح ✅" : "فشل ❌"}');
print('   - Response Body:');
print(response.body);
print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
```

### 9. معالجة الاستجابة

```dart
if (response.statusCode >= 200 && response.statusCode < 300) {
  // نجح الرفع ✅
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('تم رفع الملف بنجاح! ✅'),
      backgroundColor: Colors.green,
    ),
  );
  
  // مسح البيانات
  setState(() {
    selectedFile = null;
    selectedAudio = null;
    // ... إلخ
  });
} else {
  // فشل الرفع ❌
  throw Exception('فشل رفع الملف: ${response.statusCode} - ${response.body}');
}
```

### 10. معالجة الأخطاء

```dart
catch (e) {
  print('❌ خطأ في رفع الملف: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('خطأ: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## مثال على الـ Console Log

عند رفع ملف، ستجد في الـ console:

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
   - LevelSubjectId: 0685fbc8-81f1-4317-bfe5-56144feb010d
   - LevelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a
   - ClassId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5
   - اسم الملف: math_lesson.pdf
   - حجم الملف: 1547823 bytes
   - التفاصيل: درس المصفوفات
🔑 التوكن: eyJhbGciOiJIUzI1NiIs...
🌐 URL: https://nouraleelemorg.runasp.net/api/pdf/upload
📨 Headers:
   - Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
   - Accept: application/json
📎 تم إضافة الملف الرئيسي
📝 الحقول المرسلة:
   - levelSubjectId: 0685fbc8-81f1-4317-bfe5-56144feb010d
   - levelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a
   - classId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5
   - unit: الفصل الأول
   - details: درس المصفوفات
🚀 جاري إرسال الطلب...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📥 استجابة السيرفر:
   - Status Code: 200
   - Status: نجح ✅
   - Response Body:
{
  "success": true,
  "message": "تم رفع الملف بنجاح",
  "fileId": "abc123"
}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## البيانات المرسلة

### Files (Multipart)
- **`file`**: الملف الرئيسي (PDF, Image, Video)
- **`audio`**: الملف الصوتي (اختياري)

### Fields (Form Data)
- **`levelSubjectId`**: معرف المادة في المرحلة
- **`levelId`**: معرف المرحلة
- **`classId`**: معرف الفصل/الشعبة
- **`unit`**: الوحدة/الفصل (اختياري)
- **`details`**: تفاصيل إضافية (اختياري)

## ملاحظات مهمة

### 1. تعديل الـ Endpoint

**⚠️ مهم جداً**: عدّل السطر 373 حسب API الخاص بك:

```dart
final url = Uri.parse('$baseUrl/api/pdf/upload'); // عدّل هذا!
```

اسأل Backend Developer عن:
- ما هو الـ endpoint الصحيح؟
- ما أسماء الحقول المتوقعة؟
- هل يوجد حقول إضافية مطلوبة؟

### 2. أسماء الحقول في Multipart

تأكد من أسماء الحقول:

```dart
request.files.add(http.MultipartFile.fromBytes(
  'file', // ⚠️ هل API يتوقع 'file' أم 'pdfFile' أم 'document'؟
  fileBytes,
  filename: selectedFile!.path.split('/').last,
));
```

### 3. Content-Type

إذا احتاج السيرفر content-type معين:

```dart
request.files.add(http.MultipartFile.fromBytes(
  'file',
  fileBytes,
  filename: selectedFile!.path.split('/').last,
  contentType: MediaType('application', 'pdf'), // أضف هذا
));
```

تحتاج import:
```dart
import 'package:http_parser/http_parser.dart';
```

### 4. معالجة الأخطاء من السيرفر

السيرفر قد يرجع أخطاء متعددة:

```dart
// 400: Bad Request - بيانات خاطئة
// 401: Unauthorized - التوكن غير صالح
// 403: Forbidden - لا تملك صلاحية
// 413: Payload Too Large - الملف كبير جداً
// 422: Unprocessable Entity - بيانات غير صالحة
// 500: Internal Server Error - خطأ في السيرفر
```

## الاختبار

### 1. اختر البيانات

1. اختر مدرسة
2. اختر مرحلة
3. اختر شعبة
4. اختر مادة
5. (اختياري) اختر وحدة
6. ارفع ملف PDF

### 2. اضغط "إرسال"

### 3. راقب الـ Console

ستجد جميع التفاصيل مطبوعة!

### 4. تحقق من النتيجة

- **نجح**: رسالة خضراء + مسح البيانات
- **فشل**: رسالة حمراء + تفاصيل الخطأ

## التعامل مع مشاكل شائعة

### المشكلة: "لم يتم العثور على التوكن"

**الحل**: تأكد من تسجيل الدخول

### المشكلة: 401 Unauthorized

**الحل**: 
- التوكن منتهي الصلاحية
- سجل دخول مرة أخرى

### المشكلة: 404 Not Found

**الحل**: 
- الـ endpoint خاطئ
- عدّل السطر 373

### المشكلة: 413 Payload Too Large

**الحل**: 
- الملف كبير جداً
- ضغط الملف أو اختر ملف أصغر

### المشكلة: "لم يتم العثور على الفصل المطابق"

**الحل**: 
- البيانات المختارة غير موجودة في classes
- تحقق من بيانات المعلم

## الملخص

✅ **الآن الدالة ترسل البيانات فعلياً للسيرفر**  
✅ **Logging مفصل لتتبع كل خطوة**  
✅ **معالجة صحيحة للنجاح والفشل**  
✅ **دعم الملفات الصوتية**  
✅ **معالجة شاملة للأخطاء**

⚠️ **لا تنسى تعديل الـ endpoint حسب API الخاص بك!**
