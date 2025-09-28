import 'package:equatable/equatable.dart';
import '../../../data/models/attendance_model.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

/// Loading state for any operation
class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

/// State when students are loaded successfully
class StudentsLoaded extends AttendanceState {
  final List<StudentAttendance> students;

  const StudentsLoaded(this.students);

  @override
  List<Object?> get props => [students];
}

/// State when attendance is being submitted
class AttendanceSubmitting extends AttendanceState {
  const AttendanceSubmitting();
}

/// State when attendance is submitted successfully
class AttendanceSubmitted extends AttendanceState {
  final AttendanceResponse response;
  final String message;

  const AttendanceSubmitted({
    required this.response,
    this.message = 'تم تسجيل الحضور بنجاح',
  });

  @override
  List<Object?> get props => [response, message];
}

/// State when attendance submission fails
class AttendanceSubmissionFailed extends AttendanceState {
  final String message;

  const AttendanceSubmissionFailed(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when attendance history is loaded
class AttendanceHistoryLoaded extends AttendanceState {
  final List<AttendanceSubmission> attendanceHistory;

  const AttendanceHistoryLoaded(this.attendanceHistory);

  @override
  List<Object?> get props => [attendanceHistory];
}

/// State when student attendance is updated locally
class StudentAttendanceUpdated extends AttendanceState {
  final List<StudentAttendance> students;
  final String updatedStudentId;
  final String newStatus;

  const StudentAttendanceUpdated({
    required this.students,
    required this.updatedStudentId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [students, updatedStudentId, newStatus];
}

/// State for validation in progress
class AttendanceValidating extends AttendanceState {
  const AttendanceValidating();
}

/// State for successful validation
class AttendanceValidationSuccess extends AttendanceState {
  final String message;

  const AttendanceValidationSuccess({
    this.message = 'البيانات صحيحة',
  });

  @override
  List<Object?> get props => [message];
}

/// State for validation failure
class AttendanceValidationFailure extends AttendanceState {
  final String message;

  const AttendanceValidationFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// General failure state for any operation
class AttendanceFailure extends AttendanceState {
  final String message;

  const AttendanceFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when loading students fails
class StudentsLoadingFailed extends AttendanceState {
  final String message;

  const StudentsLoadingFailed(this.message);

  @override
  List<Object?> get props => [message];
}

/// State when loading attendance history fails
class AttendanceHistoryLoadingFailed extends AttendanceState {
  final String message;

  const AttendanceHistoryLoadingFailed(this.message);

  @override
  List<Object?> get props => [message];
}
