# إصلاح مشكلة صيغة التاريخ في API

## المشكلة

عند إرسال طلب GET إلى:
```
https://nouraleelemorg.runasp.net/api/dailygrade/ClassStudents
```

مع المعاملات:
```
SubjectId=0685fbc8-81f1-4317-bfe5-56144feb010d
LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a
ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5
Date=14-10-2025
```

السيرفر يرجع خطأ:
```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "errors": {
    "Date": ["The value '14-10-2025' is not valid for Date."]
  }
}
```

## السبب الجذري

### 1. الصيغة المستخدمة (خطأ ❌)
```dart
final formattedDate = '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}';
// النتيجة: "14-10-2025" (DD-MM-YYYY)
```

### 2. المشكلة
- ✅ معيار **ISO 8601** يتطلب: `YYYY-MM-DD`
- ❌ الصيغة `DD-MM-YYYY` **غير قياسية**
- ⚠️ السيرفر (.NET/C#) يتوقع صيغة قياسية

### 3. لماذا السيرفر رفض الصيغة؟

#### في .NET/C# (السيرفر):
```csharp
// السيرفر يحاول تحويل النص إلى DateTime
DateTime.Parse("14-10-2025") // ❌ خطأ!
DateTime.Parse("2025-10-14") // ✅ يعمل!
```

#### مشاكل صيغة `DD-MM-YYYY`:
1. **غموض**: هل `01-02-2025` يعني 1 فبراير أم 2 يناير؟
2. **غير قياسي**: ليس ISO 8601
3. **مشاكل في Sorting**: لا يمكن ترتيبها أبجدياً

## الحل

### الكود القديم (خطأ ❌)
```dart
// في grades_screen.dart - السطر 393
final formattedDate = '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}';
// النتيجة: "14-10-2025"
```

### الكود الجديد (صحيح ✅)
```dart
// تنسيق التاريخ بصيغة ISO 8601 (YYYY-MM-DD)
final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
// النتيجة: "2025-10-14"
```

### شرح الكود

```dart
selectedDate.year                           // 2025
selectedDate.month.toString().padLeft(2, '0')  // "10" (يضيف 0 للأشهر < 10)
selectedDate.day.toString().padLeft(2, '0')    // "14" (يضيف 0 للأيام < 10)
```

**أمثلة:**
- `DateTime(2025, 1, 5)` → `"2025-01-05"` ✅
- `DateTime(2025, 10, 14)` → `"2025-10-14"` ✅
- `DateTime(2025, 12, 31)` → `"2025-12-31"` ✅

## بديل أفضل: استخدام DateFormat

إذا كنت تريد حل أكثر احترافية، استخدم حزمة `intl`:

```dart
import 'package:intl/intl.dart';

// استخدام DateFormat
final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
// النتيجة: "2025-10-14"
```

**مميزات:**
- ✅ أقصر وأوضح
- ✅ يدعم صيغ متعددة
- ✅ آمن من الأخطاء

## صيغ التاريخ القياسية

### ISO 8601 (الموصى به ✅)
```
التاريخ فقط:     2025-10-14
التاريخ والوقت:  2025-10-14T14:30:00
مع المنطقة:     2025-10-14T14:30:00Z
```

### صيغ أخرى شائعة
```
RFC 3339:        2025-10-14T14:30:00+00:00
Unix Timestamp:  1760445000
```

### صيغ خاطئة (تجنبها ❌)
```
14-10-2025      // DD-MM-YYYY
10-14-2025      // MM-DD-YYYY
14/10/2025      // DD/MM/YYYY
2025.10.14      // استخدم - وليس .
```

## الاختبار

### قبل الإصلاح (خطأ):
```
GET /api/dailygrade/ClassStudents?Date=14-10-2025
Response: 400 Bad Request
```

### بعد الإصلاح (صحيح):
```
GET /api/dailygrade/ClassStudents?Date=2025-10-14
Response: 200 OK
```

## ملاحظات مهمة

### 1. للعرض في الواجهة
```dart
// للعرض للمستخدم (يمكن استخدام أي صيغة)
Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}');
// العرض: "14/10/2025" ✅ (OK للواجهة)
```

### 2. للإرسال إلى API
```dart
// للإرسال إلى السيرفر (يجب ISO 8601)
final apiDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
// النتيجة: "2025-10-14" ✅
```

### 3. قاعدة عامة
> **للعرض**: استخدم أي صيغة تناسب اللغة  
> **للـ API**: استخدم ISO 8601 دائماً

## ملخص التغييرات

| الملف | السطر | التغيير |
|-------|------|---------|
| `grades_screen.dart` | 393-394 | تحويل صيغة التاريخ من `DD-MM-YYYY` إلى `YYYY-MM-DD` |

## الكود الكامل للمرجع

```dart
void _loadGradeTitles(List<TeacherClass> classes) {
  // ... existing code ...
  
  // ✅ الكود الصحيح
  final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
  print('🔄 جلب الدرجات تلقائياً لليوم: $formattedDate');
  
  _dailyGradesBloc.add(LoadClassStudentsGradesEvent(
    subjectId: matchingClass.levelSubjectId!,
    levelId: matchingClass.levelId!,
    classId: matchingClass.classId!,
    date: formattedDate, // "2025-10-14"
  ));
}
```

## المراجع

- [ISO 8601 Standard](https://en.wikipedia.org/wiki/ISO_8601)
- [RFC 3339 (Date and Time on the Internet)](https://www.rfc-editor.org/rfc/rfc3339)
- [Flutter DateFormat Documentation](https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html)

## النتيجة النهائية

✅ **التاريخ الآن يُرسل بصيغة ISO 8601 الصحيحة**  
✅ **السيرفر يقبل الطلب بنجاح**  
✅ **لا مزيد من أخطاء 400 Bad Request**  
