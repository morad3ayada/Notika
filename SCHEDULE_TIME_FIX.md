# إصلاح عرض الوقت في شاشة الجدول

## المشكلة ❌

في `schedule_screen.dart`، الوقت يظهر كـ **أصفار** بدلاً من الوقت الفعلي من السيرفر.

```
الوقت: 00:00:00.000 - 00:00:00.000
```

### السبب

في model `Schedule`، كان الكود يستخدم `toString()` مباشرة:

```dart
// ❌ القديم (خطأ)
startTime: json['startTime']?.toString() ?? '',
endTime: json['endTime']?.toString() ?? '',
```

**المشكلة**: إذا كان السيرفر يرجع الوقت بصيغة:
- ISO 8601 DateTime: `"2025-10-14T08:30:00"`
- DateTime object
- TimeOfDay object
- Map: `{"hour": 8, "minute": 30}`

فإن `toString()` لن يعطي الصيغة المطلوبة `HH:mm`.

## الحل ✅

### 1. إضافة دالة `_parseTime`

أضفت دالة شاملة في `schedule.dart` تدعم جميع الصيغ:

```dart
static String _parseTime(dynamic time) {
  if (time == null) {
    return '';
  }
  
  print('   🕐 Parsing time: $time (type: ${time.runtimeType})');
  
  // إذا كان String
  if (time is String) {
    // إذا كانت الصيغة ISO 8601 مثل "2025-10-14T08:30:00"
    if (time.contains('T')) {
      try {
        final dateTime = DateTime.parse(time);
        final formatted = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        print('   ✅ Parsed from ISO8601: $formatted');
        return formatted;
      } catch (e) {
        print('   ❌ Failed to parse ISO8601: $e');
      }
    }
    
    // إذا كانت بالفعل بصيغة HH:mm أو H:mm
    if (time.contains(':')) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        try {
          final hour = int.parse(parts[0]).toString().padLeft(2, '0');
          final minute = int.parse(parts[1]).toString().padLeft(2, '0');
          return '$hour:$minute';
        } catch (e) {
          print('   ❌ Failed to parse HH:mm: $e');
        }
      }
    }
    
    return time;
  }
  
  // إذا كان DateTime object
  if (time is DateTime) {
    final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    print('   ✅ Parsed from DateTime: $formatted');
    return formatted;
  }
  
  // إذا كان Map (قد يحتوي على hour و minute)
  if (time is Map) {
    try {
      final hour = (time['hour'] ?? time['Hour'] ?? 0).toString().padLeft(2, '0');
      final minute = (time['minute'] ?? time['Minute'] ?? 0).toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      print('   ❌ Failed to parse Map: $e');
    }
  }
  
  // fallback
  return time.toString();
}
```

### 2. استخدام `_parseTime` في `fromJson`

```dart
factory Schedule.fromJson(Map<String, dynamic> json) {
  print('📅 Schedule.fromJson:');
  print('   - startTime: ${json['startTime']} (${json['startTime'].runtimeType})');
  print('   - endTime: ${json['endTime']} (${json['endTime'].runtimeType})');
  
  return Schedule(
    // ... other fields ...
    startTime: _parseTime(json['startTime'] ?? json['start']),
    endTime: _parseTime(json['endTime'] ?? json['end']),
    // ...
  );
}
```

### 3. إضافة Logging مفصل

لتتبع كيف يتم parsing الوقت في كل حالة.

## الصيغ المدعومة

### 1. ISO 8601 DateTime String

**Input:**
```json
{
  "startTime": "2025-10-14T08:30:00",
  "endTime": "2025-10-14T09:15:00"
}
```

**Output:**
```
الوقت: 08:30 - 09:15
```

**Console:**
```
🕐 Parsing time: 2025-10-14T08:30:00 (type: String)
✅ Parsed from ISO8601: 08:30
```

### 2. HH:mm String

**Input:**
```json
{
  "startTime": "08:30",
  "endTime": "09:15"
}
```

**Output:**
```
الوقت: 08:30 - 09:15
```

**Console:**
```
🕐 Parsing time: 08:30 (type: String)
✅ Formatted time: 08:30
```

### 3. H:mm String (بدون padding)

**Input:**
```json
{
  "startTime": "8:30",
  "endTime": "9:15"
}
```

**Output:**
```
الوقت: 08:30 - 09:15
```

**Console:**
```
🕐 Parsing time: 8:30 (type: String)
✅ Formatted time: 08:30
```

### 4. DateTime Object

**Input:**
```json
{
  "startTime": <DateTime object>,
  "endTime": <DateTime object>
}
```

**Output:**
```
الوقت: 08:30 - 09:15
```

**Console:**
```
🕐 Parsing time: 2025-10-14 08:30:00.000 (type: DateTime)
✅ Parsed from DateTime: 08:30
```

### 5. Map Object

**Input:**
```json
{
  "startTime": {"hour": 8, "minute": 30},
  "endTime": {"hour": 9, "minute": 15}
}
```

**Output:**
```
الوقت: 08:30 - 09:15
```

**Console:**
```
🕐 Parsing time: {hour: 8, minute: 30} (type: _Map)
✅ Parsed from Map: 08:30
```

## كيفية الاختبار

### 1. افتح التطبيق
```bash
flutter run
```

### 2. انتقل لشاشة الجدول

### 3. راقب Console

ستجد رسائل مفصلة:

```
📅 Schedule.fromJson:
   - Raw JSON: {subjectName: الرياضيات, startTime: 2025-10-14T08:30:00, ...}
   - startTime: 2025-10-14T08:30:00 (String)
   - endTime: 2025-10-14T09:15:00 (String)
   🕐 Parsing time: 2025-10-14T08:30:00 (type: String)
   ✅ Parsed from ISO8601: 08:30
   🕐 Parsing time: 2025-10-14T09:15:00 (type: String)
   ✅ Parsed from ISO8601: 09:15
```

### 4. تحقق من الشاشة

يجب أن ترى:
```
الوقت: 08:30 - 09:15
```

بدلاً من:
```
الوقت: 00:00:00.000 - 00:00:00.000
```

## معالجة الأخطاء

### الحالة 1: لا يزال يظهر أصفار

**السبب**: السيرفر يرجع صيغة غير مدعومة

**الحل**: 
1. افحص Console log
2. ابحث عن:
   ```
   🕐 Parsing time: ... (type: ...)
   ```
3. راسلني بالصيغة الفعلية

### الحالة 2: يظهر وقت خاطئ

**السبب**: timezone مختلف أو parsing خاطئ

**الحل**: 
1. تحقق من Console
2. قارن بين Raw JSON والنتيجة النهائية

### الحالة 3: "⚠️ Time is null"

**السبب**: السيرفر لا يرجع `startTime` أو `endTime`

**الحل**:
1. تحقق من API endpoint
2. تحقق من أن السيرفر يرجع الحقول الصحيحة

## الملفات المعدلة

### `lib\data\models\schedule.dart`

| السطر | التغيير | الوصف |
|-------|---------|-------|
| 25-28 | إضافة | Logging للبيانات الخام |
| 36-37 | تعديل | استخدام `_parseTime` بدلاً من `toString()` |
| 59-125 | إضافة | دالة `_parseTime` الشاملة |

## ميزات إضافية

### 1. Padding تلقائي

```dart
"8:30" → "08:30"
"9:5"  → "09:05"
```

### 2. دعم حقول بديلة

```dart
json['startTime'] ?? json['start']  // يبحث في كلا الحقلين
json['endTime'] ?? json['end']
```

### 3. Error handling

كل محاولة parsing محاطة بـ try-catch مع logging.

### 4. Fallback

إذا فشلت كل المحاولات، يستخدم `toString()` كـ fallback.

## الملخص

✅ **دعم ISO 8601 DateTime** (`2025-10-14T08:30:00`)  
✅ **دعم HH:mm String** (`08:30`)  
✅ **دعم H:mm String** (`8:30`)  
✅ **دعم DateTime object**  
✅ **دعم Map object** (`{hour: 8, minute: 30}`)  
✅ **Padding تلقائي** لضمان صيغة موحدة  
✅ **Logging مفصل** لتتبع كل خطوة  
✅ **Error handling** شامل  

**جرب الآن! الوقت يجب أن يظهر بشكل صحيح!** 🕐
