import 'package:get_it/get_it.dart';
import '../data/services/auth_service.dart' as auth_service;
import '../data/services/profile_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';

final sl = GetIt.instance;

void setupDependencies() {
  // Services
  sl.registerLazySingleton<auth_service.AuthService>(() => auth_service.AuthService());
  sl.registerLazySingleton<ProfileService>(() => ProfileService());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepository(sl()));
}
