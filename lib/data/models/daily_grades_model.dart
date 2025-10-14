import 'package:equatable/equatable.dart';

/// نموذج درجة يومية واحدة - يطابق schema الجديد
class DailyGrade extends Equatable {
  final String? id;
  final String? gradeTitleId;  // من API
  final String dailyGradeTitleId;  // للتوافق مع الكود القديم
  final String? title;  // اسم الدرجة
  final double grade;
  final double? maxGrade;  // الدرجة الكاملة
  final String? note;
  final DateTime? date;

  const DailyGrade({
    this.id,
    this.gradeTitleId,
    required this.dailyGradeTitleId,
    this.title,
    required this.grade,
    this.maxGrade,
    this.note,
    this.date,
  });

  factory DailyGrade.fromJson(Map<String, dynamic> json) {
    // استخدم gradeTitleId أو dailyGradeTitleId
    final titleId = json['gradeTitleId']?.toString() ?? 
                   json['GradeTitleId']?.toString() ??
                   json['dailyGradeTitleId']?.toString() ?? 
                   json['DailyGradeTitleId']?.toString() ?? 
                   '';
    
    return DailyGrade(
      id: json['id']?.toString() ?? json['Id']?.toString(),
      gradeTitleId: json['gradeTitleId']?.toString(),
      dailyGradeTitleId: titleId,
      title: json['title']?.toString() ?? json['Title']?.toString(),
      grade: (json['grade'] as num?)?.toDouble() ?? 
             (json['Grade'] as num?)?.toDouble() ?? 
             0.0,
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ??
               (json['MaxGrade'] as num?)?.toDouble(),
      note: json['note']?.toString() ?? json['Note']?.toString(),
      date: json['date'] != null 
          ? DateTime.tryParse(json['date'].toString())
          : json['Date'] != null
              ? DateTime.tryParse(json['Date'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (gradeTitleId != null) 'gradeTitleId': gradeTitleId,
        'dailyGradeTitleId': dailyGradeTitleId,
        if (title != null) 'title': title,
        'grade': grade,
        if (maxGrade != null) 'maxGrade': maxGrade,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (date != null) 'date': date!.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, gradeTitleId, dailyGradeTitleId, title, grade, maxGrade, note, date];
}

/// نموذج درجة كويز واحد - يطابق schema الجديد
class QuizGrade extends Equatable {
  final String? id;
  final String? quizId;
  final String? studentId;
  final String title;
  final double grade;
  final double maxGrade;
  final String? note;
  final DateTime? attemptedAt;

  const QuizGrade({
    this.id,
    this.quizId,
    this.studentId,
    required this.title,
    required this.grade,
    this.maxGrade = 0,
    this.note,
    this.attemptedAt,
  });

  factory QuizGrade.fromJson(Map<String, dynamic> json) {
    return QuizGrade(
      id: json['id']?.toString() ?? json['Id']?.toString(),
      quizId: json['quizId']?.toString() ?? json['QuizId']?.toString(),
      studentId: json['studentId']?.toString() ?? json['StudentId']?.toString(),
      title: json['quizTitle']?.toString() ?? 
          json['QuizTitle']?.toString() ??
          json['title']?.toString() ?? 
          json['name']?.toString() ?? 
          'كويز',
      grade: (json['grade'] as num?)?.toDouble() ?? 
             (json['Grade'] as num?)?.toDouble() ?? 
             0.0,
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ?? 
          (json['MaxGrade'] as num?)?.toDouble() ??
          (json['totalGrade'] as num?)?.toDouble() ??
          0.0,
      note: json['note']?.toString() ?? json['Note']?.toString(),
      attemptedAt: json['attemptedAt'] != null
          ? DateTime.tryParse(json['attemptedAt'].toString())
          : json['AttemptedAt'] != null
              ? DateTime.tryParse(json['AttemptedAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (quizId != null) 'quizId': quizId,
        if (studentId != null) 'studentId': studentId,
        'quizTitle': title,
        'grade': grade,
        'maxGrade': maxGrade,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (attemptedAt != null) 'attemptedAt': attemptedAt!.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, quizId, studentId, title, grade, maxGrade, note, attemptedAt];
}

/// نموذج درجة اسيمنت واحد - يطابق schema الجديد
class AssignmentGrade extends Equatable {
  final String? id;
  final String? assignmentId;
  final String? studentId;
  final String title;
  final double grade;
  final double maxGrade;
  final String? note;
  final DateTime? submittedAt;
  final String? contentType;
  final String? content;

  const AssignmentGrade({
    this.id,
    this.assignmentId,
    this.studentId,
    required this.title,
    required this.grade,
    this.maxGrade = 0,
    this.note,
    this.submittedAt,
    this.contentType,
    this.content,
  });

  factory AssignmentGrade.fromJson(Map<String, dynamic> json) {
    return AssignmentGrade(
      id: json['id']?.toString() ?? json['Id']?.toString(),
      assignmentId: json['assignmentId']?.toString() ?? json['AssignmentId']?.toString(),
      studentId: json['studentId']?.toString() ?? json['StudentId']?.toString(),
      title: json['assignmentTitle']?.toString() ?? 
          json['AssignmentTitle']?.toString() ??
          json['title']?.toString() ?? 
          json['name']?.toString() ?? 
          'واجب',
      grade: (json['grade'] as num?)?.toDouble() ?? 
             (json['Grade'] as num?)?.toDouble() ?? 
             0.0,
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ?? 
          (json['MaxGrade'] as num?)?.toDouble() ??
          (json['totalGrade'] as num?)?.toDouble() ??
          0.0,
      note: json['note']?.toString() ?? json['Note']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'].toString())
          : json['SubmittedAt'] != null
              ? DateTime.tryParse(json['SubmittedAt'].toString())
              : null,
      contentType: json['contentType']?.toString() ?? json['ContentType']?.toString(),
      content: json['content']?.toString() ?? json['Content']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (assignmentId != null) 'assignmentId': assignmentId,
        if (studentId != null) 'studentId': studentId,
        'assignmentTitle': title,
        'grade': grade,
        'maxGrade': maxGrade,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
        if (contentType != null) 'contentType': contentType,
        if (content != null) 'content': content,
      };

  @override
  List<Object?> get props => [id, assignmentId, studentId, title, grade, maxGrade, note, submittedAt, contentType, content];
}

/// نموذج درجات طالب واحد - يطابق API الجديد
class StudentDailyGrades extends Equatable {
  final String? userId;
  final String studentId;
  final String? studentClassId;
  final String? studentClassSubjectId;
  final String? picture;
  final String? firstName;
  final String? secondName;
  final String? thirdName;
  final String? fourthName;
  final String? nickName;
  final String? religion;
  final String? gender;
  final int absenceTimes;
  final String? subjectId;
  final String? subjectName;
  final DateTime date;
  final List<DailyGrade> dailyGrades;
  final List<QuizGrade> quizzes;
  final List<AssignmentGrade> assignments;

  const StudentDailyGrades({
    this.userId,
    required this.studentId,
    this.studentClassId,
    this.studentClassSubjectId,
    this.picture,
    this.firstName,
    this.secondName,
    this.thirdName,
    this.fourthName,
    this.nickName,
    this.religion,
    this.gender,
    this.absenceTimes = 0,
    this.subjectId,
    this.subjectName,
    required this.date,
    this.dailyGrades = const [],
    this.quizzes = const [],
    this.assignments = const [],
  });

  factory StudentDailyGrades.fromJson(Map<String, dynamic> json) {
    print('═══════════════════════════════════════════════════════');
    print('🔍 Parsing StudentDailyGrades from JSON (NEW SCHEMA):');
    print('   - Raw JSON keys: ${json.keys.join(", ")}');
    print('   - studentId: ${json['studentId']}');
    print('   - studentClassSubjectId: ${json['studentClassSubjectId']}');
    print('   - firstName: ${json['firstName']}');
    print('   - absenceTimes: ${json['absenceTimes']}');
    
    return StudentDailyGrades(
      userId: json['userId']?.toString(),
      studentId: json['studentId']?.toString() ?? 
                 json['StudentId']?.toString() ?? 
                 '',
      studentClassId: json['studentClassId']?.toString() ??
                     json['StudentClassId']?.toString(),
      studentClassSubjectId: json['studentClassSubjectId']?.toString() ?? 
                            json['StudentClassSubjectId']?.toString(),
      picture: json['picture']?.toString(),
      firstName: json['firstName']?.toString() ??
                json['FirstName']?.toString(),
      secondName: json['secondName']?.toString() ??
                 json['SecondName']?.toString(),
      thirdName: json['thirdName']?.toString() ??
                json['ThirdName']?.toString(),
      fourthName: json['fourthName']?.toString() ??
                 json['FourthName']?.toString(),
      nickName: json['nickName']?.toString() ??
               json['NickName']?.toString(),
      religion: json['religin']?.toString() ?? // typo في API!
               json['religion']?.toString() ??
               json['Religion']?.toString(),
      gender: json['gender']?.toString() ??
             json['Gender']?.toString(),
      absenceTimes: json['absenceTimes'] as int? ?? 
                   json['AbsenceTimes'] as int? ?? 
                   0,
      subjectId: json['subjectId']?.toString() ??
                json['SubjectId']?.toString(),
      subjectName: json['subjectName']?.toString() ??
                  json['SubjectName']?.toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      // ⚠️ الحقل في API هو 'grades' وليس 'dailyGrades'!
      dailyGrades: (json['grades'] as List<dynamic>?)
              ?.map((e) => DailyGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['dailyGrades'] as List<dynamic>?)
              ?.map((e) => DailyGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quizzes: (json['quizAttempts'] as List<dynamic>?)
              ?.map((e) => QuizGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['quizzes'] as List<dynamic>?)
              ?.map((e) => QuizGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assignments: (json['assignmentSubmissions'] as List<dynamic>?)
              ?.map((e) => AssignmentGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['assignments'] as List<dynamic>?)
              ?.map((e) => AssignmentGrade.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// الاسم الكامل
  String get fullName {
    final names = [
      firstName,
      secondName,
      thirdName,
      fourthName,
    ].where((n) => n != null && n.isNotEmpty).join(' ');
    return names.isNotEmpty ? names : nickName ?? 'غير محدد';
  }

  Map<String, dynamic> toJson() => {
        if (userId != null) 'userId': userId,
        'studentId': studentId,
        if (studentClassId != null) 'studentClassId': studentClassId,
        if (studentClassSubjectId != null) 'studentClassSubjectId': studentClassSubjectId,
        if (picture != null) 'picture': picture,
        if (firstName != null) 'firstName': firstName,
        if (secondName != null) 'secondName': secondName,
        if (thirdName != null) 'thirdName': thirdName,
        if (fourthName != null) 'fourthName': fourthName,
        if (nickName != null) 'nickName': nickName,
        if (religion != null) 'religin': religion, // typo في API
        if (gender != null) 'gender': gender,
        'absenceTimes': absenceTimes,
        if (subjectId != null) 'subjectId': subjectId,
        if (subjectName != null) 'subjectName': subjectName,
        'date': date.toIso8601String(),
        'DailyGrades': dailyGrades.map((e) => e.toJson()).toList(),  // ✅ تغيير إلى DailyGrades كما يتوقع Swagger
        'quizAttempts': quizzes.map((e) => e.toJson()).toList(),
        'assignmentSubmissions': assignments.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
    userId,
    studentId,
    studentClassId,
    studentClassSubjectId,
    picture,
    firstName,
    secondName,
    thirdName,
    fourthName,
    nickName,
    religion,
    gender,
    absenceTimes,
    subjectId,
    subjectName,
    date,
    dailyGrades,
    quizzes,
    assignments,
  ];
}

/// نموذج الطلب لتحديث الدرجات بشكل جماعي
class BulkDailyGradesRequest extends Equatable {
  final String levelId;
  final String classId;
  final String subjectId;
  final DateTime date;
  final List<StudentDailyGrades> studentsDailyGrades;

  const BulkDailyGradesRequest({
    required this.levelId,
    required this.classId,
    required this.subjectId,
    required this.date,
    required this.studentsDailyGrades,
  });

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'classId': classId,
        'subjectId': subjectId,
        'date': date.toIso8601String(),
        'studentsDailyGrades':
            studentsDailyGrades.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props =>
      [levelId, classId, subjectId, date, studentsDailyGrades];
}

/// نموذج الاستجابة
class DailyGradesResponse extends Equatable {
  final bool success;
  final String message;
  final dynamic data;

  const DailyGradesResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DailyGradesResponse.success({String? message, dynamic data}) {
    return DailyGradesResponse(
      success: true,
      message: message ?? 'تم حفظ الدرجات بنجاح',
      data: data,
    );
  }

  factory DailyGradesResponse.error(String message) {
    return DailyGradesResponse(
      success: false,
      message: message,
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
