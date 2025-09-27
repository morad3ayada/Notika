import 'package:equatable/equatable.dart';
import '../../../data/models/assignment_model.dart';

abstract class AssignmentEvent extends Equatable {
  const AssignmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadAssignments extends AssignmentEvent {
  const LoadAssignments();
}

class CreateAssignment extends AssignmentEvent {
  final CreateAssignmentRequest request;

  const CreateAssignment(this.request);

  @override
  List<Object?> get props => [request];
}

class ResetAssignmentState extends AssignmentEvent {
  const ResetAssignmentState();
}
