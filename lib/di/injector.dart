import 'package:get_it/get_it.dart';
import '../data/services/auth_service.dart' as auth_service;
import '../data/services/profile_service.dart';
import '../data/services/chapter_unit_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/conferences_repository.dart';
import '../data/repositories/assignment_repository.dart';
import '../data/repositories/file_classification_repository.dart';
import '../data/repositories/quick_tests_repository.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/chapter_unit_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/pdf_upload_repository.dart';
import '../data/repositories/exam_export_repository.dart';
import '../data/repositories/exam_schedule_repository.dart';
import '../data/repositories/exam_questions_repository.dart';
import '../data/repositories/class_students_repository.dart';
import '../data/repositories/daily_grade_titles_repository.dart';
import '../data/repositories/daily_grades_repository.dart';
import '../data/repositories/all_students_repository.dart';
import '../api/api_client.dart';
import '../config/api_config.dart';
import '../providers/user_provider.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // API Client
  sl.registerLazySingleton<ApiClient>(() => ApiClient(baseUrl: ApiConfig.baseUrl));

  // Services
  sl.registerLazySingleton<auth_service.AuthService>(() => auth_service.AuthService());
  sl.registerLazySingleton<ProfileService>(() => ProfileService());
  sl.registerLazySingleton<ChapterUnitService>(() => ChapterUnitService(sl<ApiClient>()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepository(sl()));
  sl.registerLazySingleton<ConferencesRepository>(() => ConferencesRepository(sl()));
  sl.registerLazySingleton<AssignmentRepository>(() => AssignmentRepository());
  sl.registerLazySingleton<FileClassificationRepository>(() => FileClassificationRepository());
  sl.registerLazySingleton<QuickTestsRepository>(() => QuickTestsRepository());
  sl.registerLazySingleton<AttendanceRepository>(() => AttendanceRepository());
  sl.registerLazySingleton<ScheduleRepository>(() => ScheduleRepository());
  sl.registerLazySingleton<ChapterUnitRepository>(() => ChapterUnitRepository(sl<ApiClient>()));
  
  // إضافة PdfUploadRepository للـ dependency injection
  // عشان نقدر نستخدمه في الـ BLoC والشاشات
  sl.registerLazySingleton<PdfUploadRepository>(() => PdfUploadRepository());
  
  // إضافة ExamExportRepository
  sl.registerLazySingleton<ExamExportRepository>(() => ExamExportRepository());
  
  // إضافة ExamScheduleRepository
  sl.registerLazySingleton<ExamScheduleRepository>(() => ExamScheduleRepository());
  
  // إضافة ExamQuestionsRepository
  sl.registerLazySingleton<ExamQuestionsRepository>(() => ExamQuestionsRepository());
  
  // إضافة ClassStudentsRepository
  sl.registerLazySingleton<ClassStudentsRepository>(() => ClassStudentsRepository());
  
  // إضافة DailyGradeTitlesRepository
  sl.registerLazySingleton<DailyGradeTitlesRepository>(() => DailyGradeTitlesRepository());
  
  // إضافة DailyGradesRepository
  sl.registerLazySingleton<DailyGradesRepository>(() => DailyGradesRepository());
  
  // إضافة AllStudentsRepository
  sl.registerLazySingleton<AllStudentsRepository>(() => AllStudentsRepository());
}
