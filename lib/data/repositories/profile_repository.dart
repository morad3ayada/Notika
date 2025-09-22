import '../models/profile_models.dart';
import '../services/profile_service.dart';

class ProfileRepository {
  final ProfileService _service;
  ProfileRepository(this._service);

  Future<TeacherProfile> loadProfile() => _service.getTeacherProfile();
  Future<Organization> loadOrganization() => _service.getOrganization();
  Future<ProfileResult> loadProfileResult() => _service.getProfileResult();
}
