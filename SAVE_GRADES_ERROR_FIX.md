# إصلاح خطأ "خطأ في البيانات الأساسية" عند حفظ الدرجات

## 🔴 المشكلة

عند الضغط على زر "حفظ الدرجات"، يظهر خطأ:
```
خطأ في البيانات الأساسية
```

## 🔍 التشخيص

### 1. Hot Restart

```bash
r
```

### 2. جرب حفظ الدرجات

افتح شاشة الدرجات → أدخل درجات → اضغط حفظ

### 3. راقب Console Log

ابحث عن:
```
═══════════════════════════════════════════════════════
📝 تحديث الدرجات اليومية بشكل جماعي
═══════════════════════════════════════════════════════
📋 بيانات الطلب الأساسية:
   - LevelId: ...
   - ClassId: ...
   - SubjectId: ...
   - Date: ...
   - عدد الطلاب: ...

📊 طالب #0:
   - StudentId: ...
   - StudentClassSubjectId: ...  ← تحقق من هذا!
   - عدد الدرجات: ...
```

---

## ⚠️ الأسباب المحتملة

### السبب 1: studentClassSubjectId = null أو 00000000

```
📊 طالب #0:
   - StudentClassSubjectId: null  ❌
   أو
   - StudentClassSubjectId: 00000000-0000-0000-0000-000000000000  ❌
```

**الحل**: راجع `BACKEND_STUDENTCLASSSUBJECTID_FIX.md` لإصلاح Backend

---

### السبب 2: LevelId أو ClassId أو SubjectId خطأ

```
📋 بيانات الطلب الأساسية:
   - LevelId: null  ❌
   - ClassId: null  ❌
   - SubjectId: null  ❌
```

**الحل**: 
- تأكد من اختيار المدرسة والمرحلة والشعبة والمادة
- راجع `VERIFY_API_PARAMETERS.md`

---

### السبب 3: Date format خطأ

```
   - Date: 2025-10-14T00:00:00.000Z  ✅ صحيح
   أو
   - Date: 14-10-2025  ❌ خطأ
```

**الحل**: تم إصلاحه - التاريخ يُرسل بصيغة ISO 8601

---

### السبب 4: DailyGrade بدون dailyGradeTitleId

```
📊 طالب #0:
   - عدد الدرجات: 2
      * Grade: 5, TitleId: null  ❌
      * Grade: 3, TitleId:   ❌
```

**الحل**: تأكد من أن كل درجة لها `dailyGradeTitleId`

---

### السبب 5: JSON structure خطأ

انظر للـ JSON المرسل:
```
📦 JSON الكامل المرسل:
{
  "levelId": "...",
  "classId": "...",
  "subjectId": "...",
  "date": "2025-10-14T00:00:00.000Z",
  "studentsDailyGrades": [...]
}
```

تأكد من أن البنية صحيحة.

---

## 📋 Response من السيرفر

### إذا كان Status Code = 400

```
❌ خطأ 400: Bad Request
📄 Response Body الكامل:
{
  "message": "...",
  "errors": {
    "SubjectId": ["SubjectId is required"],
    "StudentsDailyGrades[0].StudentClassSubjectId": ["StudentClassSubjectId is required"]
  }
}
```

**الحل**: اقرأ `errors` للتعرف على الحقل الناقص أو الخطأ

---

## ✅ Checklist للتحقق

قبل الحفظ، تأكد من:

### في البيانات الأساسية:
- [ ] **LevelId** ليس null وهو UUID صحيح
- [ ] **ClassId** ليس null وهو UUID صحيح
- [ ] **SubjectId** ليس null وهو UUID صحيح (من `matchingClass.subjectId`)
- [ ] **Date** بصيغة ISO 8601

### لكل طالب:
- [ ] **StudentId** ليس null
- [ ] **StudentClassSubjectId** ليس null وليس `00000000`
- [ ] كل درجة لها **dailyGradeTitleId**

---

## 🔧 الحلول الشائعة

### الحل 1: إصلاح studentClassSubjectId في Backend

**إذا كان `studentClassSubjectId = 00000000` في Response من `/api/dailygrade/ClassStudents`:**

راجع `BACKEND_STUDENTCLASSSUBJECTID_FIX.md` وطبق الحل في ASP.NET Core Backend.

**مثال Backend صحيح**:
```csharp
var students = await (
    from scs in _context.StudentClassSubjects
    join student in _context.Students on scs.StudentId equals student.Id
    where scs.ClassId == ClassId 
       && scs.SubjectId == SubjectId
    select new {
        StudentId = student.Id,
        StudentClassSubjectId = scs.Id,  // ✅ مضمون ليس null
        // ...
    }
).ToListAsync();
```

---

### الحل 2: التأكد من استخدام subjectId الصحيح

**في grades_screen.dart**:
```dart
_dailyGradesBloc.add(LoadClassStudentsGradesEvent(
  subjectId: matchingClass.subjectId!,  // ✅ subjectId من Profile
  levelId: matchingClass.levelId!,
  classId: matchingClass.classId!,
  date: formattedDate,
));
```

**عند الحفظ**:
```dart
final request = BulkDailyGradesRequest(
  levelId: matchingClass.levelId!,
  classId: matchingClass.classId!,
  subjectId: matchingClass.subjectId!,  // ✅ نفس subjectId
  date: selectedDate,
  studentsDailyGrades: [...],
);
```

---

### الحل 3: إضافة validation قبل الحفظ

```dart
Future<void> _saveGrades() async {
  // Validation
  if (matchingClass == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('الرجاء اختيار الفصل والمادة أولاً')),
    );
    return;
  }
  
  if (matchingClass!.subjectId == null || 
      matchingClass!.levelId == null || 
      matchingClass!.classId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: معرفات الفصل غير كاملة')),
    );
    return;
  }
  
  // تحقق من أن كل طالب له studentClassSubjectId
  final students = _currentStudents;
  for (var student in students) {
    if (student.studentClassSubjectId == null || 
        student.studentClassSubjectId == '00000000-0000-0000-0000-000000000000') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: بيانات الطلاب غير كاملة (studentClassSubjectId مفقود)')),
      );
      return;
    }
  }
  
  // الحفظ
  final request = BulkDailyGradesRequest(
    levelId: matchingClass!.levelId!,
    classId: matchingClass!.classId!,
    subjectId: matchingClass!.subjectId!,
    date: selectedDate,
    studentsDailyGrades: students,
  );
  
  final response = await _repository.updateBulkDailyGrades(request);
  
  if (response.success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message)),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message),
        duration: Duration(seconds: 5),
      ),
    );
  }
}
```

---

## 📊 مثال JSON صحيح

### Request صحيح:

```json
{
  "levelId": "7f959c2c-fac1-45f5-b47e-56b84b74a76a",
  "classId": "9dce0fd8-2971-4a34-bab9-6a78a643eca5",
  "subjectId": "0685fbc8-81f1-4317-bfe5-56144feb010d",
  "date": "2025-10-14T00:00:00.000Z",
  "studentsDailyGrades": [
    {
      "studentId": "abc-123-def-456",
      "studentClassSubjectId": "5e219eea-5abe-4c41-ade0-08de05b95900",
      "date": "2025-10-14T00:00:00.000Z",
      "grades": [
        {
          "id": null,
          "gradeTitleId": "title-123",
          "dailyGradeTitleId": "title-123",
          "title": "مشاركة",
          "grade": 5,
          "maxGrade": 5,
          "note": null,
          "date": "2025-10-14T00:00:00.000Z"
        }
      ],
      "quizAttempts": [],
      "assignmentSubmissions": [],
      "absenceTimes": 0
    }
  ]
}
```

---

## 🎯 خطوات التصحيح

### 1. تحقق من Console Log

```bash
r  # Hot Restart
```

افتح شاشة الدرجات → أدخل درجات → احفظ → **راقب Console**

### 2. ابحث عن المشكلة

- ✅ كل IDs موجودة؟
- ✅ `studentClassSubjectId` ليس `00000000`؟
- ✅ JSON structure صحيح؟

### 3. اقرأ Response من السيرفر

```
📊 استجابة السيرفر:
   - Status Code: 400
   - Response Body: {"errors": {...}}
```

### 4. طبق الحل المناسب

- إذا `studentClassSubjectId = 00000000` → أصلح Backend
- إذا `subjectId = null` → تأكد من استخدام `matchingClass.subjectId`
- إذا validation errors → أصلح البيانات المرسلة

---

## 🚀 بعد التصليح

سترى:
```
✅ تم تحديث الدرجات بنجاح
```

**والدرجات ستُحفظ في Database!** 🎉
