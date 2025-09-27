/// API Endpoints for Notika Teacher App
/// Contains all static and dynamic endpoints used throughout the application
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  // ==================== AUTHENTICATION ENDPOINTS ====================
  
  /// User login endpoint
  /// POST: /api/auth/login
  static const String login = '/api/auth/login';
  
  /// User logout endpoint
  /// POST: /api/auth/logout
  static const String logout = '/api/auth/logout';
  
  /// User registration endpoint
  /// POST: /api/auth/register
  static const String register = '/api/auth/register';
  
  /// Change password endpoint
  /// PUT: /api/auth/change-password
  static const String changePassword = '/api/auth/change-password';
  
  /// Reset password endpoint
  /// POST: /api/auth/reset-password
  static const String resetPassword = '/api/auth/reset-password';
  
  /// Verify reset password token
  /// POST: /api/auth/verify-reset-token
  static const String verifyResetToken = '/api/auth/verify-reset-token';
  
  /// Refresh authentication token
  /// POST: /api/auth/refresh-token
  static const String refreshToken = '/api/auth/refresh-token';

  // ==================== PROFILE ENDPOINTS ====================
  
  /// Get user profile information
  /// GET: /api/profile
  static const String profile = '/api/profile';
  
  /// Update user profile
  /// PUT: /api/profile
  static const String updateProfile = '/api/profile';
  
  /// Get organization information
  /// GET: /api/profile/organization
  static const String organization = '/api/profile/organization';
  
  /// Upload profile picture
  /// POST: /api/profile/avatar
  static const String uploadAvatar = '/api/profile/avatar';

  // ==================== SCHOOL & CLASS ENDPOINTS ====================
  
  /// Get all classes for the teacher
  /// GET: /api/school/classes
  static const String classes = '/api/school/classes';
  
  /// Get students in a specific class
  /// GET: /api/school/ClassStudents
  static const String classStudents = '/api/school/ClassStudents';
  
  /// Get class details by ID
  /// GET: /api/school/classes/{classId}
  static String classDetails(String classId) => '/api/school/classes/$classId';
  
  /// Get subjects for a specific class
  /// GET: /api/school/classes/{classId}/subjects
  static String classSubjects(String classId) => '/api/school/classes/$classId/subjects';
  
  /// Get class schedule
  /// GET: /api/school/classes/{classId}/schedule
  static String classSchedule(String classId) => '/api/school/classes/$classId/schedule';

  // ==================== STUDENT ENDPOINTS ====================
  
  /// Get all students
  /// GET: /api/students
  static const String students = '/api/students';
  
  /// Get student details by ID
  /// GET: /api/students/{studentId}
  static String studentDetails(String studentId) => '/api/students/$studentId';
  
  /// Get student grades
  /// GET: /api/students/{studentId}/grades
  static String studentGrades(String studentId) => '/api/students/$studentId/grades';
  
  /// Get student attendance
  /// GET: /api/students/{studentId}/attendance
  static String studentAttendance(String studentId) => '/api/students/$studentId/attendance';

  // ==================== ATTENDANCE ENDPOINTS ====================
  
  /// Get attendance records
  /// GET: /api/attendance
  static const String attendance = '/api/attendance';
  
  /// Submit attendance for a class
  /// POST: /api/attendance
  static const String submitAttendance = '/api/attendance';
  
  /// Get attendance for a specific date
  /// GET: /api/attendance/date/{date}
  static String attendanceByDate(String date) => '/api/attendance/date/$date';
  
  /// Get attendance for a specific class
  /// GET: /api/attendance/class/{classId}
  static String attendanceByClass(String classId) => '/api/attendance/class/$classId';
  
  /// Update attendance record
  /// PUT: /api/attendance/{attendanceId}
  static String updateAttendance(String attendanceId) => '/api/attendance/$attendanceId';

  // ==================== QUIZ & TEST ENDPOINTS ====================
  
  /// Get all quizzes
  /// GET: /api/quizzes
  static const String quizzes = '/api/quizzes';
  
  /// Create a new quiz
  /// POST: /api/quizzes
  static const String createQuiz = '/api/quiz/add';
  
  
  /// Get quiz details by ID
  /// GET: /api/quizzes/{quizId}
  static String quizDetails(String quizId) => '/api/quizzes/$quizId';
  
  /// Update quiz
  /// PUT: /api/quizzes/{quizId}
  static String updateQuiz(String quizId) => '/api/quizzes/$quizId';
  
  /// Delete quiz
  /// DELETE: /api/quizzes/{quizId}
  static String deleteQuiz(String quizId) => '/api/quizzes/$quizId';
  
  /// Get quiz results
  /// GET: /api/quizzes/{quizId}/results
  static String quizResults(String quizId) => '/api/quizzes/$quizId/results';
  
  /// Submit quiz answers
  /// POST: /api/quizzes/{quizId}/submit
  static String submitQuizAnswers(String quizId) => '/api/quizzes/$quizId/submit';

  // ==================== GRADES & ASSIGNMENTS ENDPOINTS ====================
  
  /// Get all grades
  /// GET: /api/grades
  static const String grades = '/api/grades';
  
  /// Submit grades for students
  /// POST: /api/grades
  static const String submitGrades = '/api/grades';
  
  /// Get grades for a specific class
  /// GET: /api/grades/class/{classId}
  static String gradesByClass(String classId) => '/api/grades/class/$classId';
  
  /// Get assignments
  /// GET: /api/assignments
  static const String assignments = '/api/assignments';
  
  /// Create new assignment
  /// POST: /api/assignments
  static const String createAssignment = '/api/assignments';
  
  /// Get assignment details
  /// GET: /api/assignments/{assignmentId}
  static String assignmentDetails(String assignmentId) => '/api/assignments/$assignmentId';
  
  /// Update assignment
  /// PUT: /api/assignments/{assignmentId}
  static String updateAssignment(String assignmentId) => '/api/assignments/$assignmentId';

  // ==================== NOTIFICATION ENDPOINTS ====================
  
  /// Get all notifications
  /// GET: /api/notifications
  static const String notifications = '/api/notifications';
  
  /// Get notifications for a specific user
  /// GET: /api/notifications/user/{userId}
  static String userNotifications(String userId) => '/api/notifications/user/$userId';
  
  /// Mark notification as read
  /// PUT: /api/notifications/{notificationId}/read
  static String markNotificationRead(String notificationId) => '/api/notifications/$notificationId/read';
  
  /// Delete notification
  /// DELETE: /api/notifications/{notificationId}
  static String deleteNotification(String notificationId) => '/api/notifications/$notificationId';
  
  /// Get unread notifications count
  /// GET: /api/notifications/unread-count
  static const String unreadNotificationsCount = '/api/notifications/unread-count';
  
  /// Send notification to students
  /// POST: /api/notifications/send
  static const String sendNotification = '/api/notifications/send';

  // ==================== ORDERS & PAYMENTS ENDPOINTS ====================
  
  /// Get all orders
  /// GET: /api/orders
  static const String orders = '/api/orders';
  
  /// Create new order
  /// POST: /api/orders
  static const String createOrder = '/api/orders';
  
  /// Get order details by ID
  /// GET: /api/orders/{orderId}
  static String orderDetails(String orderId) => '/api/orders/$orderId';
  
  /// Update order status
  /// PUT: /api/orders/{orderId}/status
  static String updateOrderStatus(String orderId) => '/api/orders/$orderId/status';
  
  /// Cancel order
  /// DELETE: /api/orders/{orderId}
  static String cancelOrder(String orderId) => '/api/orders/$orderId';
  
  /// Get user's order history
  /// GET: /api/orders/user/{userId}
  static String userOrders(String userId) => '/api/orders/user/$userId';

  // ==================== REPORTS & ANALYTICS ENDPOINTS ====================
  
  /// Get attendance reports
  /// GET: /api/reports/attendance
  static const String attendanceReports = '/api/reports/attendance';
  
  /// Get grade reports
  /// GET: /api/reports/grades
  static const String gradeReports = '/api/reports/grades';
  
  /// Get class performance report
  /// GET: /api/reports/class/{classId}/performance
  static String classPerformanceReport(String classId) => '/api/reports/class/$classId/performance';
  
  /// Get student progress report
  /// GET: /api/reports/student/{studentId}/progress
  static String studentProgressReport(String studentId) => '/api/reports/student/$studentId/progress';
  
  /// Export report as PDF
  /// GET: /api/reports/{reportId}/export
  static String exportReport(String reportId) => '/api/reports/$reportId/export';

  // ==================== COMMUNICATION ENDPOINTS ====================
  
  /// Get messages/chat
  /// GET: /api/messages
  static const String messages = '/api/messages';
  
  /// Send message
  /// POST: /api/messages
  static const String sendMessage = '/api/messages';
  
  /// Get conversation with specific user
  /// GET: /api/messages/conversation/{userId}
  static String conversation(String userId) => '/api/messages/conversation/$userId';
  
  /// Get announcements
  /// GET: /api/announcements
  static const String announcements = '/api/announcements';
  
  /// Create announcement
  /// POST: /api/announcements
  static const String createAnnouncement = '/api/announcements';

  // ==================== FILE UPLOAD ENDPOINTS ====================
  
  /// Upload file
  /// POST: /api/files/upload
  static const String uploadFile = '/api/files/upload';
  
  /// Download file
  /// GET: /api/files/{fileId}/download
  static String downloadFile(String fileId) => '/api/files/$fileId/download';
  
  /// Delete file
  /// DELETE: /api/files/{fileId}
  static String deleteFile(String fileId) => '/api/files/$fileId';
  
  /// Get file metadata
  /// GET: /api/files/{fileId}/metadata
  static String fileMetadata(String fileId) => '/api/files/$fileId/metadata';

  // ==================== SETTINGS ENDPOINTS ====================
  
  /// Get app settings
  /// GET: /api/settings
  static const String settings = '/api/settings';
  
  /// Update app settings
  /// PUT: /api/settings
  static const String updateSettings = '/api/settings';
  
  /// Get user preferences
  /// GET: /api/settings/preferences
  static const String userPreferences = '/api/settings/preferences';
  
  /// Update user preferences
  /// PUT: /api/settings/preferences
  static const String updateUserPreferences = '/api/settings/preferences';

  // ==================== UTILITY METHODS ====================
  
  /// Build query string from parameters
  /// Example: buildQueryString({'page': '1', 'limit': '10'}) returns "?page=1&limit=10"
  static String buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    
    final query = params.entries
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    
    return '?$query';
  }
  
  /// Build endpoint with query parameters
  /// Example: withQuery('/api/users', {'page': '1'}) returns "/api/users?page=1"
  static String withQuery(String endpoint, Map<String, String> params) {
    return endpoint + buildQueryString(params);
  }
  
  /// Build paginated endpoint
  /// Example: paginated('/api/users', 1, 10) returns "/api/users?page=1&limit=10"
  static String paginated(String endpoint, int page, int limit) {
    return withQuery(endpoint, {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }
}
