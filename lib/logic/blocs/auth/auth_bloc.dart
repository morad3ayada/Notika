import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/auth_service.dart' as auth_service;
import '../../../data/models/auth_models.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;
  AuthBloc(this.repository) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckSavedAuth>(_onCheckSavedAuth);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await repository.login(event.username, event.password);
      emit(AuthSuccess(response));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await repository.logout();
    emit(AuthInitial());
  }

  Future<void> _onCheckSavedAuth(CheckSavedAuth event, Emitter<AuthState> emit) async {
    try {
      debugPrint('🔍 Checking saved auth...');
      
      // Check if user is already logged in with saved credentials
      final isLoggedIn = await auth_service.AuthService.isLoggedIn();
      debugPrint('📱 isLoggedIn: $isLoggedIn');
      
      if (isLoggedIn) {
        final savedAuthData = await auth_service.AuthService.getSavedAuthData();
        debugPrint('📦 Saved auth data exists: ${savedAuthData != null}');
        
        if (savedAuthData != null) {
          debugPrint('📋 Saved data keys: ${savedAuthData.keys.toList()}');
          
          // Validate required fields before parsing
          if (!savedAuthData.containsKey('token')) {
            debugPrint('❌ Missing token field in saved data');
            await auth_service.AuthService.clearAuthData();
            emit(AuthInitial());
            return;
          }
          
          if (!savedAuthData.containsKey('userType')) {
            debugPrint('⚠️ Missing userType field in saved data - data structure may be outdated');
            await auth_service.AuthService.clearAuthData();
            emit(AuthInitial());
            return;
          }
          
          // Create a LoginResponse from saved data
          final response = LoginResponse.fromJson(savedAuthData);
          debugPrint('✅ Auth restored successfully for user: ${response.profile.userName}');
          emit(AuthSuccess(response));
        } else {
          debugPrint('⚠️ No saved auth data found');
          emit(AuthInitial());
        }
      } else {
        debugPrint('⚠️ User not logged in');
        emit(AuthInitial());
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking saved auth: $e');
      debugPrint('Stack trace: $stackTrace');
      // Clear corrupted data to prevent future errors
      await auth_service.AuthService.clearAuthData();
      emit(AuthInitial());
    }
  }
}
