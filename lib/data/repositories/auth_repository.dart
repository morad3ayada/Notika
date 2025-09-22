import '../models/auth_models.dart';
import '../services/auth_service.dart' as service;

class AuthRepository {
  final service.AuthService _service;
  AuthRepository(this._service);

  Future<LoginResponse> login(String username, String password) async {
    return _service.login(username, password);
  }

  Future<void> logout() async {
    await service.AuthService.logout();
  }
}
