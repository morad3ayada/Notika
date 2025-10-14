# Multi-Tenant Authentication System

## نظام المصادقة متعدد المنظمات

تم تطبيق نظام مصادقة يدعم تسجيل الدخول لمنظمات متعددة باستخدام Central Authentication Server.

## آلية العمل

### 1. الخطوة الأولى: الحصول على URL المنظمة
عند إدخال المستخدم لـ username، يتم:
- إرسال طلب إلى Central Authentication Server:
  ```
  GET https://notikacentraladmin.runasp.net/api/OrganizationAuth/GetOrganizationUrl?username={username}
  ```
- استقبال URL المنظمة الخاص بالمستخدم
- حفظ URL المنظمة في SharedPreferences
- تحديث `ApiConfig.baseUrl` ديناميكياً

### 2. الخطوة الثانية: تسجيل الدخول
باستخدام organization URL المستلم:
- إنشاء ApiClient جديد بـ baseUrl الخاص بالمنظمة
- إرسال بيانات تسجيل الدخول (username & password)
- التحقق من نوع المستخدم (Teacher only)
- حفظ بيانات المصادقة

## الملفات المُعدلة

### 1. ApiConfig (`lib/config/api_config.dart`)
```dart
// Central Authentication Server
static const String centralAuthBaseUrl = 'https://notikacentraladmin.runasp.net';

// Dynamic baseUrl - يتم تحديثه بناءً على المنظمة
static String baseUrl = defaultBaseUrl;

// Methods
static void setOrganizationBaseUrl(String url)
static void resetBaseUrl()
```

### 2. AuthModels (`lib/data/models/auth_models.dart`)
إضافة:
```dart
class OrganizationUrlResponse {
  final String organizationUrl;
  final String? organizationName;
  final String? message;
}
```

### 3. AuthService (`lib/data/services/auth_service.dart`)
Methods جديدة:
```dart
// الحصول على URL المنظمة
Future<OrganizationUrlResponse> getOrganizationUrl(String username)

// تحميل organization URL عند بدء التطبيق
static Future<void> loadSavedOrganizationUrl()

// تسجيل الدخول بخطوتين
Future<LoginResponse> login(String username, String password)
```

### 4. Main (`lib/main.dart`)
إضافة:
```dart
// تحميل organization URL المحفوظ عند بدء التطبيق
await AuthService.loadSavedOrganizationUrl();
```

## تدفق البيانات

```
1. المستخدم يدخل username
   ↓
2. GET /api/OrganizationAuth/GetOrganizationUrl?username={username}
   → Central Server: notikacentraladmin.runasp.net
   ← Response: { organizationUrl: "https://org.example.com" }
   ↓
3. حفظ organizationUrl + تحديث ApiConfig.baseUrl
   ↓
4. POST /api/auth/login
   → Organization Server: https://org.example.com
   Body: { username, password }
   ← Response: { token, userType, profile, ... }
   ↓
5. حفظ بيانات المصادقة + organizationUrl
```

## الميزات

✅ **Dynamic Base URL**: كل منظمة لها URL خاص بها
✅ **Persistent Storage**: حفظ organization URL في SharedPreferences
✅ **Auto-Load**: تحميل organization URL تلقائياً عند بدء التطبيق
✅ **Centralized Auth**: سيرفر مركزي لإدارة المنظمات
✅ **Error Handling**: معالجة شاملة للأخطاء مع رسائل عربية
✅ **Logging**: سجلات مفصلة لتتبع عملية المصادقة

## الأمان

- يتم حفظ token في SharedPreferences بشكل آمن
- يتم تنظيف baseUrl عند تسجيل الخروج
- التحقق من نوع المستخدم (Teacher only)
- معالجة آمنة للأخطاء دون تسريب معلومات حساسة

## التوافق

- ✅ يعمل مع جميع الـ APIs الموجودة
- ✅ يدعم الـ repositories الحالية
- ✅ يحافظ على نفس واجهة المستخدم
- ✅ متوافق مع BLoC pattern

## مثال الاستخدام

### في AuthBloc
```dart
// عملية تسجيل الدخول تلقائياً تتعامل مع خطوتين
final response = await _authService.login(username, password);
// الآن ApiConfig.baseUrl محدث تلقائياً لـ organization URL
```

### في أي Repository
```dart
// استخدام ApiConfig.baseUrl العادي
final client = ApiClient(baseUrl: ApiConfig.baseUrl);
// سيستخدم تلقائياً organization URL الصحيح
```

## Testing

للتجربة:
```dart
username: NORStu197473
// سيحصل تلقائياً على organization URL من Central Server
// ثم يستخدمه لتسجيل الدخول
```

## Notes

- إذا فشل الحصول على organization URL، يتم استخدام defaultBaseUrl
- يتم إعادة تعيين baseUrl عند تسجيل الخروج
- جميع الـ API calls تستخدم organization URL تلقائياً
- يتم حفظ organization URL مع بيانات المصادقة

## Future Enhancements

- [ ] Cache organization URLs للمستخدمين المتكررين
- [ ] دعم التبديل بين منظمات متعددة
- [ ] واجهة لاختيار المنظمة يدوياً (fallback)
- [ ] إدارة انتهاء صلاحية organization URLs
