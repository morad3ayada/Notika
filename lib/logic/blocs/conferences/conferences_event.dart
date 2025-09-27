import 'package:equatable/equatable.dart';

abstract class ConferencesEvent extends Equatable {
  const ConferencesEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load conferences from the API
class LoadConferences extends ConferencesEvent {
  /// Whether to force refresh the data (bypass cache if any)
  final bool forceRefresh;

  const LoadConferences({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];

  @override
  String toString() => 'LoadConferences(forceRefresh: $forceRefresh)';
}

/// Event to refresh conferences (same as LoadConferences with forceRefresh = true)
class RefreshConferences extends ConferencesEvent {
  const RefreshConferences();

  @override
  String toString() => 'RefreshConferences()';
}

/// Event to create a new conference
class CreateConference extends ConferencesEvent {
  final Map<String, dynamic> conferenceData;

  const CreateConference(this.conferenceData);

  @override
  List<Object?> get props => [conferenceData];

  @override
  String toString() => 'CreateConference(data: $conferenceData)';
}

/// Event to update an existing conference
class UpdateConference extends ConferencesEvent {
  final String conferenceId;
  final Map<String, dynamic> conferenceData;

  const UpdateConference(this.conferenceId, this.conferenceData);

  @override
  List<Object?> get props => [conferenceId, conferenceData];

  @override
  String toString() => 'UpdateConference(id: $conferenceId, data: $conferenceData)';
}

/// Event to delete a conference
class DeleteConference extends ConferencesEvent {
  final String conferenceId;

  const DeleteConference(this.conferenceId);

  @override
  List<Object?> get props => [conferenceId];

  @override
  String toString() => 'DeleteConference(id: $conferenceId)';
}
