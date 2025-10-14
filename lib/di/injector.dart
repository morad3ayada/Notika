import 'package:get_it/get_it.dart';
import '../data/services/auth_service.dart' as auth_service;
import '../data/services/profile_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/conferences_repository.dart';
import '../data/repositories/conversations_repository.dart';
import '../data/repositories/all_students_repository.dart'; // إضافة استيراد AllStudentsRepository
import '../data/repositories/assignment_repository.dart';
import '../data/repositories/file_classification_repository.dart';
import '../data/repositories/quick_tests_repository.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/teacher_class_settings_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/class_students_repository.dart';
import '../data/repositories/daily_grade_titles_repository.dart';
import '../data/repositories/daily_grades_repository.dart';
import '../data/repositories/exam_export_repository.dart';
import '../data/repositories/exam_schedule_repository.dart';
import '../data/repositories/exam_questions_repository.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import '../logic/blocs/auth/auth_bloc.dart';
import '../logic/blocs/profile/profile_bloc.dart';
import '../data/repositories/notifications_repository.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // API Client - تم إزالته من هنا لأن baseUrl يتغير ديناميكياً
  // سيتم إنشاء ApiClient في كل service/repository حسب الحاجة

  // Services
  sl.registerLazySingleton<auth_service.AuthService>(() => auth_service.AuthService());
  sl.registerLazySingleton<ProfileService>(() => ProfileService());

  // Repositories
  sl.registerFactory<AuthRepository>(() => AuthRepository(auth_service.AuthService()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepository(sl()));
  sl.registerLazySingleton<ConferencesRepository>(() => ConferencesRepository());
  sl.registerLazySingleton<ConversationsRepository>(() => ConversationsRepository());
  sl.registerLazySingleton<AllStudentsRepository>(() => AllStudentsRepository()); // إضافة تسجيل AllStudentsRepository
  sl.registerLazySingleton<AssignmentRepository>(() => AssignmentRepository());
  sl.registerLazySingleton<FileClassificationRepository>(() => FileClassificationRepository());
  sl.registerLazySingleton<QuickTestsRepository>(() => QuickTestsRepository());
  sl.registerLazySingleton<AttendanceRepository>(() => AttendanceRepository());
  sl.registerLazySingleton<NotificationsRepository>(() => NotificationsRepository());
  sl.registerLazySingleton<TeacherClassSettingsRepository>(() => TeacherClassSettingsRepository());
  sl.registerLazySingleton<ChatRepository>(() => ChatRepository());
  sl.registerLazySingleton<ClassStudentsRepository>(() => ClassStudentsRepository());
  sl.registerLazySingleton<DailyGradeTitlesRepository>(() => DailyGradeTitlesRepository());
  sl.registerLazySingleton<DailyGradesRepository>(() => DailyGradesRepository());
  sl.registerLazySingleton<ExamExportRepository>(() => ExamExportRepository());
  sl.registerLazySingleton<ExamScheduleRepository>(() => ExamScheduleRepository());
  sl.registerLazySingleton<ExamQuestionsRepository>(() => ExamQuestionsRepository());

  // Blocs
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(sl()));
  sl.registerLazySingleton<ProfileBloc>(() => ProfileBloc(sl()));
}
