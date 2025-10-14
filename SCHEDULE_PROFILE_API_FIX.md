# إصلاح Endpoint الجدول لاستخدام Profile API

## المشكلة ❌

كان Schedule screen يستخدم endpoint خاطئ:
```
/api/school/TeacherClasses
```

هذا الـ endpoint يرجع أوقات **كلها أصفار**:
```json
{
  "startTime": "00:00:00",
  "endTime": "00:00:00"
}
```

## الحل ✅

تغيير الـ endpoint إلى:
```
/api/profile
```

هذا الـ endpoint يرجع الأوقات **الصحيحة**:
```json
{
  "classes": [
    {
      "startTime": "08:00:00",
      "endTime": "09:00:00"
    }
  ]
}
```

## التغييرات

### 1. تغيير الـ Endpoint

**File**: `lib\data\repositories\schedule_repository.dart`

```dart
// ❌ القديم (خطأ)
ScheduleRepository({this.endpoint = '/api/school/TeacherClasses'});

// ✅ الجديد (صحيح)
ScheduleRepository({this.endpoint = '/api/profile'});
```

### 2. تحديث Parsing Logic

```dart
// Profile API يرجع Map مع 'classes' array
if (response is Map<String, dynamic>) {
  print('   - Response is Map with keys: ${response.keys.join(", ")}');
  
  // البيانات في 'classes' key
  final classes = response['classes'];
  if (classes is List) {
    print('   - Found ${classes.length} classes in profile');
    final schedules = classes.map((e) => Schedule.fromJson(e as Map<String, dynamic>)).toList();
    print('✅ Parsed ${schedules.length} schedule items from profile');
    return schedules;
  }
}
```

## الفرق بين الـ APIs

### `/api/school/TeacherClasses` (القديم ❌)

**Response Structure**:
```json
[
  {
    "subjectName": "العربية",
    "startTime": "00:00:00",  ❌ أصفار
    "endTime": "00:00:00",    ❌ أصفار
    "day": 0
  }
]
```

**المشكلة**: الأوقات كلها `00:00:00`

### `/api/profile` (الجديد ✅)

**Response Structure**:
```json
{
  "teacherId": "...",
  "fullName": "احمد حيدر جبر",
  "classes": [
    {
      "subjectName": "العربية",
      "startTime": "08:00:00",  ✅ صحيح
      "endTime": "09:00:00",    ✅ صحيح
      "day": 0
    }
  ]
}
```

**الميزة**: الأوقات صحيحة!

## Console Log المتوقع

بعد التعديل، ستجد:

```
═══════════════════════════════════════════════════════
📅 ScheduleRepository: جلب الجدول
   - Endpoint: /api/profile
═══════════════════════════════════════════════════════
📥 Schedule Response:
   - Type: _Map<String, dynamic>
   - Response is Map with keys: teacherId, subject, classes, ...
   - Found 9 classes in profile
📅 Schedule.fromJson:
   - startTime: 08:00:00 (String)
   - endTime: 09:00:00 (String)
   🕐 Parsing time: 08:00:00 (type: String)
   ✅ Formatted time: 08:00
   🕐 Parsing time: 09:00:00 (type: String)
   ✅ Formatted time: 09:00
✅ Parsed 9 schedule items from profile
```

## النتيجة في الشاشة

**قبل ❌**:
```
الوقت: 00:00 - 00:00
```

**بعد ✅**:
```
الوقت: 08:00 - 09:00
```

## الاختبار

1. **Hot Restart** (r في Terminal)
2. افتح شاشة **الجدول**
3. **راقب Console** - يجب أن ترى:
   - `Endpoint: /api/profile`
   - `Found X classes in profile`
   - أوقات صحيحة مثل `08:00`, `09:00`
4. **تحقق من الشاشة** - يجب أن تعرض الأوقات الصحيحة

## الملخص

✅ **تغيير endpoint** من `/api/school/TeacherClasses` إلى `/api/profile`  
✅ **تحديث parsing** ليستخدم `classes` array من الـ response  
✅ **الأوقات الآن صحيحة** من Profile API  
✅ **Logging مفصل** لتتبع كل خطوة  

**جرب الآن! الأوقات يجب أن تظهر بشكل صحيح!** 🕐
