class ApiConfig {
  // Base URLs
  static const String baseUrl = 'https://nouraleelemorg.runasp.net';
  static const String centralAuthBaseUrl = baseUrl;
  
  // Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String changePasswordEndpoint = '/api/auth/change-password';
  
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
