import 'package:equatable/equatable.dart';

/// Model for student attendance status
class StudentAttendance extends Equatable {
  final String studentId;
  final String name;
  final String status; // "present", "absent", "excused"

  const StudentAttendance({
    required this.studentId,
    required this.name,
    required this.status,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> json) {
    return StudentAttendance(
      studentId: json['studentId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? 'present',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'name': name,
      'status': status,
    };
  }

  StudentAttendance copyWith({
    String? studentId,
    String? name,
    String? status,
  }) {
    return StudentAttendance(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [studentId, name, status];
}

/// Model for attendance submission
class AttendanceSubmission extends Equatable {
  final String subjectId;
  final String levelId;
  final String classId;
  final int classOrder;
  final DateTime date;
  final List<StudentAttendance> students;

  const AttendanceSubmission({
    required this.subjectId,
    required this.levelId,
    required this.classId,
    required this.classOrder,
    required this.date,
    required this.students,
  });

  factory AttendanceSubmission.fromJson(Map<String, dynamic> json) {
    return AttendanceSubmission(
      subjectId: json['subjectId']?.toString() ?? '',
      levelId: json['levelId']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      classOrder: json['classOrder'] is int 
          ? json['classOrder'] 
          : int.tryParse(json['classOrder']?.toString() ?? '1') ?? 1,
      date: json['date'] != null 
          ? DateTime.parse(json['date'].toString())
          : DateTime.now(),
      students: (json['students'] as List<dynamic>?)
          ?.map((student) => StudentAttendance.fromJson(student as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'levelId': levelId,
      'classId': classId,
      'classOrder': classOrder,
      'date': date.toIso8601String(),
      'students': students.map((student) => {
        'studentId': student.studentId,
        'status': student.status,
      }).toList(),
    };
  }

  AttendanceSubmission copyWith({
    String? subjectId,
    String? levelId,
    String? classId,
    int? classOrder,
    DateTime? date,
    List<StudentAttendance>? students,
  }) {
    return AttendanceSubmission(
      subjectId: subjectId ?? this.subjectId,
      levelId: levelId ?? this.levelId,
      classId: classId ?? this.classId,
      classOrder: classOrder ?? this.classOrder,
      date: date ?? this.date,
      students: students ?? this.students,
    );
  }

  @override
  List<Object?> get props => [subjectId, levelId, classId, classOrder, date, students];
}

/// Response model for attendance submission
class AttendanceResponse extends Equatable {
  final String? id;
  final String message;
  final bool success;
  final DateTime? createdAt;

  const AttendanceResponse({
    this.id,
    required this.message,
    required this.success,
    this.createdAt,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      id: json['id']?.toString(),
      message: json['message']?.toString() ?? 'تم تسجيل الحضور بنجاح',
      success: json['success'] == true || json['isSuccess'] == true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'message': message,
      'success': success,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, message, success, createdAt];
}

/// Enum for attendance status
enum AttendanceStatus {
  present('present', 'حاضر'),
  absent('absent', 'غائب'),
  excused('excused', 'مُجاز');

  const AttendanceStatus(this.value, this.label);

  final String value;
  final String label;

  static AttendanceStatus fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'excused':
        return AttendanceStatus.excused;
      default:
        return AttendanceStatus.present;
    }
  }
}
