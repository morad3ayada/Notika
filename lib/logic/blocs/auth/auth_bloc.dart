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
      // Check if user is already logged in with saved credentials
      final isLoggedIn = await auth_service.AuthService.isLoggedIn();
      if (isLoggedIn) {
        final savedAuthData = await auth_service.AuthService.getSavedAuthData();
        if (savedAuthData != null) {
          // Create a LoginResponse from saved data
          final response = LoginResponse.fromJson(savedAuthData);
          emit(AuthSuccess(response));
        } else {
          emit(AuthInitial());
        }
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      debugPrint('Error checking saved auth: $e');
      emit(AuthInitial());
    }
  }
}
