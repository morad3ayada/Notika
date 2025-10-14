# إصلاح تحميل FileClassifications في شاشة PDF

## المشكلة الأساسية ❌

الشاشة **لم تكن تستدعي** `LoadFileClassificationsEvent` أصلاً!

```dart
// ❌ لا يوجد استدعاء للـ API
onTap: () {
  setState(() {
    selectedSubject = subject;
  });
},
```

**النتيجة**: لا بيانات تُجلب من السيرفر، ولا شيء يظهر في اللوج!

## الحل ✅

### 1. إضافة دالة `_loadFileClassifications`

```dart
void _loadFileClassifications(
  List<TeacherClass> classes,
  String? school,
  String? stage,
  String? section,
  String? subject,
) {
  if (school == null || stage == null || section == null || subject == null) {
    print('⚠️ لا يمكن جلب FileClassifications - بعض الاختيارات مفقودة');
    return;
  }

  // Find matching TeacherClass
  final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
    classes, school, stage, section, subject,
  );

  if (matchingClass == null) {
    print('⚠️ لم يتم العثور على الفصل المطابق');
    return;
  }

  print('🔵 تم اختيار المادة - جلب FileClassifications');
  print('   - المدرسة: $school');
  print('   - المرحلة: $stage');
  print('   - الشعبة: $section');
  print('   - المادة: $subject');

  // Dispatch LoadFileClassificationsEvent
  _fileClassificationBloc.add(LoadFileClassificationsEvent(
    levelSubjectId: matchingClass.levelSubjectId ?? '...',
    levelId: matchingClass.levelId ?? '...',
    classId: matchingClass.classId ?? '...',
  ));
}
```

### 2. استدعاء الدالة عند اختيار المادة

```dart
onTap: () {
  setState(() {
    selectedSubject = subject;
  });
  
  // ✅ جلب FileClassifications
  _loadFileClassifications(
    classes,
    selectedSchool,
    selectedStage,
    selectedSection,
    subject,
  );
},
```

### 3. معالجة البيانات المُستلمة

```dart
listener: (context, fileClassificationState) {
  // ... existing code ...
  
  else if (fileClassificationState is FileClassificationsLoaded) {
    print('✅ تم استلام FileClassifications في الشاشة');
    print('   - العدد: ${fileClassificationState.fileClassifications.length}');
    
    setState(() {
      units.clear();
      units.addAll(
        fileClassificationState.fileClassifications
            .map((fc) => fc.name)
            .toList(),
      );
    });
    
    print('📋 تم تحديث قائمة الوحدات المحلية:');
    for (var i = 0; i < units.length; i++) {
      print('   ${i + 1}. ${units[i]}');
    }
  } 
  else if (fileClassificationState is FileClassificationError) {
    print('❌ خطأ في جلب FileClassifications: ${fileClassificationState.message}');
  }
},
```

## تدفق البيانات الكامل

```
1. المستخدم يختار المادة
   ↓
2. onTap() → _loadFileClassifications()
   ↓
3. تحديد IDs من TeacherClass
   ↓
4. إرسال LoadFileClassificationsEvent إلى BLoC
   ↓
5. BLoC → Repository → HTTP GET Request
   ↓
6. السيرفر يرجع البيانات
   ↓
7. Repository يحول JSON إلى List<FileClassification>
   ↓
8. BLoC يرسل FileClassificationsLoaded
   ↓
9. BlocConsumer.listener يستقبل البيانات
   ↓
10. setState() يحدث قائمة units
   ↓
11. الـ UI تُحدّث وتظهر الوحدات
```

## Console Log المتوقع

عند اختيار المادة، ستجد:

```
🔵 تم اختيار المادة - جلب FileClassifications
   - المدرسة: مدرسة النور الأهلية
   - المرحلة: الصف الثالث الثانوي
   - الشعبة: 3/1
   - المادة: الرياضيات

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
🌐 URL: https://nouraleelemorg.runasp.net/api/fileclassification/getByLevelAndClass?...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📥 استجابة السيرفر:
   - Status Code: 200
   - Status: نجح ✅
   - Response Body:
[
  {"id":"abc","name":"الفصل الأول",...},
  {"id":"def","name":"الفصل الثاني",...}
]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 تحليل البيانات المستلمة:
   - نوع البيانات: List<dynamic>
   - البيانات عبارة عن قائمة (List)
   - عدد العناصر: 2
✅ تم تحويل 2 عنصر بنجاح
   1. الفصل الأول (ID: abc)
   2. الفصل الثاني (ID: def)

🔷 FileClassificationBloc: تم الحصول على 2 عنصر
✅ FileClassificationBloc: تم emit حالة FileClassificationsLoaded

✅ تم استلام FileClassifications في الشاشة
   - العدد: 2
📋 تم تحديث قائمة الوحدات المحلية:
   1. الفصل الأول
   2. الفصل الثاني
```

## التغييرات في الملفات

### `pdf_upload_screen.dart`

| السطر | التغيير | الوصف |
|-------|---------|-------|
| 685-725 | إضافة | دالة `_loadFileClassifications()` |
| 1186-1192 | إضافة | استدعاء `_loadFileClassifications()` عند اختيار المادة |
| 927-949 | إضافة | معالجة `FileClassificationsLoaded` و `FileClassificationError` |

### `file_classification_repository.dart`

تم إصلاحه في المرحلة السابقة - راجع `FILE_CLASSIFICATION_FIX.md`

### `file_classification_bloc.dart`

تم إصلاحه في المرحلة السابقة - راجع `FILE_CLASSIFICATION_FIX.md`

## كيفية الاختبار

### الخطوات:

1. **اعمل Hot Restart** (r في Terminal أو Shift+R)
2. افتح شاشة رفع PDF
3. اختر **مدرسة**
4. اختر **مرحلة**
5. اختر **شعبة**
6. اختر **مادة** ← **هنا يبدأ جلب البيانات!**
7. راقب الـ **Console**

### النتيجة المتوقعة:

✅ **في Console**: سترى كل الرسائل من البداية للنهاية  
✅ **في الشاشة**: عند فتح "الفصل/الوحدة"، ستجد القائمة مملوءة بالبيانات من السيرفر!

## حل المشاكل

### المشكلة: "لا يزال لا يظهر شيء"

**السبب المحتمل**: لم تعمل Hot Restart

**الحل**:
1. اضغط `r` في Terminal
2. أو اضغط Shift+R في VS Code
3. انتظر حتى يكتمل البناء

### المشكلة: "⚠️ لا يمكن جلب FileClassifications"

**السبب**: لم تختر جميع الحقول (مدرسة، مرحلة، شعبة، مادة)

**الحل**: تأكد من اختيار كل الحقول بالترتيب

### المشكلة: "⚠️ لم يتم العثور على الفصل المطابق"

**السبب**: بيانات المعلم لا تحتوي على هذه المادة

**الحل**: اختر مادة أخرى من المواد المتاحة

### المشكلة: Status Code 401

**السبب**: التوكن منتهي الصلاحية

**الحل**: سجل دخول مرة أخرى

### المشكلة: Status Code 404

**السبب**: Endpoint خاطئ (تم إصلاحه في الكود الجديد)

**الحل**: تأكد من عمل Hot Restart لتحميل الكود الجديد

## الملخص

✅ **أضفنا استدعاء LoadFileClassificationsEvent**  
✅ **أضفنا معالجة FileClassificationsLoaded**  
✅ **أضفنا logging مفصل في كل خطوة**  
✅ **البيانات الآن تُجلب من السيرفر عند اختيار المادة**  
✅ **قائمة الوحدات تُملأ تلقائياً من السيرفر**

⚠️ **لا تنسى عمل Hot Restart!**
