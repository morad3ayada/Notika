import 'package:equatable/equatable.dart';
import '../../../data/models/conference_model.dart';

abstract class ConferencesState extends Equatable {
  const ConferencesState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is first created
class ConferencesInitial extends ConferencesState {
  const ConferencesInitial();

  @override
  String toString() => 'ConferencesInitial()';
}

/// State when conferences are being loaded from the API
class ConferencesLoading extends ConferencesState {
  const ConferencesLoading();

  @override
  String toString() => 'ConferencesLoading()';
}

/// State when conferences have been successfully loaded and separated into upcoming and past
class ConferencesLoaded extends ConferencesState {
  final List<ConferenceModel> upcomingConferences;
  final List<ConferenceModel> pastConferences;
  final DateTime lastUpdated;

  const ConferencesLoaded({
    required this.upcomingConferences,
    required this.pastConferences,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [upcomingConferences, pastConferences, lastUpdated];

  @override
  String toString() => 'ConferencesLoaded(upcoming: ${upcomingConferences.length}, past: ${pastConferences.length}, lastUpdated: $lastUpdated)';

  /// Helper method to get total number of conferences
  int get totalConferences => upcomingConferences.length + pastConferences.length;

  /// Helper method to check if there are any conferences
  bool get hasConferences => totalConferences > 0;

  /// Helper method to check if there are upcoming conferences
  bool get hasUpcomingConferences => upcomingConferences.isNotEmpty;

  /// Helper method to check if there are past conferences
  bool get hasPastConferences => pastConferences.isNotEmpty;
}

/// State when there's an error loading conferences
class ConferencesError extends ConferencesState {
  final String message;
  final String? errorCode;
  final DateTime timestamp;

  const ConferencesError({
    required this.message,
    this.errorCode,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [message, errorCode, timestamp];

  @override
  String toString() => 'ConferencesError(message: $message, errorCode: $errorCode, timestamp: $timestamp)';
}

/// State when a conference is being created
class ConferenceCreating extends ConferencesState {
  const ConferenceCreating();

  @override
  String toString() => 'ConferenceCreating()';
}

/// State when a conference has been successfully created
class ConferenceCreated extends ConferencesState {
  final ConferenceModel conference;

  const ConferenceCreated(this.conference);

  @override
  List<Object?> get props => [conference];

  @override
  String toString() => 'ConferenceCreated(conference: ${conference.title})';
}

/// State when there's an error creating a conference
class ConferenceCreateError extends ConferencesState {
  final String message;

  const ConferenceCreateError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ConferenceCreateError(message: $message)';
}

/// State when a conference is being updated
class ConferenceUpdating extends ConferencesState {
  final String conferenceId;

  const ConferenceUpdating(this.conferenceId);

  @override
  List<Object?> get props => [conferenceId];

  @override
  String toString() => 'ConferenceUpdating(id: $conferenceId)';
}

/// State when a conference has been successfully updated
class ConferenceUpdated extends ConferencesState {
  final ConferenceModel conference;

  const ConferenceUpdated(this.conference);

  @override
  List<Object?> get props => [conference];

  @override
  String toString() => 'ConferenceUpdated(conference: ${conference.title})';
}

/// State when there's an error updating a conference
class ConferenceUpdateError extends ConferencesState {
  final String message;

  const ConferenceUpdateError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ConferenceUpdateError(message: $message)';
}

/// State when a conference is being deleted
class ConferenceDeleting extends ConferencesState {
  final String conferenceId;

  const ConferenceDeleting(this.conferenceId);

  @override
  List<Object?> get props => [conferenceId];

  @override
  String toString() => 'ConferenceDeleting(id: $conferenceId)';
}

/// State when a conference has been successfully deleted
class ConferenceDeleted extends ConferencesState {
  final String conferenceId;

  const ConferenceDeleted(this.conferenceId);

  @override
  List<Object?> get props => [conferenceId];

  @override
  String toString() => 'ConferenceDeleted(id: $conferenceId)';
}

/// State when there's an error deleting a conference
class ConferenceDeleteError extends ConferencesState {
  final String message;

  const ConferenceDeleteError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'ConferenceDeleteError(message: $message)';
}
