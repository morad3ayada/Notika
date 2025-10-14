# دليل طباعة الطلبات والردود (API Logging)

## نظرة عامة

تم تحسين نظام طباعة الطلبات والردود في التطبيق ليكون أكثر وضوحاً وسهولة في القراءة والـ debugging.

## شكل الطباعة الجديد

### 📤 طباعة الطلب (Request)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 API REQUEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔹 Method:   POST
🔹 URL:      https://organization.com/api/auth/login
🔹 BaseURL:  https://organization.com

📋 Headers:
   Content-Type: application/json
   Accept: application/json
   Authorization: eyJhbGciOi...[hidden]

📦 Request Body:
   {
     "username": "teacher@example.com",
     "password": "********"
   }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ✅ طباعة الرد الناجح (Successful Response)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ API RESPONSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 Status:  200 OK
🔹 Method:  POST
🔹 URL:     https://organization.com/api/auth/login

📋 Response Headers:
   content-type: application/json
   content-length: 1234

📦 Response Body:
   {
     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     "userType": "teacher",
     "profile": {
       "userId": "123",
       "userName": "teacher1",
       "fullName": "أحمد محمد"
     }
   }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ❌ طباعة الرد الفاشل (Failed Response)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ API RESPONSE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 Status:  404 Not Found
🔹 Method:  GET
🔹 URL:     https://organization.com/api/session

📋 Response Headers:
   content-type: application/json

📦 Response Body:
   {
     "error": "لم يتم العثور على البيانات المطلوبة",
     "message": "Session not found"
   }
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## المعلومات المعروضة

### في الطلب (Request)
- ✅ **Method** - نوع الطلب (GET, POST, PUT, DELETE)
- ✅ **URL** - الرابط الكامل المُستخدم
- ✅ **BaseURL** - الـ base URL المُستخدم (للتأكد من organization URL)
- ✅ **Headers** - جميع الـ headers (مع إخفاء Authorization)
- ✅ **Body** - محتوى الطلب بصيغة JSON منسقة

### في الرد (Response)
- ✅ **Status Code** - رمز الحالة مع النص (200 OK, 404 Not Found, إلخ)
- ✅ **Icon** - رمز نجاح (✅) أو فشل (❌)
- ✅ **Color** - لون للحالة (🟢 نجاح / 🔴 فشل)
- ✅ **Method** - نوع الطلب
- ✅ **URL** - الرابط المُستخدم
- ✅ **Headers** - جميع الـ response headers
- ✅ **Body** - محتوى الرد بصيغة JSON منسقة

## الأمان (Security)

### إخفاء البيانات الحساسة

تلقائياً يتم إخفاء:
```dart
// Authorization header
Authorization: eyJhbGciOi...[hidden]
// بدلاً من عرض الـ token كاملاً
```

## أكواد الحالة HTTP (Status Codes)

| الكود | النص | المعنى |
|------|------|-------|
| 🟢 200 | OK | نجح الطلب |
| 🟢 201 | Created | تم الإنشاء بنجاح |
| 🟢 202 | Accepted | تم القبول |
| 🟢 204 | No Content | نجح بدون محتوى |
| 🔴 400 | Bad Request | طلب غير صالح |
| 🔴 401 | Unauthorized | غير مصرح |
| 🔴 403 | Forbidden | ممنوع |
| 🔴 404 | Not Found | غير موجود |
| 🔴 422 | Unprocessable Entity | بيانات غير صالحة |
| 🔴 429 | Too Many Requests | طلبات كثيرة جداً |
| 🔴 500 | Internal Server Error | خطأ في السيرفر |
| 🔴 502 | Bad Gateway | بوابة سيئة |
| 🔴 503 | Service Unavailable | الخدمة غير متاحة |

## كيفية استخدام Logs للـ Debugging

### 1. التحقق من baseUrl الصحيح

```
🔹 BaseURL:  https://organization.com
```
**✅ صحيح** - يوجد organization URL  
**❌ خطأ** - BaseURL فارغ أو خاطئ

### 2. التحقق من Authorization Token

```
📋 Headers:
   Authorization: eyJhbGciOi...[hidden]
```
**✅ صحيح** - يوجد Authorization header  
**❌ خطأ** - لا يوجد Authorization header (قد تحتاج login)

### 3. التحقق من Request Body

```
📦 Request Body:
   {
     "username": "teacher1",
     "password": "test123"
   }
```
تأكد من:
- جميع الحقول المطلوبة موجودة
- القيم صحيحة
- التنسيق صحيح

### 4. فهم أخطاء السيرفر

```
🔴 Status:  404 Not Found

📦 Response Body:
   {
     "error": "User not found"
   }
```
هنا المشكلة واضحة: المستخدم غير موجود

### 5. مقارنة الطلب والرد

قارن بين:
- الـ Request Body المُرسل
- الـ Response Body المُستلم
- تأكد أن الرد يحتوي على البيانات المتوقعة

## أمثلة عملية

### مثال 1: تسجيل الدخول الناجح

```
📤 REQUEST
🔹 Method:   POST
🔹 URL:      https://org.com/api/auth/login
📦 Body:     { "username": "teacher1", "password": "***" }

✅ RESPONSE
🟢 Status:  200 OK
📦 Body:     { "token": "...", "userType": "teacher" }
```
**✅ نجح** - تم الحصول على token

### مثال 2: خطأ في البيانات

```
📤 REQUEST
🔹 Method:   POST
🔹 URL:      https://org.com/api/session/add
📦 Body:     { "title": "New Session" }

❌ RESPONSE
🔴 Status:  422 Unprocessable Entity
📦 Body:     { "error": "startAt is required" }
```
**❌ خطأ** - حقل startAt مفقود

### مثال 3: مشكلة في baseUrl

```
📤 REQUEST
🔹 BaseURL:  (empty)
🔹 URL:      /api/session

❌ ERROR: No host specified in URL
```
**❌ خطأ** - baseUrl فارغ، يجب تسجيل الدخول أولاً

## نصائح للـ Debugging

1. **دائماً افحص baseURL أولاً**
   - تأكد أنه ليس فارغاً
   - تأكد أنه الـ organization الصحيح

2. **تحقق من Authorization**
   - يجب أن يظهر في جميع الطلبات المحمية
   - إذا مفقود، قد تحتاج إعادة تسجيل الدخول

3. **اقرأ Response Body بعناية**
   - رسائل الخطأ تحتوي معلومات مهمة
   - تحقق من الحقول المطلوبة

4. **قارن Status Codes**
   - 2xx = نجاح ✅
   - 4xx = خطأ من العميل ❌
   - 5xx = خطأ في السيرفر ❌

5. **استخدم Search في Console**
   - ابحث عن "📤" للطلبات
   - ابحث عن "✅" للنجاح
   - ابحث عن "❌" للأخطاء

## التفعيل/التعطيل

الـ logging يعمل **فقط في Debug Mode**:
```dart
if (kDebugMode) {
  // طباعة الـ logs
}
```

في Release Mode، لا يتم طباعة أي logs (للأداء والأمان).

## الملف المسؤول

جميع التحسينات في:
```
lib/api/api_client.dart
- _logRequest()  → طباعة الطلب
- _logResponse() → طباعة الرد
```
