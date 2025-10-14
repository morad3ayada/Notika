# التحقق من صحة Parameters المرسلة للسيرفر

## 🎯 الهدف

التأكد من أن `SubjectId`, `LevelId`, `ClassId`, `Date` يتم أخذها من السيرفر (Profile API) وإرسالها صحيحة في طلب الدرجات.

---

## 📊 Flow المعلومات

```
1. GET /api/profile
   ↓ Response
   {
     "profile": {...},
     "classes": [
       {
         "levelSubjectId": "...",  ← SubjectId
         "levelId": "...",          ← LevelId
         "classId": "...",          ← ClassId
         ...
       }
     ]
   }

2. User يختار مدرسة → مرحلة → شعبة → مادة
   ↓

3. Flutter يبحث عن TeacherClass المطابق

4. GET /api/dailygrade/ClassStudents
   ↓ Query Parameters
   - SubjectId = levelSubjectId من Profile
   - LevelId = levelId من Profile
   - ClassId = classId من Profile
   - Date = من تاريخ المحدد (YYYY-MM-DD)
```

---

## 🧪 كيف تتحقق

### 1. Hot Restart

```bash
r
```

### 2. افتح شاشة الدرجات

### 3. راقب Console Log

#### **عند جلب Profile:**

```
📦 TeacherClass.fromJson:
   - Raw JSON keys: schoolId, schoolName, levelId, levelName, classId, className, subjectId, subjectName, levelSubjectId
   ✅ Parsed TeacherClass:
      School: مدرسة النور (ID: school-123)
      Level: المرحلة الابتدائية (ID: level-456)
      Class: الصف الأول أ (ID: class-789)
      Subject: اللغة العربية (ID: subject-abc)
      LevelSubjectId: levelsub-def
```

**تأكد من**:
- ✅ `levelId` ليس null
- ✅ `classId` ليس null
- ✅ `levelSubjectId` ليس null

#### **عند اختيار الفصل والمادة:**

```
═══════════════════════════════════════════════════════
✅ تم العثور على TeacherClass المطابق
═══════════════════════════════════════════════════════
📋 بيانات الفصل من Profile:
   - School: مدرسة النور
   - Stage: المرحلة الابتدائية
   - Section: الصف الأول أ
   - Subject: اللغة العربية

📊 المعرفات (IDs) التي سيتم إرسالها للسيرفر:
   - SubjectId (levelSubjectId): 0685fbc8-81f1-4317-bfe5-56144feb010d  ✅
   - LevelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a                      ✅
   - ClassId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5                      ✅

📅 التاريخ المحدد:
   - التاريخ الأصلي: 2025-10-14 00:00:00.000
   - التاريخ المنسق (YYYY-MM-DD): 2025-10-14                         ✅
═══════════════════════════════════════════════════════
```

**تأكد من**:
- ✅ كل ID عبارة عن UUID صحيح (ليس null أو 00000000)
- ✅ التاريخ بصيغة `YYYY-MM-DD`

#### **عند إرسال الطلب:**

```
═══════════════════════════════════════════════════════
📚 جلب درجات طلاب الفصل
═══════════════════════════════════════════════════════
📋 Parameters:
   - SubjectId: 0685fbc8-81f1-4317-bfe5-56144feb010d  ✅
   - LevelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a    ✅
   - ClassId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5    ✅
   - Date: 2025-10-14                                  ✅
🌐 Full URL: https://nouraleelemorg.runasp.net/api/dailygrade/ClassStudents?SubjectId=0685fbc8-81f1-4317-bfe5-56144feb010d&LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a&ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5&Date=2025-10-14
🔑 Token: eyJhbGciOiJIUzI1NiIs...

📨 cURL equivalent:
curl -X 'GET' \
  'https://nouraleelemorg.runasp.net/api/dailygrade/ClassStudents?SubjectId=0685fbc8-81f1-4317-bfe5-56144feb010d&LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a&ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5&Date=2025-10-14' \
  -H 'accept: text/plain' \
  -H 'Authorization: eyJhbGc...'
```

**تأكد من**:
- ✅ URL كامل وصحيح
- ✅ Parameters في URL تطابق IDs من Profile

---

## ✅ Checklist التحقق

### في Profile Response:

- [ ] `/api/profile` يرجع `classes` array
- [ ] كل `class` يحتوي على:
  - [ ] `levelSubjectId` (UUID صحيح)
  - [ ] `levelId` (UUID صحيح)
  - [ ] `classId` (UUID صحيح)
  - [ ] `schoolName`, `levelName`, `className`, `subjectName`

### في grades_screen.dart:

- [ ] `matchingClass` تم إيجاده صحيح
- [ ] `matchingClass.levelSubjectId` ليس null
- [ ] `matchingClass.levelId` ليس null
- [ ] `matchingClass.classId` ليس null

### في الطلب:

- [ ] `SubjectId` = `levelSubjectId` من Profile
- [ ] `LevelId` = `levelId` من Profile
- [ ] `ClassId` = `classId` من Profile
- [ ] `Date` بصيغة `YYYY-MM-DD`

### Response من السيرفر:

- [ ] Status Code = `200`
- [ ] Response Body يحتوي على array من الطلاب
- [ ] كل طالب يحتوي على `studentClassSubjectId`

---

## 🔍 الأخطاء الشائعة

### خطأ 1: IDs تكون null

**السبب**:
- Profile API لم يرجع البيانات صحيح
- Model parsing خطأ

**الحل**:
- راجع Response من `/api/profile`
- تأكد من أن `TeacherClass.fromJson` يقرأ الحقول صحيح

**Example صحيح من Profile**:
```json
{
  "classes": [
    {
      "schoolId": "school-123",
      "schoolName": "مدرسة النور",
      "levelId": "level-456",
      "levelName": "المرحلة الابتدائية",
      "classId": "class-789",
      "className": "الصف الأول أ",
      "subjectId": "subject-abc",
      "subjectName": "اللغة العربية",
      "levelSubjectId": "levelsub-def"  ← هذا مهم!
    }
  ]
}
```

---

### خطأ 2: matchingClass لم يتم إيجاده

**السبب**:
- User اختار مدرسة/مرحلة/شعبة/مادة غير موجودة في Profile
- الأسماء غير متطابقة (مسافات زيادة، أحرف مختلفة)

**الحل**:
```dart
// في grades_screen.dart - تم تطبيقه
matchingClass = classes.firstWhere(
  (c) =>
      c.schoolName?.trim() == selectedSchool?.trim() &&
      c.levelName?.trim() == selectedStage?.trim() &&
      c.className?.trim() == selectedSection?.trim() &&
      c.subjectName?.trim() == selectedSubject?.trim(),
);
```

---

### خطأ 3: Date بصيغة خاطئة

**الصيغة الصحيحة**: `YYYY-MM-DD`

**Examples**:
- ✅ `2025-10-14` (صحيح)
- ✅ `2025-01-05` (صحيح)
- ❌ `14-10-2025` (خطأ)
- ❌ `2025-10-1` (خطأ - يجب `2025-10-01`)
- ❌ `14/10/2025` (خطأ)

**الكود الصحيح** (تم تطبيقه):
```dart
final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
```

---

### خطأ 4: SubjectId vs LevelSubjectId

⚠️ **مهم جداً**:

في Profile API:
- `subjectId` = معرف المادة نفسها (مثل "اللغة العربية")
- `levelSubjectId` = معرف ربط المادة بالمرحلة (مثل "عربي للمرحلة الابتدائية")

في Grades API نستخدم:
- `SubjectId` = `levelSubjectId` ❗ (ليس `subjectId`)

**الكود الصحيح** (تم تطبيقه):
```dart
_dailyGradesBloc.add(LoadClassStudentsGradesEvent(
  subjectId: matchingClass.levelSubjectId!,  // ✅ levelSubjectId
  levelId: matchingClass.levelId!,
  classId: matchingClass.classId!,
  date: formattedDate,
));
```

---

## 🧪 اختبار يدوي

### 1. نسخ cURL من Console

```bash
# انسخ الـ cURL من Console Log
curl -X 'GET' \
  'https://nouraleelemorg.runasp.net/api/dailygrade/ClassStudents?SubjectId=...&LevelId=...&ClassId=...&Date=...' \
  -H 'accept: text/plain' \
  -H 'Authorization: ...'
```

### 2. شغله في Terminal

إذا نجح → Parameters صحيحة! ✅  
إذا فشل → راجع IDs

### 3. قارن Parameters

قارن IDs في cURL مع IDs في Profile Response.

---

## 📊 مثال كامل - Flow ناجح

### 1. Profile Response

```json
{
  "profile": {...},
  "classes": [
    {
      "levelSubjectId": "0685fbc8-81f1-4317-bfe5-56144feb010d",
      "levelId": "7f959c2c-fac1-45f5-b47e-56b84b74a76a",
      "classId": "9dce0fd8-2971-4a34-bab9-6a78a643eca5",
      "schoolName": "مدرسة النور",
      "levelName": "المرحلة الابتدائية",
      "className": "الصف الأول أ",
      "subjectName": "اللغة العربية"
    }
  ]
}
```

### 2. User يختار

- School: مدرسة النور
- Stage: المرحلة الابتدائية
- Section: الصف الأول أ
- Subject: اللغة العربية

### 3. Flutter يجد matchingClass

```
✅ Found match:
   levelSubjectId: 0685fbc8-81f1-4317-bfe5-56144feb010d
   levelId: 7f959c2c-fac1-45f5-b47e-56b84b74a76a
   classId: 9dce0fd8-2971-4a34-bab9-6a78a643eca5
```

### 4. Request يُرسل

```
GET /api/dailygrade/ClassStudents
  ?SubjectId=0685fbc8-81f1-4317-bfe5-56144feb010d
  &LevelId=7f959c2c-fac1-45f5-b47e-56b84b74a76a
  &ClassId=9dce0fd8-2971-4a34-bab9-6a78a643eca5
  &Date=2025-10-14
```

### 5. Response صحيح

```json
[
  {
    "studentId": "...",
    "studentClassSubjectId": "5e219eea-5abe-4c41-ade0-08de05b95900",  ✅
    "firstName": "محمد",
    ...
  }
]
```

---

## 🎯 الخلاصة

✅ **SubjectId** = `levelSubjectId` من Profile  
✅ **LevelId** = `levelId` من Profile  
✅ **ClassId** = `classId` من Profile  
✅ **Date** = المحدد من User بصيغة `YYYY-MM-DD`

**كل القيم تأتي من Profile API!** 📊

**جرب الآن وراقب Console!** 🎉
