import 'package:equatable/equatable.dart';
import '../../../data/models/quick_tests_model.dart';

abstract class QuickTestsEvent extends Equatable {
  const QuickTestsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to add a new quick test
class AddQuickTestEvent extends QuickTestsEvent {
  final CreateQuickTestRequest request;

  const AddQuickTestEvent(this.request);

  @override
  List<Object?> get props => [request];
}

/// Event to load all quick tests
class LoadQuickTestsEvent extends QuickTestsEvent {
  const LoadQuickTestsEvent();
}

/// Event to refresh quick tests
class RefreshQuickTestsEvent extends QuickTestsEvent {
  const RefreshQuickTestsEvent();
}

/// Event to reset quick tests state
class ResetQuickTestsEvent extends QuickTestsEvent {
  const ResetQuickTestsEvent();
}

/// Event to validate quick test data before submission
class ValidateQuickTestEvent extends QuickTestsEvent {
  final CreateQuickTestRequest request;

  const ValidateQuickTestEvent(this.request);

  @override
  List<Object?> get props => [request];
}
