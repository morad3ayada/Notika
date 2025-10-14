# إصلاح مشكلة بقاء Organization URL القديم بعد تسجيل الخروج

## المشكلة

عند تسجيل الخروج ثم تسجيل الدخول بحساب آخر، كان التطبيق يستمر في استخدام organization URL القديم، مما يؤدي لخطأ "user not found".

## السبب الجذري

### 1. **ApiClient كان Singleton مع baseUrl ثابت**
```dart
// في injector.dart - الكود القديم
sl.registerLazySingleton<ApiClient>(() => ApiClient(baseUrl: ApiConfig.baseUrl));
```

المشكلة:
- يتم إنشاء ApiClient **مرة واحدة فقط** عند بدء التطبيق
- يأخذ قيمة `ApiConfig.baseUrl` في وقت الإنشاء فقط
- حتى لو تغير `ApiConfig.baseUrl` بعد logout/login، ApiClient يستمر باستخدام URL القديم!

### 2. **login() لم يمسح SharedPreferences القديم**
```dart
// الكود القديم
ApiConfig.resetBaseUrl(); // يمسح ApiConfig فقط
// لكن لا يمسح SharedPreferences!
```

المشكلة:
- كان يتم reset الـ ApiConfig.baseUrl فقط
- لكن organization URL القديم يبقى محفوظ في SharedPreferences
- إذا حصل أي خطأ، قد يُعاد تحميل URL القديم

## الحل

### 1. **إزالة ApiClient من Dependency Injection**
```dart
// في injector.dart - الكود الجديد
// تم إزالة تسجيل ApiClient كـ Singleton
// سيتم إنشاء ApiClient ديناميكياً في كل repository/service
```

**لماذا؟**
- الآن كل repository/service ينشئ ApiClient جديد في كل مرة
- يستخدم القيمة **الحالية** لـ `ApiConfig.baseUrl`
- إذا تغير baseUrl، كل الطلبات الجديدة تستخدم URL الجديد تلقائياً

### 2. **مسح SharedPreferences بالكامل قبل Login**
```dart
// في auth_service.dart - دالة login()
await clearAuthData(); // مسح كل البيانات القديمة
debugPrint('✅ Old auth data cleared');

// ثم الحصول على organization URL جديد
final orgUrlResponse = await fetchOrganizationUrl(username);
```

**لماذا؟**
- يضمن مسح organization URL القديم **قبل** تسجيل الدخول
- يمنع أي تداخل بين حسابات مختلفة
- يبدأ من صفحة نظيفة في كل مرة

### 3. **تحويل Repositories لاستخدام ApiClient ديناميكي**

#### ConferencesRepository
```dart
// قبل
final ApiClient _apiClient;
ConferencesRepository(this._apiClient);

// بعد
ApiClient get _apiClient => ApiClient(baseUrl: ApiConfig.baseUrl);
ConferencesRepository();
```

#### ScheduleRepository
```dart
// قبل
final ApiClient _client;
ScheduleRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.baseUrl);

// بعد
ApiClient get _client => ApiClient(baseUrl: ApiConfig.baseUrl);
ScheduleRepository();
```

**لماذا getter؟**
- `get _apiClient` يُنفذ في **كل مرة** يتم استدعاؤه
- يُنشئ ApiClient جديد مع `ApiConfig.baseUrl` **الحالي**
- يضمن دائماً استخدام الـ URL الصحيح

## السيناريو المُصلح

### 1. **تسجيل دخول بحساب A**
```
1. clearAuthData() → مسح كل البيانات القديمة
2. fetchOrganizationUrl(userA) → الحصول على URL_A
3. حفظ URL_A في SharedPreferences
4. تحديث ApiConfig.baseUrl = URL_A
5. جميع ApiClient الجديدة تستخدم URL_A ✅
```

### 2. **تسجيل خروج**
```
1. clearAuthData() → مسح SharedPreferences + ApiConfig.baseUrl = ''
2. emit(AuthInitial) → العودة لشاشة تسجيل الدخول
```

### 3. **تسجيل دخول بحساب B**
```
1. clearAuthData() → مسح أي بقايا (تأكيد إضافي)
2. fetchOrganizationUrl(userB) → الحصول على URL_B (جديد!)
3. حفظ URL_B في SharedPreferences
4. تحديث ApiConfig.baseUrl = URL_B
5. جميع ApiClient الجديدة تستخدم URL_B ✅
```

## الملفات المُعدلة

1. **lib/di/injector.dart**
   - ✅ إزالة ApiClient من dependency injection
   - ✅ تحويل AuthRepository لـ Factory بدلاً من Singleton
   - ✅ تحديث ConferencesRepository لعدم تمرير ApiClient

2. **lib/data/services/auth_service.dart**
   - ✅ إضافة `clearAuthData()` في بداية `login()`

3. **lib/data/repositories/conferences_repository.dart**
   - ✅ تحويل `_apiClient` من field إلى getter
   - ✅ إزالة ApiClient من constructor

4. **lib/data/repositories/schedule_repository.dart**
   - ✅ تحويل `_client` من field إلى getter
   - ✅ إزالة ApiClient من constructor parameters

## النتيجة

✅ **تسجيل الخروج يمسح organization URL بالكامل**  
✅ **تسجيل الدخول بحساب جديد يستخدم organization URL الجديد فقط**  
✅ **لا توجد تداخلات بين حسابات مختلفة**  
✅ **جميع API requests تستخدم الـ URL الصحيح دائماً**  

## ملاحظات مهمة

### Singleton vs Factory vs Getter

- **Singleton Field** ❌ - يُنشأ مرة واحدة ولا يتغير
  ```dart
  final ApiClient _client = ApiClient(baseUrl: ApiConfig.baseUrl);
  ```

- **Factory/Constructor** ⚠️ - يُنشأ عند إنشاء الـ repository (قد يكون قديم)
  ```dart
  final ApiClient _client;
  Repository() : _client = ApiClient(baseUrl: ApiConfig.baseUrl);
  ```

- **Getter** ✅ - يُنشأ في كل استخدام بالقيمة الحالية
  ```dart
  ApiClient get _client => ApiClient(baseUrl: ApiConfig.baseUrl);
  ```

### Repositories التي تستخدم getter الآن

جميع الـ repositories التالية تستخدم `get baseUrl => '${ApiConfig.baseUrl}/api'`:
- AllStudentsRepository
- AssignmentRepository
- ChatRepository
- ClassStudentsRepository
- ConversationsRepository
- DailyGradeTitlesRepository
- DailyGradesRepository
- ExamScheduleRepository
- ExamQuestionsRepository
- FileClassificationRepository
- NotificationsRepository
- TeacherClassSettingsRepository
- AttendanceRepository
- QuickTestsRepository

هذا النمط **صحيح** لأنه يُقيّم `ApiConfig.baseUrl` في كل مرة يُستخدم فيها!
