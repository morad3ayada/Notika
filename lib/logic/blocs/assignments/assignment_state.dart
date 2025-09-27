import 'package:equatable/equatable.dart';
import '../../../data/models/assignment_model.dart';

abstract class AssignmentState extends Equatable {
  const AssignmentState();

  @override
  List<Object?> get props => [];
}

class AssignmentInitial extends AssignmentState {
  const AssignmentInitial();
}

class AssignmentLoading extends AssignmentState {
  const AssignmentLoading();
}

class AssignmentCreating extends AssignmentState {
  const AssignmentCreating();
}

class AssignmentCreated extends AssignmentState {
  const AssignmentCreated();
}

class AssignmentCreateError extends AssignmentState {
  final String message;

  const AssignmentCreateError(this.message);

  @override
  List<Object?> get props => [message];
}

class AssignmentsLoaded extends AssignmentState {
  final List<AssignmentModel> assignments;

  const AssignmentsLoaded(this.assignments);

  @override
  List<Object?> get props => [assignments];
}

class AssignmentError extends AssignmentState {
  final String message;

  const AssignmentError(this.message);

  @override
  List<Object?> get props => [message];
}
