# تشخيص مشكلة "جاري التحقق..." الطويلة

## المشكلة
التطبيق يظل على شاشة "جاري التحقق من تسجيل الدخول..." لفترة طويلة ولا يدخل للصفحة الرئيسية.

## خطوات التشخيص

### 1. شغّل التطبيق وراقب الـ Logs

عند إعادة فتح التطبيق، راقب Debug Console وابحث عن:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 STARTING CheckSavedAuth...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. تتبع الخطوات

يجب أن ترى الخطوات التالية **بالترتيب**:

```
✓ AuthLoading emitted
📱 Step 1: Getting token...
🔑 Token result: eyJhbGciOi...
📱 Step 2: Getting organization URL...
🌐 OrgUrl result: https://...
📱 Step 3: Checking login status...
📱 isLoggedIn result: true
📱 Step 4: Loading saved auth data...
📦 Saved auth data loaded: true
📋 Saved data keys: [token, userType, profile, organizationUrl, organization]
🔄 Attempting to create LoginResponse from saved data...
📋 Full saved data: {...}
📦 Creating LoginResponse with data: [token, userType, profile, organization]
✅ LoginResponse created successfully
✅ User: ..., Type: teacher
📤 About to emit AuthSuccess...
✅✅✅ AuthSuccess state emitted successfully!
🎯 AuthSuccess should now be processed by BlocBuilder
🏁 CheckSavedAuth COMPLETED
```

ثم في الـ main.dart:

```
🎨 Building home widget - State: AuthSuccess
✅ Showing MainScreen
```

### 3. أين توقف الكود؟

ابحث في الـ logs عن **آخر رسالة ظهرت**:

#### السيناريو A: توقف عند "Step 1: Getting token..."
```
📱 Step 1: Getting token...
⏱️ getToken timeout!
```
**المشكلة:** SharedPreferences معلق أو بطيء جداً
**الحل:** 
1. امسح بيانات التطبيق من إعدادات الجهاز
2. أعد تثبيت التطبيق

#### السيناريو B: توقف عند "Attempting to create LoginResponse..."
```
🔄 Attempting to create LoginResponse from saved data...
❌ Error creating LoginResponse from saved data: ...
```
**المشكلة:** البيانات المحفوظة فاسدة
**الحل:** 
1. سجل خروج يدوياً
2. أعد تسجيل الدخول

#### السيناريو C: نجح CheckSavedAuth لكن لم يظهر MainScreen
```
✅✅✅ AuthSuccess state emitted successfully!
🎯 AuthSuccess should now be processed by BlocBuilder
🏁 CheckSavedAuth COMPLETED
```

لكن **لا يوجد**:
```
🎨 Building home widget - State: AuthSuccess
✅ Showing MainScreen
```

**المشكلة:** BlocBuilder لا يستجيب
**الحل المحتمل:** 
- مشكلة في widget tree
- أعد تشغيل التطبيق بالكامل: `flutter clean && flutter run`

#### السيناريو D: يظهر "Building home widget - State: AuthLoading" لفترة طويلة
```
🎨 Building home widget - State: AuthLoading
```
بدون أي تحديث

**المشكلة:** CheckSavedAuth لم يُستدعى أو معلق
**الحل:**
1. تأكد من أن التطبيق يعمل في Debug mode
2. أعد تشغيل التطبيق

### 4. كيفية حل المشكلة بناءً على الـ Logs

**احفظ الـ Logs كاملة** وأرسلها، مع تحديد:
1. آخر رسالة ظهرت
2. هل ظهر أي error (❌)
3. هل ظهر أي timeout (⏱️)

## إذا لم تظهر أي Logs على الإطلاق

هذا يعني:
1. التطبيق لا يعمل في Debug mode
2. Debug Console غير متصل

**الحل:**
```bash
flutter run
```

وراقب Terminal/Console للـ logs.

## Quick Fix: امسح كل شيء وابدأ من جديد

```bash
# 1. امسح التطبيق من الهاتف تماماً
# 2. نظف المشروع
flutter clean

# 3. احصل على المكتبات
flutter pub get

# 4. شغّل التطبيق
flutter run

# 5. سجل دخول من جديد
```

## الـ Timeouts المضافة

كل عملية لها timeout 3 ثوان:
- ✅ getToken: 3 seconds
- ✅ getOrganizationUrl: 3 seconds  
- ✅ getSavedAuthData: 3 seconds

إذا تجاوزت أي عملية الوقت، سيظهر في الـ logs:
```
⏱️ [operation] timeout!
```

وسيعرض شاشة تسجيل الدخول تلقائياً.
