# Quick Tests Implementation - تطبيق الاختبارات السريعة

تم تطبيق وظيفة الاختبارات السريعة بالكامل باستخدام BLoC architecture pattern والتكامل مع API.

## الملفات المُنشأة/المُحدثة:

### 1. **QuickTestModel** (`lib/data/models/quick_tests_model.dart`)
- نموذج البيانات الكامل مع جميع الحقول المطلوبة
- `levelSubjectId`, `levelId`, `classId`, `title`, `deadline`, `questionsJson`, `answersJson`, `durationMinutes`, `maxGrade`
- `CreateQuickTestRequest` DTO للإرسال للـ API
- دعم `toJson()` و `fromJson()` مع Equatable

### 2. **QuickTestsRepository** (`lib/data/repositories/quick_tests_repository.dart`)
- Repository للتعامل مع API باستخدام http package
- POST endpoint: `/api/quiz/add`
- Headers: Authorization (token بدون Bearer), Content-Type: application/json
- معالجة شاملة للأخطاء مع رسائل عربية
- دعم `getQuickTests()` لجلب الاختبارات

### 3. **QuickTestsBloc** (`lib/logic/blocs/quick_tests/quick_tests_bloc.dart`)
- BLoC كامل مع Events و States
- `AddQuickTestEvent`, `LoadQuickTestsEvent`, `RefreshQuickTestsEvent`, `ResetQuickTestsEvent`, `ValidateQuickTestEvent`
- `QuickTestsLoading`, `QuickTestsSuccess`, `QuickTestsFailure` states
- معالجة شاملة للأخطاء والحالات المختلفة
- Helper methods لتحويل البيانات من الفورم إلى API format

### 4. **تحديث QuickTestsScreen** (`lib/presentation/screens/tests/quick_tests_screen.dart`)
- تحويل كامل من النظام القديم إلى BLoC pattern
- حقول جديدة: عنوان الاختبار، موعد الاختبار النهائي
- اختيار التاريخ والوقت للموعد النهائي
- استخدام TeacherClassMatcher للعثور على GUIDs الصحيحة
- BlocConsumer للاستماع لحالات النجاح والفشل
- Loading states مع تعطيل الزر أثناء الإرسال

### 5. **Dependency Injection** (`lib/di/injector.dart`)
- إضافة QuickTestsRepository للـ dependency injection
- تكامل مع AuthService الموجود

## المميزات الجديدة:

### 1. **حقول الفورم الكاملة:**
- **عنوان الاختبار** (مطلوب) - TextEditingController
- **موعد الاختبار** (مطلوب) - DatePicker + TimePicker
- **مدة الاختبار** (مطلوب) - بالدقائق
- **الدرجة القصوى** (مطلوب) - رقم صحيح
- **الأسئلة والإجابات** (مطلوب) - JSON format

### 2. **اختيار التاريخ والوقت:**
- DatePicker لاختيار التاريخ
- TimePicker لاختيار الوقت
- تنسيق ISO 8601 للإرسال للـ API
- عرض التاريخ والوقت بتنسيق عربي

### 3. **تكامل مع TeacherClass:**
- استخدام اختيارات المستخدم (مدرسة، مرحلة، شعبة، مادة)
- العثور على TeacherClass المطابق باستخدام TeacherClassMatcher
- استخراج GUIDs الصحيحة (levelSubjectId, levelId, classId)

### 4. **تجربة مستخدم محسنة:**
- رسائل نجاح وفشل واضحة
- Loading indicator في الزر أثناء الإرسال
- تعطيل الزر لمنع الإرسال المتكرر
- تنظيف الفورم بعد النجاح
- العودة التلقائية للشاشة السابقة بعد النجاح

## API Integration:

### **Endpoint:**
```
POST https://nouraleelemorg.runasp.net/api/quiz/add
```

### **Headers:**
```
accept: text/plain
Authorization: <التوكن المخزن بدون Bearer prefix>
Content-Type: application/json
```

### **Request Body:**
```json
{
  "levelSubjectId": "guid",
  "levelId": "guid", 
  "classId": "guid",
  "title": "عنوان الاختبار",
  "deadline": "2025-09-28T02:14:24.000Z",
  "questionsJson": "[{\"id\":1,\"type\":\"choice\",\"question\":\"السؤال\",\"options\":[\"خيار1\",\"خيار2\"]}]",
  "answersJson": "[{\"questionId\":1,\"type\":\"choice\",\"correctOption\":0}]",
  "durationMinutes": 30,
  "maxGrade": 10
}
```

## تدفق البيانات:

1. ✅ المستخدم يختار المدرسة والمرحلة والشعبة والمادة
2. ✅ المستخدم يملأ عنوان الاختبار وموعد الاختبار
3. ✅ المستخدم يحدد مدة الاختبار والدرجة القصوى
4. ✅ المستخدم ينشئ الأسئلة (اختياري، صح/خطأ، أكمل الفراغ)
5. ✅ المستخدم يضغط "إرسال الاختبار"
6. ✅ النظام يجد TeacherClass المطابق ويستخرج GUIDs
7. ✅ إرسال AddQuickTestEvent إلى QuickTestsBloc
8. ✅ QuickTestsBloc يحول الأسئلة والإجابات إلى JSON
9. ✅ QuickTestsBloc يرسل البيانات للسيرفر عبر Repository
10. ✅ عند النجاح: رسالة نجاح وتنظيف الفورم والعودة
11. ✅ عند الفشل: رسالة خطأ مفصلة

## JSON Format للأسئلة والإجابات:

### **Questions JSON:**
```json
[
  {
    "id": 1,
    "type": "choice",
    "question": "ما هو لون السماء؟",
    "options": ["أزرق", "أحمر", "أخضر", "أصفر"]
  },
  {
    "id": 2,
    "type": "truefalse",
    "question": "الأرض كروية الشكل"
  },
  {
    "id": 3,
    "type": "complete",
    "question": "عاصمة مصر هي ______"
  }
]
```

### **Answers JSON:**
```json
[
  {
    "questionId": 1,
    "type": "choice",
    "correctOption": 0
  },
  {
    "questionId": 2,
    "type": "truefalse",
    "answer": true
  },
  {
    "questionId": 3,
    "type": "complete",
    "answer": "القاهرة"
  }
]
```

## معمارية BLoC:

### **Events:**
- `AddQuickTestEvent` - إضافة اختبار جديد
- `LoadQuickTestsEvent` - تحميل جميع الاختبارات
- `RefreshQuickTestsEvent` - تحديث الاختبارات
- `ResetQuickTestsEvent` - إعادة تعيين الحالة
- `ValidateQuickTestEvent` - التحقق من صحة البيانات

### **States:**
- `QuickTestsInitial` - الحالة الأولية
- `QuickTestsLoading` - جاري التحميل
- `QuickTestsSuccess` - نجح الإرسال
- `QuickTestsFailure` - فشل الإرسال
- `QuickTestsLoaded` - تم تحميل الاختبارات
- `QuickTestsValidating` - جاري التحقق
- `QuickTestsValidationSuccess` - نجح التحقق
- `QuickTestsValidationFailure` - فشل التحقق

## الفوائد المعمارية:

- ✅ **فصل الاهتمامات**: UI, Business Logic, Data
- ✅ **قابلية الاختبار**: Business logic قابل للاختبار
- ✅ **التناسق**: متوافق مع بنية المشروع الحالية
- ✅ **إدارة الحالة**: إدارة صحيحة للحالات
- ✅ **معالجة الأخطاء**: معالجة شاملة للأخطاء وحالات التحميل
- ✅ **Dependency Injection**: تكامل مع نظام الحقن

## النتيجة النهائية:

التطبيق أصبح جاهزاً لإنشاء الاختبارات السريعة مع:
- تكامل كامل مع API
- معمارية BLoC نظيفة
- تجربة مستخدم ممتازة
- معالجة شاملة للأخطاء
- الحفاظ على الأنماط المُتبعة في المشروع

عندما يضغط المستخدم على "إرسال الاختبار"، يتم إرسال البيانات للسيرفر، وعند النجاح يتم عرض رسالة نجاح وتنظيف الفورم والعودة للشاشة السابقة تلقائياً.
