import 'package:equatable/equatable.dart';
import '../../../data/models/attendance_model.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

/// Event to submit attendance for students
class SendAttendanceEvent extends AttendanceEvent {
  final List<StudentAttendance> students;
  final String subjectId;
  final String levelId;
  final String classId;
  final int classOrder;
  final DateTime date;

  const SendAttendanceEvent({
    required this.students,
    required this.subjectId,
    required this.levelId,
    required this.classId,
    required this.classOrder,
    required this.date,
  });

  @override
  List<Object?> get props => [students, subjectId, levelId, classId, classOrder, date];
}

/// Event to load students list for a specific class
class LoadStudentsEvent extends AttendanceEvent {
  final String subjectId;
  final String levelId;
  final String classId;

  const LoadStudentsEvent({
    required this.subjectId,
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [subjectId, levelId, classId];
}

/// Event to load attendance history
class LoadAttendanceHistoryEvent extends AttendanceEvent {
  final String? subjectId;
  final String? levelId;
  final String? classId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadAttendanceHistoryEvent({
    this.subjectId,
    this.levelId,
    this.classId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [subjectId, levelId, classId, startDate, endDate];
}

/// Event to update a student's attendance status
class UpdateStudentAttendanceEvent extends AttendanceEvent {
  final String studentId;
  final String status;

  const UpdateStudentAttendanceEvent({
    required this.studentId,
    required this.status,
  });

  @override
  List<Object?> get props => [studentId, status];
}

/// Event to reset attendance state
class ResetAttendanceEvent extends AttendanceEvent {
  const ResetAttendanceEvent();
}

/// Event to validate attendance data before submission
class ValidateAttendanceEvent extends AttendanceEvent {
  final List<StudentAttendance> students;
  final String subjectId;
  final String levelId;
  final String classId;

  const ValidateAttendanceEvent({
    required this.students,
    required this.subjectId,
    required this.levelId,
    required this.classId,
  });

  @override
  List<Object?> get props => [students, subjectId, levelId, classId];
}

/// Event to refresh attendance data
class RefreshAttendanceEvent extends AttendanceEvent {
  const RefreshAttendanceEvent();
}
