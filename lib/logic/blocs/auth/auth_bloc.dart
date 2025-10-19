import 'dart:async';
import 'dart:convert';
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
      emit(AuthSuccess(response, isFromLogin: true));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await repository.logout();
    emit(AuthInitial());
  }

  Future<void> _onCheckSavedAuth(CheckSavedAuth event, Emitter<AuthState> emit) async {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔍 STARTING CheckSavedAuth...');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    try {
      // لا نعرض AuthLoading حتى لا تظهر شاشة "جاري التحقق"
      debugPrint('✓ Checking silently...');
      
      // Check if user is already logged in with saved credentials
      debugPrint('📱 Step 1: Getting token...');
      final token = await auth_service.AuthService.getToken().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ getToken timeout!');
          return null;
        },
      ).catchError((e) {
        debugPrint('❌ getToken error: $e');
        return null;
      });
      debugPrint('🔑 Token result: ${token != null ? "${token.substring(0, 10)}..." : "null"}');
      
      debugPrint('📱 Step 2: Getting organization URL...');
      final orgUrl = await auth_service.AuthService.getOrganizationUrl().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ getOrganizationUrl timeout!');
          return null;
        },
      ).catchError((e) {
        debugPrint('❌ getOrganizationUrl error: $e');
        return null;
      });
      debugPrint('🌐 OrgUrl result: $orgUrl');
      
      debugPrint('📱 Step 3: Checking login status...');
      final isLoggedIn = await auth_service.AuthService.isLoggedIn().catchError((e) {
        debugPrint('❌ isLoggedIn error: $e');
        return false;
      });
      debugPrint('📱 isLoggedIn result: $isLoggedIn');
      
      if (isLoggedIn) {
        debugPrint('📱 Step 4: Loading saved auth data...');
        final savedAuthData = await auth_service.AuthService.getSavedAuthData().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⏱️ getSavedAuthData timeout!');
            return null;
          },
        ).catchError((e) {
          debugPrint('❌ getSavedAuthData error: $e');
          return null;
        });
        debugPrint('📦 Saved auth data loaded: ${savedAuthData != null}');
        
        if (savedAuthData != null) {
          debugPrint('📋 Data found');
          
          // Validate required fields
          if (!savedAuthData.containsKey('token')) {
            debugPrint('❌ No token');
            emit(AuthInitial());
            return;
          }
          
          if (!savedAuthData.containsKey('userType')) {
            debugPrint('❌ No userType');
            emit(AuthInitial());
            return;
          }
          
          debugPrint('✓ Data valid');
          
          // تحميل organization URL المحفوظ وتحديث ApiConfig
          debugPrint('📱 Step 5: Loading organization URL...');
          await auth_service.AuthService.loadSavedOrganizationUrl();
          debugPrint('✅ Organization URL loaded and set in ApiConfig');
          
          // Create a LoginResponse from saved data
          try {
            debugPrint('Creating response...');
            
            // بناء البيانات بشكل مباشر وبسيط
            final response = LoginResponse(
              token: savedAuthData['token'] as String,
              userType: savedAuthData['userType'] as String,
              profile: UserProfile.fromJson(savedAuthData['profile'] as Map<String, dynamic>),
              organization: savedAuthData['organization'] != null 
                  ? Organization.fromJson(savedAuthData['organization'] as Map<String, dynamic>)
                  : null,
            );
            
            debugPrint('✅ Response created');
            debugPrint('🚀 Emitting AuthSuccess...');
            
            emit(AuthSuccess(response, isFromLogin: false));
            
            debugPrint('✅ DONE!');
          } catch (e) {
            debugPrint('❌ Error: $e');
            emit(AuthInitial());
            return;
          }
        } else {
          debugPrint('⚠️ No saved auth data found');
          emit(AuthInitial());
        }
      } else {
        debugPrint('⚠️ User not logged in - no token found');
        emit(AuthInitial());
      }
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ CRITICAL ERROR in CheckSavedAuth: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // لا نمسح البيانات المحفوظة عند حدوث خطأ - فقط نعرض شاشة تسجيل الدخول
      // المستخدم يمكنه المحاولة مرة أخرى
      debugPrint('⚠️ Emitting AuthInitial due to error...');
      emit(AuthInitial());
      debugPrint('✓ AuthInitial emitted');
    } finally {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🏁 CheckSavedAuth COMPLETED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }
}
