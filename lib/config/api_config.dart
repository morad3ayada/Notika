class ApiConfig {
  // Central Authentication Server
  static const String centralAuthBaseUrl = 'https://notikacentraladmin.runasp.net';
  
  // Organization URL endpoint
  static const String getOrganizationUrlEndpoint = '/api/OrganizationAuth/GetOrganizationUrl';
  
  // Dynamic baseUrl - يتم تحديثه بعد الحصول على URL المنظمة من السيرفر
  // يجب تحميل الـ URL المحفوظ عند بدء التطبيق
  static String baseUrl = '';
  
  // Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String changePasswordEndpoint = '/api/auth/change-password';
  // Attendance / Students
  static const String classStudentsEndpoint = '/api/school/ClassStudents';
  
  // Profile Endpoints
  static const String profileEndpoint = '/api/profile';
  static const String organizationEndpoint = '/api/profile/organization';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // تحديث baseUrl الخاص بالمنظمة
  static void setOrganizationBaseUrl(String organizationUrl) {
    baseUrl = organizationUrl;
  }
  
  // إعادة تعيين baseUrl (مسح الـ URL)
  static void resetBaseUrl() {
    baseUrl = '';
  }
  
  // Get full URL for organization-specific endpoints
  static String getOrganizationAuthUrl(String orgBaseUrl, String endpoint) {
    return '$orgBaseUrl$endpoint';
  }
  
  // Error messages
  static const String noInternetMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك بالشبكة والمحاولة مرة أخرى.';
  static const String connectionTimeoutMessage = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';
  static const String serverErrorMessage = 'حدث خطأ في الخادم. يرجى المحاولة مرة أخرى لاحقًا.';
  static const String unauthorizedMessage = 'غير مصرح لك بالدخول. يرجى تسجيل الدخول مرة أخرى.';
  static const String notFoundMessage = 'لم يتم العثور على البيانات المطلوبة.';
}
