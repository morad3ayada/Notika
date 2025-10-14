# إصلاح مشكلة "no host specified in URL /api/"

## المشكلة

عند فتح الشاشات التالية، كان يظهر خطأ:
```
Invalid arguments: No host specified in URL /api/...
```

**الشاشات المتأثرة:**
- assignments_screen.dart
- student_attendance_screen.dart
- exam_questions_screen.dart
- grades_screen.dart
- pdf_upload_screen.dart
- quick_tests_screen.dart
- conferences_screen.dart

## السبب الجذري

### السيناريو الذي يسبب المشكلة:

1. **عند بدء التطبيق:**
   ```
   main.dart → validateSavedAuth() → isValidAuth = true
   main.dart → loadSavedOrganizationUrl() → ApiConfig.baseUrl تم تحديثه ✅
   ```

2. **ثم يتم استدعاء:**
   ```
   AuthBloc → CheckSavedAuth event
   AuthBloc → getSavedAuthData() → emit(AuthSuccess)
   ```

3. **المشكلة:**
   - في `main.dart` يتم تحميل organization URL ✅
   - لكن في `AuthBloc._onCheckSavedAuth()` **لا يتم** تحميل organization URL ❌
   - إذا تم استدعاء `CheckSavedAuth` event في وقت آخر (مثلاً بعد hot restart)
   - `ApiConfig.baseUrl` يكون فارغ!

### الكود المسبب للمشكلة:

```dart
// في auth_bloc.dart - _onCheckSavedAuth()
final response = LoginResponse(...);
emit(AuthSuccess(response));
// ❌ لم يتم تحميل organization URL!
```

### النتيجة:

```dart
// في أي repository
String get baseUrl => '${ApiConfig.baseUrl}/api';
// ApiConfig.baseUrl = '' (فارغ!)
// النتيجة: '/api' فقط بدون host
// الخطأ: No host specified in URL /api/
```

## الحل

### إضافة تحميل organization URL في AuthBloc

```dart
// في auth_bloc.dart - _onCheckSavedAuth()
debugPrint('✓ Data valid');

// ✅ تحميل organization URL المحفوظ وتحديث ApiConfig
debugPrint('📱 Step 5: Loading organization URL...');
await auth_service.AuthService.loadSavedOrganizationUrl();
debugPrint('✅ Organization URL loaded and set in ApiConfig');

// Create a LoginResponse from saved data
final response = LoginResponse(...);
emit(AuthSuccess(response));
```

### كيف يعمل `loadSavedOrganizationUrl()`

```dart
// في auth_service.dart
static Future<void> loadSavedOrganizationUrl() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final orgUrl = prefs.getString(orgUrlKey);
    
    if (orgUrl != null && orgUrl.isNotEmpty) {
      ApiConfig.setOrganizationBaseUrl(orgUrl); // ✅ تحديث baseUrl
      debugPrint('✅ Loaded saved organization URL: $orgUrl');
    } else {
      ApiConfig.resetBaseUrl();
      debugPrint('⚠️ No saved organization URL found');
    }
  } catch (e) {
    debugPrint('❌ Error loading organization URL: $e');
    ApiConfig.resetBaseUrl();
  }
}
```

## تدفق العمل الصحيح الآن

### 1. بدء التطبيق (App Start)
```
main.dart:
  → validateSavedAuth() ✅
  → loadSavedOrganizationUrl() ✅ (ApiConfig.baseUrl = "https://org.com")

AuthBloc:
  → CheckSavedAuth event
  → loadSavedOrganizationUrl() ✅ (تأكيد إضافي)
  → emit(AuthSuccess) ✅
```

### 2. تسجيل الدخول (Login)
```
AuthBloc:
  → LoginRequested event
  → login(username, password)
    → clearAuthData() (مسح baseUrl)
    → fetchOrganizationUrl() (الحصول على URL جديد)
    → setOrganizationBaseUrl() ✅ (تحديث ApiConfig.baseUrl)
    → emit(AuthSuccess) ✅
```

### 3. Hot Restart
```
main.dart: 
  → validateSavedAuth() ✅
  → loadSavedOrganizationUrl() ✅

AuthBloc:
  → CheckSavedAuth event (triggered by AuthInitializer)
  → loadSavedOrganizationUrl() ✅ (حماية إضافية!)
  → emit(AuthSuccess) ✅
```

### 4. استخدام أي repository
```dart
// في أي repository
String get baseUrl => '${ApiConfig.baseUrl}/api';
// ApiConfig.baseUrl = "https://organization.com" ✅
// النتيجة: "https://organization.com/api" ✅
// يعمل بشكل صحيح! ✅
```

## الملفات المُعدلة

1. **lib/logic/blocs/auth/auth_bloc.dart**
   - ✅ إضافة `loadSavedOrganizationUrl()` في `_onCheckSavedAuth()`

## الفرق بين main.dart و AuthBloc

| الموقع | متى يُنفذ | الغرض |
|--------|----------|-------|
| **main.dart** | عند بدء التطبيق فقط | تحميل baseUrl الأولي |
| **AuthBloc** | عند CheckSavedAuth event | تحميل baseUrl عند استعادة الجلسة |

**لماذا نحتاج الاثنين؟**
- `main.dart` → للحماية عند بدء التطبيق الأولي
- `AuthBloc` → للحماية عند hot restart أو أي استدعاء آخر لـ CheckSavedAuth

## النتيجة

✅ **ApiConfig.baseUrl دائماً محدث بشكل صحيح**  
✅ **جميع الشاشات تعمل بدون خطأ "no host specified"**  
✅ **hot restart يعمل بدون مشاكل**  
✅ **حماية مزدوجة (main.dart + AuthBloc)**  

## اختبار الإصلاح

```bash
# 1. سجل دخول
# 2. اذهب لأي شاشة (assignments, attendance, etc.)
# 3. اعمل hot restart (r)
# 4. يجب أن تعمل الشاشة بدون أخطاء ✅
```
