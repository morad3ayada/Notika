import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'assignment_event.dart';
import 'assignment_state.dart';
import '../../../data/repositories/assignment_repository.dart';

class AssignmentBloc extends Bloc<AssignmentEvent, AssignmentState> {
  final AssignmentRepository _repository;

  AssignmentBloc(this._repository) : super(const AssignmentInitial()) {
    on<LoadAssignments>(_onLoadAssignments);
    on<CreateAssignment>(_onCreateAssignment);
    on<ResetAssignmentState>(_onResetAssignmentState);
  }

  Future<void> _onLoadAssignments(
    LoadAssignments event,
    Emitter<AssignmentState> emit,
  ) async {
    try {
      developer.log('Loading assignments...');
      emit(const AssignmentLoading());
      
      final assignments = await _repository.getAssignments();
      developer.log('Loaded ${assignments.length} assignments');
      
      emit(AssignmentsLoaded(assignments));
    } catch (e) {
      developer.log('Error loading assignments: $e');
      emit(AssignmentError(e.toString()));
    }
  }

  Future<void> _onCreateAssignment(
    CreateAssignment event,
    Emitter<AssignmentState> emit,
  ) async {
    try {
      developer.log('Creating assignment: ${event.request.title}');
      emit(const AssignmentCreating());
      
      final success = await _repository.createAssignment(event.request);
      
      if (success) {
        developer.log('Assignment created successfully');
        emit(const AssignmentCreated());
        
        // Optionally reload assignments after creation
        add(const LoadAssignments());
      } else {
        developer.log('Assignment creation failed');
        emit(const AssignmentCreateError('فشل في إنشاء الواجب'));
      }
    } catch (e) {
      developer.log('Error creating assignment: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      emit(AssignmentCreateError(errorMessage));
    }
  }

  Future<void> _onResetAssignmentState(
    ResetAssignmentState event,
    Emitter<AssignmentState> emit,
  ) async {
    developer.log('Resetting assignment state');
    emit(const AssignmentInitial());
  }
}
