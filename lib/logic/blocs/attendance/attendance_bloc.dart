import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/models/attendance_model.dart';
import '../../../utils/teacher_class_matcher.dart';
import '../../../data/models/profile_models.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _repository;
  List<StudentAttendance> _currentStudents = [];

  AttendanceBloc(this._repository) : super(const AttendanceInitial()) {
    on<SendAttendanceEvent>(_onSendAttendance);
    on<LoadStudentsEvent>(_onLoadStudents);
    on<LoadAttendanceHistoryEvent>(_onLoadAttendanceHistory);
    on<UpdateStudentAttendanceEvent>(_onUpdateStudentAttendance);
    on<ResetAttendanceEvent>(_onResetAttendance);
    on<ValidateAttendanceEvent>(_onValidateAttendance);
    on<RefreshAttendanceEvent>(_onRefreshAttendance);
  }

  Future<void> _onSendAttendance(
    SendAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      print('AttendanceBloc: Starting to send attendance');
      emit(const AttendanceSubmitting());

      // Validate the attendance data
      final validationResult = _validateAttendanceData(
        event.students,
        event.subjectId,
        event.levelId,
        event.classId,
      );
      if (validationResult != null) {
        print('AttendanceBloc: Validation failed: $validationResult');
        emit(AttendanceSubmissionFailed(validationResult));
        return;
      }

      // Create attendance submission
      final submission = AttendanceSubmission(
        subjectId: event.subjectId,
        levelId: event.levelId,
        classId: event.classId,
        classOrder: event.classOrder,
        date: event.date,
        students: event.students,
      );

      print('AttendanceBloc: Validation passed, calling repository');
      final response = await _repository.submitAttendance(submission);
      
      print('AttendanceBloc: Attendance submitted successfully: ${response.id}');
      emit(AttendanceSubmitted(
        response: response,
        message: response.message,
      ));
    } catch (e) {
      print('AttendanceBloc: Error submitting attendance: $e');
      String errorMessage = 'فشل في تسجيل الحضور';
      
      if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.contains('Exception: ')) {
          errorMessage = exceptionMessage.replaceFirst('Exception: ', '');
        } else {
          errorMessage = exceptionMessage;
        }
      } else {
        errorMessage = 'حدث خطأ غير متوقع: $e';
      }
      
      emit(AttendanceSubmissionFailed(errorMessage));
    }
  }

  Future<void> _onLoadStudents(
    LoadStudentsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      print('AttendanceBloc: Loading students for class');
      emit(const AttendanceLoading());

      final students = await _repository.getStudentsList(
        subjectId: event.subjectId,
        levelId: event.levelId,
        classId: event.classId,
      );
      
      _currentStudents = students;
      print('AttendanceBloc: Loaded ${students.length} students');
      emit(StudentsLoaded(students));
    } catch (e) {
      print('AttendanceBloc: Error loading students: $e');
      String errorMessage = 'فشل في تحميل قائمة الطلاب';
      
      if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.contains('Exception: ')) {
          errorMessage = exceptionMessage.replaceFirst('Exception: ', '');
        } else {
          errorMessage = exceptionMessage;
        }
      }
      
      emit(StudentsLoadingFailed(errorMessage));
    }
  }

  Future<void> _onLoadAttendanceHistory(
    LoadAttendanceHistoryEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      print('AttendanceBloc: Loading attendance history');
      emit(const AttendanceLoading());

      final history = await _repository.getAttendanceHistory(
        subjectId: event.subjectId,
        levelId: event.levelId,
        classId: event.classId,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      
      print('AttendanceBloc: Loaded ${history.length} attendance records');
      emit(AttendanceHistoryLoaded(history));
    } catch (e) {
      print('AttendanceBloc: Error loading attendance history: $e');
      String errorMessage = 'فشل في تحميل سجل الحضور';
      
      if (e is Exception) {
        final exceptionMessage = e.toString();
        if (exceptionMessage.contains('Exception: ')) {
          errorMessage = exceptionMessage.replaceFirst('Exception: ', '');
        } else {
          errorMessage = exceptionMessage;
        }
      }
      
      emit(AttendanceHistoryLoadingFailed(errorMessage));
    }
  }

  void _onUpdateStudentAttendance(
    UpdateStudentAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) {
    print('AttendanceBloc: Updating student ${event.studentId} status to ${event.status}');
    
    // Update the student's status in the current list
    final updatedStudents = _currentStudents.map((student) {
      if (student.studentId == event.studentId) {
        return student.copyWith(status: event.status);
      }
      return student;
    }).toList();
    
    _currentStudents = updatedStudents;
    
    emit(StudentAttendanceUpdated(
      students: updatedStudents,
      updatedStudentId: event.studentId,
      newStatus: event.status,
    ));
  }

  void _onResetAttendance(
    ResetAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) {
    print('AttendanceBloc: Resetting state');
    _currentStudents = [];
    emit(const AttendanceInitial());
  }

  void _onValidateAttendance(
    ValidateAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) {
    print('AttendanceBloc: Validating attendance data');
    emit(const AttendanceValidating());

    final validationResult = _validateAttendanceData(
      event.students,
      event.subjectId,
      event.levelId,
      event.classId,
    );
    
    if (validationResult != null) {
      print('AttendanceBloc: Validation failed: $validationResult');
      emit(AttendanceValidationFailure(validationResult));
    } else {
      print('AttendanceBloc: Validation passed');
      emit(const AttendanceValidationSuccess());
    }
  }

  void _onRefreshAttendance(
    RefreshAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) {
    print('AttendanceBloc: Refreshing attendance data');
    // Emit the current students if available
    if (_currentStudents.isNotEmpty) {
      emit(StudentsLoaded(_currentStudents));
    } else {
      emit(const AttendanceInitial());
    }
  }

  String? _validateAttendanceData(
    List<StudentAttendance> students,
    String subjectId,
    String levelId,
    String classId,
  ) {
    // Validate required fields
    if (subjectId.trim().isEmpty) {
      return 'يرجى اختيار المادة';
    }

    if (levelId.trim().isEmpty) {
      return 'يرجى اختيار المرحلة';
    }

    if (classId.trim().isEmpty) {
      return 'يرجى اختيار الشعبة';
    }

    if (students.isEmpty) {
      return 'لا توجد طلاب لتسجيل الحضور';
    }

    // Validate each student's data
    for (final student in students) {
      if (student.studentId.trim().isEmpty) {
        return 'معرف الطالب مفقود لأحد الطلاب';
      }

      if (student.name.trim().isEmpty) {
        return 'اسم الطالب مفقود لأحد الطلاب';
      }

      if (!['present', 'absent', 'excused'].contains(student.status)) {
        return 'حالة حضور غير صحيحة للطالب ${student.name}';
      }
    }

    // Check for duplicate student IDs
    final studentIds = students.map((s) => s.studentId).toList();
    final uniqueIds = studentIds.toSet();
    if (studentIds.length != uniqueIds.length) {
      return 'يوجد طلاب مكررون في القائمة';
    }

    return null; // No validation errors
  }

  /// Helper method to create attendance submission from form data
  static AttendanceSubmission createSubmissionFromFormData({
    required List<TeacherClass> classes,
    required String selectedSchool,
    required String selectedStage,
    required String selectedSection,
    required String selectedSubject,
    required List<StudentAttendance> students,
    required int classOrder,
    required DateTime date,
  }) {
    // Find matching TeacherClass
    final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
      classes,
      selectedSchool,
      selectedStage,
      selectedSection,
      selectedSubject,
    );

    if (matchingClass == null) {
      throw Exception('لم يتم العثور على الفصل المطابق للاختيارات المحددة');
    }

    return AttendanceSubmission(
      subjectId: matchingClass.levelSubjectId ?? 
                 matchingClass.subjectId ?? 
                 '00000000-0000-0000-0000-000000000000',
      levelId: matchingClass.levelId ?? '00000000-0000-0000-0000-000000000000',
      classId: matchingClass.classId ?? '00000000-0000-0000-0000-000000000000',
      classOrder: classOrder,
      date: date,
      students: students,
    );
  }

  /// Get current students list
  List<StudentAttendance> get currentStudents => List.unmodifiable(_currentStudents);

  /// Update current students list
  void updateCurrentStudents(List<StudentAttendance> students) {
    _currentStudents = students;
  }
}
