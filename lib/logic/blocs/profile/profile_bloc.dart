import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../../../data/repositories/profile_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;
  ProfileBloc(this.repository) : super(const ProfileInitial()) {
    on<FetchProfile>((event, emit) async {
      emit(const ProfileLoading());
      try {
        final result = await repository.loadProfileResult();
        emit(ProfileLoaded(
          profile: result.profile,
          classes: result.classes,
          organization: result.organization,
        ));
      } catch (e) {
        emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
      }
    });
  }
}
