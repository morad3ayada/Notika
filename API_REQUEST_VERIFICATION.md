# التحقق من طلبات API

## 🎯 الهدف

التأكد من أن Flutter يرسل الطلبات بنفس صيغة cURL المتوقعة من Swagger.

## 📋 مثال الطلب المتوقع (من Swagger)

```bash
curl -X 'GET' \
  'https://nouraleelemorg.runasp.net/api/dailygrade/ClassStudents?SubjectId=0685fbc8-81f1-4317-bfe5-56144feb010d&LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a&ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5&Date=2025-10-14' \
  -H 'accept: text/plain' \
  -H 'Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

### المكونات:
- ✅ **Method**: `GET`
- ✅ **URL**: `/api/dailygrade/ClassStudents`
- ✅ **Query Parameters**:
  - `SubjectId`: UUID
  - `LevelId`: UUID
  - `ClassId`: UUID
  - `Date`: `YYYY-MM-DD` (مثل: `2025-10-14`)
- ✅ **Headers**:
  - `accept: text/plain`
  - `Authorization: Bearer token`

## 🔍 كيف تتحقق من الطلب في Flutter

### 1. شغل Hot Restart

```bash
r
```

### 2. افتح شاشة الدرجات

1. اختر **مدرسة**
2. اختر **مرحلة**
3. اختر **شعبة**
4. اختر **مادة**
5. الطلب سيُرسل تلقائياً

### 3. راقب Console Log

سترى output مثل هذا:

```
═══════════════════════════════════════════════════════
📚 جلب درجات طلاب الفصل
═══════════════════════════════════════════════════════
📋 Parameters:
   - SubjectId: 0685fbc8-81f1-4317-bfe5-56144feb010d
   - LevelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a
   - ClassId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5
   - Date: 2025-10-14
🌐 Full URL: https://nouraleelemorg.runasp.net/api/dailygrade/ClassStudents?SubjectId=0685fbc8-81f1-4317-bfe5-56144feb010d&LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a&ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5&Date=2025-10-14
🔑 Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOi...

📨 cURL equivalent:
curl -X 'GET' \
  'https://nouraleelemorg.runasp.net/api/dailygrade/ClassStudents?SubjectId=0685fbc8-81f1-4317-bfe5-56144feb010d&LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a&ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5&Date=2025-10-14' \
  -H 'accept: text/plain' \
  -H 'Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'

🚀 إرسال الطلب...
📊 كود الاستجابة: 200
```

## ✅ التحقق من المطابقة

### قارن بين Flutter و Swagger:

| العنصر | Swagger | Flutter | المطابقة |
|--------|---------|---------|----------|
| **Method** | `GET` | `GET` | ✅ |
| **Base URL** | `https://nouraleelemorg.runasp.net` | من `ApiConfig.baseUrl` | ✅ |
| **Endpoint** | `/api/dailygrade/ClassStudents` | `/api/dailygrade/ClassStudents` | ✅ |
| **SubjectId** | UUID | من `matchingClass.levelSubjectId` | ✅ |
| **LevelId** | UUID | من `matchingClass.levelId` | ✅ |
| **ClassId** | UUID | من `matchingClass.classId` | ✅ |
| **Date** | `2025-10-14` | `YYYY-MM-DD` formatted | ✅ |
| **Accept** | `text/plain` | `text/plain` | ✅ |
| **Authorization** | `Bearer token` | من `AuthService.getToken()` | ✅ |

## 🐞 استكشاف الأخطاء

### المشكلة 1: URL مختلف

**التحقق**:
```
🌐 Full URL: https://...
```

**إذا كان مختلفاً**:
- تأكد من `ApiConfig.baseUrl` في `lib/config/api_config.dart`
- تأكد من أن الـ parameters صحيحة

### المشكلة 2: Parameters خاطئة

**التحقق**:
```
📋 Parameters:
   - SubjectId: ...
   - LevelId: ...
   - ClassId: ...
   - Date: ...
```

**إذا كانت خاطئة**:
- تأكد من اختيار المادة والفصل الصحيح
- تأكد من `TeacherClass` يحتوي على IDs صحيحة

### المشكلة 3: التاريخ بصيغة خاطئة

**الصيغة الصحيحة**: `YYYY-MM-DD` (مثل: `2025-10-14`)

**تُنسق في الكود**:
```dart
final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
```

**أمثلة**:
- ✅ `2025-10-14` (صحيح)
- ✅ `2025-01-05` (صحيح)
- ❌ `14-10-2025` (خطأ)
- ❌ `2025-10-1` (خطأ - يجب `2025-10-01`)

### المشكلة 4: Token منتهي أو خطأ

**التحقق**:
```
🔑 Token: eyJhbGciOiJIUzI1NiIs...
```

**إذا كان**:
- فارغ أو null → سجل دخول مرة أخرى
- `401 Unauthorized` → Token منتهي، سجل دخول مرة أخرى

## 📊 Status Codes المتوقعة

| Code | المعنى | التعليق |
|------|--------|----------|
| **200** | نجح | ✅ البيانات رجعت بنجاح |
| **401** | Unauthorized | Token منتهي أو خطأ |
| **404** | Not Found | لا توجد بيانات |
| **400** | Bad Request | Parameters خاطئة |
| **500** | Server Error | خطأ في السيرفر |

## 🧪 اختبار يدوي بـ cURL

يمكنك نسخ الـ cURL من Console ولصقه في Terminal:

```bash
# انسخ الـ cURL من Console Log
curl -X 'GET' \
  'https://nouraleelemorg.runasp.net/api/dailygrade/ClassStudents?...' \
  -H 'accept: text/plain' \
  -H 'Authorization: eyJhbGci...'
```

إذا نجح في Terminal ولم ينجح في Flutter → المشكلة في Flutter  
إذا فشل في كلاهما → المشكلة في Backend

## 🔧 تصحيح مشاكل شائعة

### مشكلة: Response 200 لكن studentClassSubjectId = 00000000

**السبب**: Backend يرجع `Guid.Empty`

**الحل**: راجع Backend code (راجع التوثيق السابق عن ASP.NET Core)

### مشكلة: Date format خطأ

**في grades_screen.dart**:
```dart
// ✅ الصيغة الصحيحة (موجودة)
final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

// ❌ خطأ (لا تستخدم)
final formattedDate = DateFormat('d-M-yyyy').format(selectedDate);  // خطأ!
```

### مشكلة: Parameters من Profile بدلاً من Grades

تأكد من استخدام الـ IDs الصحيحة:

```dart
// ✅ صحيح
_dailyGradesBloc.add(LoadClassStudentsGradesEvent(
  subjectId: matchingClass.levelSubjectId!,  // من TeacherClass
  levelId: matchingClass.levelId!,
  classId: matchingClass.classId!,
  date: formattedDate,
));

// ❌ خطأ
_dailyGradesBloc.add(LoadClassStudentsGradesEvent(
  subjectId: profile.teacherId,  // خطأ!
  // ...
));
```

## 📝 Checklist للتحقق

قبل أن تقول "الطلب غير صحيح"، تأكد من:

- [ ] **Hot Restart** تم
- [ ] **Console Log** يعرض الطلب كاملاً
- [ ] **URL** يطابق Swagger تماماً
- [ ] **Parameters** كلها UUIDs صحيحة (ليست `00000000`)
- [ ] **Date** بصيغة `YYYY-MM-DD`
- [ ] **Token** موجود وليس منتهي
- [ ] **Status Code** `200`
- [ ] **Response Body** يحتوي على بيانات

## 🎯 الخلاصة

الكود الآن يطبع **نفس cURL** الذي تستخدمه في Swagger!

فقط:
1. ✅ Hot Restart
2. ✅ افتح شاشة الدرجات
3. ✅ راقب Console
4. ✅ قارن cURL المطبوع مع Swagger

**إذا كان cURL مطابق لكن النتيجة مختلفة → المشكلة في Backend!** 🎯
