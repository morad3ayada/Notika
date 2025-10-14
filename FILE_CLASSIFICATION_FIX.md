# إصلاح جلب FileClassifications من السيرفر

## المشكلة

عند محاولة جلب FileClassifications من السيرفر، كان الـ **endpoint خاطئ**:

### الكود القديم ❌
```dart
final response = await http.get(
  Uri.parse('$baseUrl/fileclassification?levelSubjectId=$levelSubjectId&levelId=$levelId&classId=$classId'),
  headers: {
    'accept': 'application/json',
    'Authorization': cleanToken,
  },
);
```

**المشاكل:**
1. ❌ Endpoint خاطئ: `/fileclassification` بدلاً من `/fileclassification/getByLevelAndClass`
2. ❌ Parameter names خاطئة: `levelSubjectId` بدلاً من `LevelSubjectId` (حرف L صغير)
3. ❌ Accept header خاطئ: `application/json` بدلاً من `text/plain`
4. ❌ Logging ضعيف

## الحل ✅

### 1. تصحيح الـ Endpoint

```dart
// الكود الجديد الصحيح
final url = Uri.parse('$baseUrl/fileclassification/getByLevelAndClass?LevelSubjectId=$levelSubjectId&LevelId=$levelId&ClassId=$classId');
```

**التغييرات:**
- ✅ Endpoint صحيح: `/fileclassification/getByLevelAndClass`
- ✅ Parameter names صحيحة: `LevelSubjectId`, `LevelId`, `ClassId` (حرف L كبير)

### 2. تصحيح Headers

```dart
headers: {
  'accept': 'text/plain',  // ✅ تغيير من application/json
  'Authorization': cleanToken,
}
```

### 3. إضافة Logging مفصل

#### في البداية:
```dart
print('═══════════════════════════════════════════════════════');
print('📂 جلب FileClassifications من السيرفر');
print('═══════════════════════════════════════════════════════');

print('📋 المعاملات:');
print('   - LevelSubjectId: $levelSubjectId');
print('   - LevelId: $levelId');
print('   - ClassId: $classId');
print('🔑 التوكن: ${cleanToken.substring(0, 20)}...');
print('🌐 URL: $url');
```

#### استجابة السيرفر:
```dart
print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
print('📥 استجابة السيرفر:');
print('   - Status Code: ${response.statusCode}');
print('   - Status: ${response.statusCode == 200 ? "نجح ✅" : "فشل ❌"}');
print('   - Response Body:');
print(response.body);
print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
```

#### تحليل البيانات:
```dart
print('📊 تحليل البيانات المستلمة:');
print('   - نوع البيانات: ${responseData.runtimeType}');

if (responseData is List) {
  print('   - البيانات عبارة عن قائمة (List)');
  print('   - عدد العناصر: ${responseData.length}');
  
  final classifications = responseData
      .map((item) => FileClassification.fromJson(item))
      .toList();
  
  print('✅ تم تحويل ${classifications.length} عنصر بنجاح');
  for (var i = 0; i < classifications.length; i++) {
    print('   ${i + 1}. ${classifications[i].name} (ID: ${classifications[i].id})');
  }
}
```

### 4. إضافة Logging في BLoC

```dart
Future<void> _onLoadFileClassifications(
  LoadFileClassificationsEvent event,
  Emitter<FileClassificationState> emit,
) async {
  try {
    print('🔷 FileClassificationBloc: بدء جلب FileClassifications');
    print('   - LevelSubjectId: ${event.levelSubjectId}');
    print('   - LevelId: ${event.levelId}');
    print('   - ClassId: ${event.classId}');
    
    emit(const FileClassificationLoading());

    final fileClassifications = await _repository.getFileClassifications(
      levelSubjectId: event.levelSubjectId,
      levelId: event.levelId,
      classId: event.classId,
    );

    print('🔷 FileClassificationBloc: تم الحصول على ${fileClassifications.length} عنصر');
    
    emit(FileClassificationsLoaded(fileClassifications: fileClassifications));
    
    print('✅ FileClassificationBloc: تم emit حالة FileClassificationsLoaded');
  } catch (e) {
    print('❌ FileClassificationBloc: خطأ في جلب FileClassifications: $e');
    // ...
  }
}
```

## مثال على طلب cURL الصحيح

```bash
curl -X 'GET' \
  'https://nouraleelemorg.runasp.net/api/fileclassification/getByLevelAndClass?LevelSubjectId=2bef959b-16ea-4b1f-8907-76a21d073d18&LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a&ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5' \
  -H 'accept: text/plain' \
  -H 'Authorization: eyJhbGci...'
```

**ملاحظة:** الكود الآن يطابق هذا الطلب تماماً!

## مثال على Console Log

عند جلب FileClassifications، ستجد:

```
🔷 FileClassificationBloc: بدء جلب FileClassifications
   - LevelSubjectId: 2bef959b-16ea-4b1f-8907-76a21d073d18
   - LevelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a
   - ClassId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5

═══════════════════════════════════════════════════════
📂 جلب FileClassifications من السيرفر
═══════════════════════════════════════════════════════
📋 المعاملات:
   - LevelSubjectId: 2bef959b-16ea-4b1f-8907-76a21d073d18
   - LevelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a
   - ClassId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5
🔑 التوكن: eyJhbGciOiJIUzI1NiIs...
🌐 URL: https://nouraleelemorg.runasp.net/api/fileclassification/getByLevelAndClass?LevelSubjectId=2bef959b-16ea-4b1f-8907-76a21d073d18&LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a&ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📥 استجابة السيرفر:
   - Status Code: 200
   - Status: نجح ✅
   - Response Body:
[
  {
    "id": "abc-123",
    "name": "الفصل الأول",
    "levelSubjectId": "2bef959b-16ea-4b1f-8907-76a21d073d18",
    "levelId": "7f959c2c-fac1-45f5-b47e-56b84b74a76a",
    "classId": "9dce0fd8-2971-4a34-bab9-6a78a643eca5",
    "createdAt": "2025-10-14T12:00:00"
  },
  {
    "id": "def-456",
    "name": "الفصل الثاني",
    "levelSubjectId": "2bef959b-16ea-4b1f-8907-76a21d073d18",
    "levelId": "7f959c2c-fac1-45f5-b47e-56b84b74a76a",
    "classId": "9dce0fd8-2971-4a34-bab9-6a78a643eca5",
    "createdAt": "2025-10-14T12:30:00"
  }
]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 تحليل البيانات المستلمة:
   - نوع البيانات: List<dynamic>
   - البيانات عبارة عن قائمة (List)
   - عدد العناصر: 2
✅ تم تحويل 2 عنصر بنجاح
   1. الفصل الأول (ID: abc-123)
   2. الفصل الثاني (ID: def-456)

🔷 FileClassificationBloc: تم الحصول على 2 عنصر
✅ FileClassificationBloc: تم emit حالة FileClassificationsLoaded
```

## التغييرات التفصيلية

### ملف: `file_classification_repository.dart`

| السطر | التغيير | الوصف |
|-------|---------|-------|
| 137-139 | إضافة | طباعة header للبداية |
| 150-154 | إضافة | طباعة المعاملات والتوكن |
| 157 | تعديل | تصحيح الـ endpoint إلى `/getByLevelAndClass` |
| 157 | تعديل | تصحيح أسماء المعاملات: `LevelSubjectId`, `LevelId`, `ClassId` |
| 165 | تعديل | تغيير accept من `application/json` إلى `text/plain` |
| 170-176 | إضافة | طباعة استجابة السيرفر |
| 181-182 | إضافة | طباعة نوع البيانات |
| 185-196 | تحسين | إضافة logging مفصل لـ List |
| 199-218 | تحسين | إضافة logging مفصل لـ Map |

### ملف: `file_classification_bloc.dart`

| السطر | التغيير | الوصف |
|-------|---------|-------|
| 49-52 | إضافة | طباعة بداية العملية |
| 62 | إضافة | طباعة عدد العناصر |
| 66 | إضافة | طباعة نجاح emit |
| 68 | إضافة | طباعة الأخطاء |

## كيفية الاختبار

### 1. افتح شاشة رفع PDF

في `pdf_upload_screen.dart`

### 2. اختر المدرسة، المرحلة، الشعبة، المادة

### 3. افتح الـ Console

راقب الرسائل المطبوعة

### 4. النتائج المتوقعة

#### إذا نجح:
- ✅ Status Code: 200
- ✅ قائمة بالـ FileClassifications
- ✅ عرض الأسماء والـ IDs

#### إذا فشل:
- ❌ Status Code غير 200
- ❌ رسالة خطأ واضحة
- ❌ تفاصيل الخطأ من السيرفر

## معالجة الحالات المختلفة

### 1. البيانات List مباشرة
```json
[
  {"id": "1", "name": "الفصل الأول"},
  {"id": "2", "name": "الفصل الثاني"}
]
```
✅ يتم معالجتها بشكل صحيح

### 2. البيانات داخل Object
```json
{
  "data": [
    {"id": "1", "name": "الفصل الأول"}
  ]
}
```
✅ يتم معالجتها بشكل صحيح

### 3. قائمة فارغة
```json
[]
```
✅ يتم إرجاع قائمة فارغة

### 4. خطأ من السيرفر
```json
{
  "message": "Invalid parameters"
}
```
❌ يتم عرض رسالة الخطأ

## الفرق بين القديم والجديد

| الجانب | القديم ❌ | الجديد ✅ |
|--------|----------|----------|
| **Endpoint** | `/fileclassification` | `/fileclassification/getByLevelAndClass` |
| **Parameters** | `levelSubjectId` | `LevelSubjectId` |
| **Accept Header** | `application/json` | `text/plain` |
| **Logging** | طباعة بسيطة | طباعة مفصلة جداً |
| **تحليل البيانات** | أساسي | مع تفاصيل كل عنصر |
| **معالجة الأخطاء** | عامة | مفصلة مع السبب |

## الملخص

✅ **تم تصحيح الـ endpoint ليطابق API السيرفر**  
✅ **تم تصحيح أسماء المعاملات (حرف L كبير)**  
✅ **تم تصحيح الـ accept header إلى `text/plain`**  
✅ **تم إضافة logging شامل لكل خطوة**  
✅ **تم إضافة تحليل مفصل للبيانات المستلمة**  
✅ **تم إضافة عرض أسماء وIDs كل عنصر**  

**الآن يمكنك رؤية كل التفاصيل في الـ Console!** 🎉
