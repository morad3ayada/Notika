import 'package:equatable/equatable.dart';
import '../../data/models/profile_models.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final TeacherProfile profile;
  final List<TeacherClass> classes;
  final Organization? organization;

  const ProfileLoaded({
    required this.profile,
    required this.classes,
    this.organization,
  });

  @override
  List<Object?> get props => [profile, classes, organization];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
