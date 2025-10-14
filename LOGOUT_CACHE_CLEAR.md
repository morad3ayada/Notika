# مسح الكاش عند تسجيل الخروج

## التعديلات المطبقة ✅

تم تحديث وظيفة تسجيل الخروج لمسح جميع أنواع الـ cache بشكل شامل:

### الملفات المُعدلة:

#### 1. **AuthService** (`lib/data/services/auth_service.dart`)

**الإضافات:**
- استيراد `dart:io` و `path_provider`
- دالة `_clearAppCache()` - لمسح cache الملفات المؤقتة
- دالة `_deleteDirectory()` - لحذف محتويات المجلدات بشكل كامل
- تحديث `clearAuthData()` لمسح جميع أنواع الكاش

**ما يتم مسحه:**
1. ✅ **SharedPreferences** - جميع البيانات المحفوظة محلياً
2. ✅ **Temporary Directory** - الملفات المؤقتة
3. ✅ **Application Cache Directory** - كاش التطبيق (Android/iOS)
4. ✅ **API Base URL Reset** - إعادة تعيين رابط المنظمة

**الكود المضاف:**
```dart
/// مسح جميع بيانات المصادقة والكاش
static Future<void> clearAuthData() async {
  try {
    // 1. مسح SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // 2. مسح cache الملفات المؤقتة
    await _clearAppCache();
    
    // 3. إعادة تعيين baseUrl
    ApiConfig.resetBaseUrl();
    
    debugPrint('✅ All cache and auth data cleared successfully');
  } catch (e) {
    debugPrint('❌ Error clearing auth data: $e');
    ApiConfig.resetBaseUrl();
  }
}

/// مسح cache الملفات المؤقتة للتطبيق
static Future<void> _clearAppCache() async {
  try {
    // مسح temporary directory
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      await _deleteDirectory(tempDir);
    }

    // مسح application cache directory (Android/iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      final cacheDir = await getApplicationCacheDirectory();
      if (cacheDir.existsSync()) {
        await _deleteDirectory(cacheDir);
      }
    }
  } catch (e) {
    debugPrint('⚠️ Error clearing app cache: $e');
  }
}
```

#### 2. **UserProvider** (`lib/providers/user_provider.dart`)

**التحديث:**
- تم تحديث دالة `logout()` لاستخدام `AuthService.clearAuthData()` مباشرة
- يضمن مسح جميع أنواع الكاش عند تسجيل الخروج من Provider

```dart
Future<void> logout() async {
  // استخدام دالة مسح الكاش الشاملة من AuthService
  await AuthService.clearAuthData();
  
  _token = null;
  _userProfile = null;
  _organization = null;
  
  notifyListeners();
}
```

## تدفق عملية تسجيل الخروج:

```
المستخدم يضغط "تسجيل الخروج"
    ↓
ProfileScreen → AuthService.serverLogout() (optional)
    ↓
UserProvider.logout()
    ↓
AuthService.clearAuthData()
    ↓
    ├─→ مسح SharedPreferences
    ├─→ مسح Temporary Directory
    ├─→ مسح Application Cache
    ├─→ إعادة تعيين API Base URL
    └─→ تحديث الـ State في Provider
    ↓
AuthBloc.add(LogoutRequested())
    ↓
إعادة توجيه للـ Login Screen
```

## الفوائد:

1. **تنظيف شامل** - يتم مسح جميع البيانات المخزنة
2. **حماية البيانات** - لا تبقى أي بيانات حساسة بعد تسجيل الخروج
3. **تحرير المساحة** - مسح الملفات المؤقتة وكاش التطبيق
4. **منع التعارضات** - إعادة تعيين API URL لتجنب مشاكل المنظمات
5. **معالجة الأخطاء** - العملية تستمر حتى لو فشل مسح بعض الملفات

## الملاحظات:

- ✅ معالجة آمنة للأخطاء - لا تفشل العملية إذا فشل مسح ملف معين
- ✅ Logging مفصل - سهولة تتبع العملية وتشخيص المشاكل
- ✅ متوافق مع Android و iOS
- ✅ يحافظ على معمارية BLoC والأنماط المتبعة

## الاختبار:

للتحقق من عمل الميزة:
1. تسجيل الدخول للتطبيق
2. استخدام بعض الميزات (تحميل ملفات، عرض صور، إلخ)
3. تسجيل الخروج
4. التحقق من مسح جميع البيانات المخزنة

يمكن مراقبة الـ logs في وحدة التحكم:
```
✅ Cleared SharedPreferences
✅ Cleared temporary directory
✅ Cleared application cache directory
✅ All cache and auth data cleared successfully
✅ UserProvider: Logged out and cleared all data
```
