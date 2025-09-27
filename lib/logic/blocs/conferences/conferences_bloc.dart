import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/conferences_repository.dart';
import '../../../data/models/conference_model.dart';
import 'conferences_event.dart';
import 'conferences_state.dart';

class ConferencesBloc extends Bloc<ConferencesEvent, ConferencesState> {
  final ConferencesRepository _repository;

  ConferencesBloc(this._repository) : super(const ConferencesInitial()) {
    on<LoadConferences>(_onLoadConferences);
    on<RefreshConferences>(_onRefreshConferences);
    on<CreateConference>(_onCreateConference);
    on<UpdateConference>(_onUpdateConference);
    on<DeleteConference>(_onDeleteConference);
  }

  /// Handles loading conferences from the API
  Future<void> _onLoadConferences(
    LoadConferences event,
    Emitter<ConferencesState> emit,
  ) async {
    try {
      debugPrint('🔄 ConferencesBloc: Loading conferences (forceRefresh: ${event.forceRefresh})');
      
      // Only show loading if we're not already in a loaded state or if force refresh
      if (state is! ConferencesLoaded || event.forceRefresh) {
        emit(const ConferencesLoading());
      }

      final conferences = await _repository.getConferences();
      
      debugPrint('📊 ConferencesBloc: Received ${conferences.length} conferences from repository');

      // Separate conferences into upcoming and past based on startAt time
      final now = DateTime.now();
      final List<ConferenceModel> upcomingConferences = [];
      final List<ConferenceModel> pastConferences = [];

      for (final conference in conferences) {
        if (conference.startAt.isAfter(now)) {
          upcomingConferences.add(conference);
          debugPrint('📅 Upcoming: ${conference.title} - ${conference.startAt}');
        } else {
          pastConferences.add(conference);
          debugPrint('📅 Past: ${conference.title} - ${conference.startAt}');
        }
      }

      // Sort upcoming conferences by startAt (earliest first)
      upcomingConferences.sort((a, b) => a.startAt.compareTo(b.startAt));
      
      // Sort past conferences by startAt (most recent first)
      pastConferences.sort((a, b) => b.startAt.compareTo(a.startAt));

      debugPrint('✅ ConferencesBloc: Separated into ${upcomingConferences.length} upcoming and ${pastConferences.length} past conferences');

      emit(ConferencesLoaded(
        upcomingConferences: upcomingConferences,
        pastConferences: pastConferences,
        lastUpdated: DateTime.now(),
      ));

    } catch (e, stackTrace) {
      debugPrint('❌ ConferencesBloc: Error loading conferences: $e');
      debugPrint('Stack trace: $stackTrace');
      
      emit(ConferencesError(
        message: e.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Handles refreshing conferences (same as load with force refresh)
  Future<void> _onRefreshConferences(
    RefreshConferences event,
    Emitter<ConferencesState> emit,
  ) async {
    debugPrint('🔄 ConferencesBloc: Refreshing conferences');
    add(const LoadConferences(forceRefresh: true));
  }

  /// Handles creating a new conference
  Future<void> _onCreateConference(
    CreateConference event,
    Emitter<ConferencesState> emit,
  ) async {
    try {
      debugPrint('🔄 ConferencesBloc: Creating conference with data: ${event.conferenceData}');
      
      emit(const ConferenceCreating());

      final createdConference = await _repository.createConference(event.conferenceData);
      
      debugPrint('✅ ConferencesBloc: Conference created successfully: ${createdConference.title}');
      
      emit(ConferenceCreated(createdConference));

      // Reload conferences to get the updated list
      add(const LoadConferences(forceRefresh: true));

    } catch (e, stackTrace) {
      debugPrint('❌ ConferencesBloc: Error creating conference: $e');
      debugPrint('Stack trace: $stackTrace');
      
      emit(ConferenceCreateError(e.toString()));
    }
  }

  /// Handles updating an existing conference
  Future<void> _onUpdateConference(
    UpdateConference event,
    Emitter<ConferencesState> emit,
  ) async {
    try {
      debugPrint('🔄 ConferencesBloc: Updating conference ${event.conferenceId}');
      
      emit(ConferenceUpdating(event.conferenceId));

      final updatedConference = await _repository.updateConference(
        event.conferenceId,
        event.conferenceData,
      );
      
      debugPrint('✅ ConferencesBloc: Conference updated successfully: ${updatedConference.title}');
      
      emit(ConferenceUpdated(updatedConference));

      // Reload conferences to get the updated list
      add(const LoadConferences(forceRefresh: true));

    } catch (e, stackTrace) {
      debugPrint('❌ ConferencesBloc: Error updating conference: $e');
      debugPrint('Stack trace: $stackTrace');
      
      emit(ConferenceUpdateError(e.toString()));
    }
  }

  /// Handles deleting a conference
  Future<void> _onDeleteConference(
    DeleteConference event,
    Emitter<ConferencesState> emit,
  ) async {
    try {
      debugPrint('🔄 ConferencesBloc: Deleting conference ${event.conferenceId}');
      
      emit(ConferenceDeleting(event.conferenceId));

      await _repository.deleteConference(event.conferenceId);
      
      debugPrint('✅ ConferencesBloc: Conference deleted successfully');
      
      emit(ConferenceDeleted(event.conferenceId));

      // Reload conferences to get the updated list
      add(const LoadConferences(forceRefresh: true));

    } catch (e, stackTrace) {
      debugPrint('❌ ConferencesBloc: Error deleting conference: $e');
      debugPrint('Stack trace: $stackTrace');
      
      emit(ConferenceDeleteError(e.toString()));
    }
  }

  /// Helper method to get current conferences if loaded
  List<ConferenceModel>? get currentUpcomingConferences {
    final currentState = state;
    if (currentState is ConferencesLoaded) {
      return currentState.upcomingConferences;
    }
    return null;
  }

  /// Helper method to get current past conferences if loaded
  List<ConferenceModel>? get currentPastConferences {
    final currentState = state;
    if (currentState is ConferencesLoaded) {
      return currentState.pastConferences;
    }
    return null;
  }

  /// Helper method to check if conferences are currently loaded
  bool get isLoaded => state is ConferencesLoaded;

  /// Helper method to check if there's an error
  bool get hasError => state is ConferencesError;

  /// Helper method to check if loading
  bool get isLoading => state is ConferencesLoading;

  @override
  void onTransition(Transition<ConferencesEvent, ConferencesState> transition) {
    super.onTransition(transition);
    debugPrint('🔄 ConferencesBloc Transition: ${transition.currentState} -> ${transition.nextState}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    debugPrint('❌ ConferencesBloc Error: $error');
    debugPrint('Stack trace: $stackTrace');
  }
}
