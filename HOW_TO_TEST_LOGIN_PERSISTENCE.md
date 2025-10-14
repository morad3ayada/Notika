# كيفية اختبار حفظ تسجيل الدخول - خطوات مفصلة

## ⚠️ مهم جداً: احذف التطبيق أولاً
قبل أي شيء، احذف التطبيق تماماً من الهاتف (Uninstall) لضمان البدء من الصفر.

## الخطوة 1: بناء التطبيق من جديد
```bash
flutter clean
flutter pub get
flutter run
```

## الخطوة 2: راقب الـ Logs أثناء تسجيل الدخول

عند تسجيل الدخول، يجب أن ترى في الـ Debug Console:

```
💾 Starting to save auth data...
💾 Save attempt 1/5
🔑 Token committed ✓
🌐 OrgUrl committed ✓
👤 UserData committed ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ AUTH DATA SAVED SUCCESSFULLY ON ATTEMPT 1
   - Token: eyJhbGciOi...
   - OrgUrl: https://...
   - UserData: 1234 chars
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ✅ إذا رأيت هذه الرسالة:
البيانات تم حفظها بنجاح! انتقل للخطوة 3.

### ❌ إذا رأيت:
```
⚠️ Verification failed on attempt 1
```
أو
```
❌ Failed to save auth data after 5 attempts
```

**هذا يعني أن هناك مشكلة في حفظ البيانات!**

احفظ الـ logs وأرسلها لي لأحلل المشكلة.

## الخطوة 3: اختبر إعادة فتح التطبيق

1. **أغلق التطبيق تماماً:**
   - اضغط زر Home
   - افتح قائمة المهام (Recent Apps)
   - اسحب التطبيق لأعلى لإغلاقه

2. **افتح التطبيق مرة أخرى**

3. **راقب الـ Logs عند بدء التطبيق:**

يجب أن ترى:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Notika Teacher App Starting...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Validating saved auth data...
   - Token: ✓
   - OrgUrl: ✓
   - UserData: ✓
✅ Validation successful: All auth data is valid
📊 Auth validation result: VALID ✓
✅ Restoring user session...
🔍 Checking saved auth...
🔑 getToken: Found (eyJhbGciOi...)
🌐 Saved orgUrl: https://...
📱 isLoggedIn: true
✅ Auth restored successfully for user: ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ✅ النتيجة المتوقعة:
- التطبيق يفتح مباشرة على الصفحة الرئيسية (Home)
- **لا يطلب تسجيل دخول**

### ❌ إذا طلب تسجيل دخول:
راقب الـ logs وابحث عن:

```
❌ Validation failed: ...
```
أو
```
🔍 getToken: Not found
```

**هذا يعني أن البيانات لم تُحفظ أو لم تُقرأ بشكل صحيح.**

## الخطوة 4: اختبار إعادة تشغيل الهاتف (اختياري)

1. أعد تشغيل الهاتف
2. افتح التطبيق
3. يجب أن يدخل مباشرة بدون طلب تسجيل دخول

## 🔍 تشخيص المشاكل

### المشكلة: البيانات لا تُحفظ (Commit fails)

**الأعراض:**
```
🔑 Token commit failed ✗
```

**الحلول المحتملة:**
1. تأكد من أن Android Manifest يحتوي على `allowBackup="true"`
2. جرّب على جهاز آخر
3. تأكد من وجود مساحة تخزين كافية

### المشكلة: البيانات تُحفظ لكن لا تُقرأ

**الأعراض:**
```
✅ AUTH DATA SAVED SUCCESSFULLY
```
لكن عند إعادة الفتح:
```
🔍 getToken: Not found
```

**الحلول المحتملة:**
1. قد يكون نظام Android ينظف البيانات
2. تأكد من ملف `backup_rules.xml` موجود في `android/app/src/main/res/xml/`
3. تحقق من Android Manifest

### المشكلة: البيانات تُحفظ وتُقرأ لكن يطلب تسجيل دخول

**الأعراض:**
```
✅ Validation successful: All auth data is valid
```
لكن يعرض صفحة تسجيل الدخول

**السبب المحتمل:**
مشكلة في AuthBloc - أرسل لي الـ logs كاملة

## 📝 ملاحظات مهمة

1. **الـ Logs مهمة جداً!** - راقبها دائماً
2. **اختبر على جهاز حقيقي** - المحاكي قد لا يحفظ البيانات بشكل صحيح
3. **انتظر رسالة النجاح** - "✅ AUTH DATA SAVED SUCCESSFULLY" قبل إغلاق التطبيق
4. **Debug Mode vs Release Mode** - جرب في Release mode أيضاً:
   ```bash
   flutter run --release
   ```

## 🆘 إذا لم يعمل الحل

أرسل لي:
1. الـ Logs كاملة من بداية التطبيق
2. الـ Logs عند تسجيل الدخول
3. الـ Logs عند إعادة فتح التطبيق
4. نوع الجهاز وإصدار Android/iOS
