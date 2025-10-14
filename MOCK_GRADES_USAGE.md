# استخدام بيانات الدرجات التجريبية

## 📋 الملفات المُنشأة

### 1. Model للبيانات التجريبية
**الملف**: `lib/data/models/student_grades_mock.dart`

يحتوي على:
- ✅ **StudentGradesMock**: نموذج الطالب مع درجاته
- ✅ **GradeItem**: عنصر درجة (title, grade, maxGrade)
- ✅ **QuizAttemptItem**: محاولة كويز (quizTitle, maxGrade, grade)
- ✅ **parseStudentGradesMockList()**: دالة لتحويل JSON إلى قائمة

### 2. شاشة العرض التجريبية
**الملف**: `lib/presentation/screens/grades/grades_mock_screen.dart`

واجهة كاملة لعرض البيانات تحتوي على:
- ✅ عرض الاسم الكامل (firstName + secondName + thirdName)
- ✅ عرض اسم المادة (subjectName)
- ✅ عرض عدد الغيابات (absenceTimes)
- ✅ عرض قائمة الدرجات اليومية (grades)
- ✅ عرض قائمة الاختبارات (quizAttempts)
- ✅ تصميم جميل وسهل القراءة

## 🎨 الواجهة

### مكونات الشاشة

#### 1. كارد الطالب
```
┌─────────────────────────────────────────┐
│  👤  طالب مبرمج فلاتر           الغيابات │
│      المادة: العربية               0    │
├─────────────────────────────────────────┤
│  الدرجات اليومية:                       │
│  ┌─────────────────────────────────────┐│
│  │ كويز                      10 / 10  ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │ شفوي                      20 / 20  ││
│  └─────────────────────────────────────┘│
│                                          │
│  الاختبارات:                            │
│  ┌─────────────────────────────────────┐│
│  │ اللغة العربية - اختبار منتصف الفصل ││
│  │ ████░░░░░░ 0.0%          0 / 20    ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

## 🔧 كيفية الاستخدام

### الطريقة الأولى: استخدام الشاشة الجاهزة

1. **افتح الشاشة في التطبيق**:

```dart
// في أي مكان في التطبيق
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const GradesMockScreen(),
  ),
);
```

2. **البيانات موجودة داخل الشاشة** (في `_loadMockData()`)

### الطريقة الثانية: استخدام Model في كود خاص بك

```dart
import 'package:notika_teacher/data/models/student_grades_mock.dart';
import 'dart:convert';

// JSON الخاص بك
final jsonString = '''
[
  {
    "absenceTimes": 0,
    "subjectName": "العربية",
    "grades": [
      {
        "title": "كويز",
        "grade": 10,
        "maxGrade": 10
      }
    ],
    "quizAttempts": [
      {
        "quizTitle": "اختبار 1",
        "maxGrade": 20,
        "grade": 15
      }
    ],
    "firstName": "طالب",
    "secondName": "مبرمج",
    "thirdName": "فلاتر"
  }
]
''';

// تحويل من JSON string
final List<dynamic> jsonList = json.decode(jsonString);
final students = parseStudentGradesMockList(jsonList);

// استخدام البيانات
for (final student in students) {
  print('الاسم: ${student.fullName}');
  print('المادة: ${student.subjectName}');
  print('الغيابات: ${student.absenceTimes}');
  
  for (final grade in student.grades) {
    print('${grade.title}: ${grade.grade}/${grade.maxGrade}');
  }
  
  for (final quiz in student.quizAttempts) {
    print('${quiz.quizTitle}: ${quiz.grade}/${quiz.maxGrade}');
  }
}
```

### الطريقة الثالثة: تحويل مباشر من List<dynamic>

```dart
// إذا كان لديك List<dynamic> جاهز
List<dynamic> jsonList = [
  {
    "absenceTimes": 0,
    "subjectName": "العربية",
    "grades": [...],
    "quizAttempts": [...],
    "firstName": "طالب",
    "secondName": "مبرمج",
    "thirdName": "فلاتر"
  }
];

// تحويل مباشر
final students = parseStudentGradesMockList(jsonList);
```

## 📊 صيغة JSON المدعومة

### المثال الكامل

```json
[
  {
    "absenceTimes": 0,
    "subjectName": "العربية",
    "grades": [
      {
        "title": "كويز",
        "grade": 10,
        "maxGrade": 10
      },
      {
        "title": "شفوي",
        "grade": 20,
        "maxGrade": 20
      }
    ],
    "quizAttempts": [
      {
        "quizTitle": "اللغة العربية - اختبار منتصف الفصل",
        "maxGrade": 20,
        "grade": 0
      }
    ],
    "firstName": "طالب",
    "secondName": "مبرمج",
    "thirdName": "فلاتر"
  }
]
```

### الحقول

| الحقل | النوع | مطلوب | الوصف |
|------|------|------|------|
| **absenceTimes** | int | ✅ | عدد مرات الغياب |
| **subjectName** | string | ✅ | اسم المادة |
| **grades** | array | ✅ | قائمة الدرجات اليومية |
| **quizAttempts** | array | ✅ | قائمة محاولات الاختبارات |
| **firstName** | string | ✅ | الاسم الأول |
| **secondName** | string | ✅ | الاسم الثاني |
| **thirdName** | string | ✅ | الاسم الثالث |

#### grades (عنصر واحد)

| الحقل | النوع | الوصف |
|------|------|------|
| **title** | string | عنوان الدرجة (كويز، شفوي، ...) |
| **grade** | number | الدرجة المحصلة |
| **maxGrade** | number | الدرجة الكاملة |

#### quizAttempts (عنصر واحد)

| الحقل | النوع | الوصف |
|------|------|------|
| **quizTitle** | string | عنوان الاختبار |
| **maxGrade** | number | الدرجة الكاملة |
| **grade** | number | الدرجة المحصلة |

## 🎯 أمثلة إضافية

### مثال 1: طالب مع درجات متعددة

```json
[
  {
    "absenceTimes": 2,
    "subjectName": "الرياضيات",
    "grades": [
      {"title": "واجب 1", "grade": 8, "maxGrade": 10},
      {"title": "واجب 2", "grade": 9, "maxGrade": 10},
      {"title": "مشاركة", "grade": 5, "maxGrade": 5}
    ],
    "quizAttempts": [
      {
        "quizTitle": "اختبار الجبر",
        "maxGrade": 50,
        "grade": 42
      }
    ],
    "firstName": "أحمد",
    "secondName": "محمد",
    "thirdName": "علي"
  }
]
```

### مثال 2: عدة طلاب

```json
[
  {
    "absenceTimes": 0,
    "subjectName": "العربية",
    "grades": [{"title": "كويز", "grade": 10, "maxGrade": 10}],
    "quizAttempts": [],
    "firstName": "فاطمة",
    "secondName": "حسن",
    "thirdName": "أحمد"
  },
  {
    "absenceTimes": 1,
    "subjectName": "العربية",
    "grades": [{"title": "كويز", "grade": 8, "maxGrade": 10}],
    "quizAttempts": [],
    "firstName": "محمود",
    "secondName": "علي",
    "thirdName": "حسين"
  }
]
```

## 🔍 Logging والتشخيص

### Console Output المتوقع

```
🔄 Parsing 1 student grades...
📦 StudentGradesMock.fromJson: {absenceTimes: 0, subjectName: العربية, ...}
✅ تم تحميل 1 طالب بنجاح
👤 طالب مبرمج فلاتر
   المادة: العربية
   الغيابات: 0
   الدرجات: 2
      - كويز: 10.0/10.0
      - شفوي: 20.0/20.0
   الاختبارات: 1
      - اللغة العربية - اختبار منتصف الفصل: 0.0/20.0
```

## 🎨 تخصيص الواجهة

### تغيير الألوان

في `grades_mock_screen.dart`:

```dart
// الألوان الحالية:
- اللون الأساسي: Color(0xFF1976D2) (أزرق)
- الخلفية: Color(0xFFE3F2FD) (أزرق فاتح)
- الدرجات: Color(0xFF233A5A) (أزرق داكن)
- الكويزات: Colors.purple (بنفسجي)
- الغيابات: Colors.red/Colors.green

// لتغيير اللون الأساسي:
const Color(0xFF1976D2) → const Color(0xFFYOUR_COLOR)
```

### إضافة حقول جديدة

1. أضف الحقل في Model:

```dart
// في student_grades_mock.dart
class StudentGradesMock {
  final int absenceTimes;
  final String subjectName;
  final String newField; // ← الحقل الجديد
  
  StudentGradesMock({
    required this.absenceTimes,
    required this.subjectName,
    required this.newField, // ← هنا
  });
  
  factory StudentGradesMock.fromJson(Map<String, dynamic> json) {
    return StudentGradesMock(
      // ...
      newField: json['newField'] as String? ?? '', // ← هنا
    );
  }
}
```

2. اعرضه في الواجهة:

```dart
// في grades_mock_screen.dart
Text('الحقل الجديد: ${student.newField}')
```

## 📱 الاختبار

### 1. تشغيل الشاشة التجريبية

```dart
// في main.dart أو أي ملف navigation
import 'package:notika_teacher/presentation/screens/grades/grades_mock_screen.dart';

// افتح الشاشة:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const GradesMockScreen()),
);
```

### 2. تشغيل مع بيانات مخصصة

```dart
// عدّل `_loadMockData()` في grades_mock_screen.dart
// غيّر الـ jsonString بالبيانات الخاصة بك
```

## 🚀 الخطوات التالية

### إذا أردت استخدام البيانات من API حقيقي:

1. **أنشئ Repository**:
```dart
class GradesRepository {
  Future<List<StudentGradesMock>> getGrades() async {
    final response = await apiClient.get('/grades');
    final List<dynamic> jsonList = response;
    return parseStudentGradesMockList(jsonList);
  }
}
```

2. **استخدم BLoC**:
```dart
class GradesBloc extends Bloc<GradesEvent, GradesState> {
  final GradesRepository repository;
  
  GradesBloc(this.repository) : super(GradesInitial());
  
  Stream<GradesState> mapEventToState(GradesEvent event) async* {
    if (event is LoadGrades) {
      yield GradesLoading();
      try {
        final grades = await repository.getGrades();
        yield GradesLoaded(grades);
      } catch (e) {
        yield GradesError(e.toString());
      }
    }
  }
}
```

3. **استخدمه في الشاشة**:
```dart
BlocBuilder<GradesBloc, GradesState>(
  builder: (context, state) {
    if (state is GradesLoaded) {
      return ListView.builder(
        itemCount: state.grades.length,
        itemBuilder: (context, index) {
          return _buildStudentCard(state.grades[index]);
        },
      );
    }
    // ...
  },
)
```

## ✅ الملخص

✅ **Model جاهز**: `StudentGradesMock` يطابق JSON تماماً  
✅ **Parsing جاهز**: `parseStudentGradesMockList()` لتحويل List<dynamic>  
✅ **واجهة جاهزة**: `GradesMockScreen` لعرض البيانات  
✅ **تصميم جميل**: كاردات، ألوان، أيقونات  
✅ **Logging مفصل**: لتتبع كل خطوة  
✅ **قابل للتوسع**: يمكن إضافة حقول وميزات جديدة  

**جرب الآن!** افتح `GradesMockScreen` وشاهد البيانات! 🎉
