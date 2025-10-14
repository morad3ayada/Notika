/// نموذج للبيانات التجريبية - يطابق JSON المعطى
class StudentGradesMock {
  final int absenceTimes;
  final String subjectName;
  final List<GradeItem> grades;
  final List<QuizAttemptItem> quizAttempts;
  final String firstName;
  final String secondName;
  final String thirdName;

  StudentGradesMock({
    required this.absenceTimes,
    required this.subjectName,
    required this.grades,
    required this.quizAttempts,
    required this.firstName,
    required this.secondName,
    required this.thirdName,
  });

  /// بناء من JSON
  factory StudentGradesMock.fromJson(Map<String, dynamic> json) {
    print('📦 StudentGradesMock.fromJson: $json');
    
    // parse grades
    final gradesJson = json['grades'] as List<dynamic>? ?? [];
    final grades = gradesJson
        .map((g) => GradeItem.fromJson(g as Map<String, dynamic>))
        .toList();
    
    // parse quizAttempts
    final quizAttemptsJson = json['quizAttempts'] as List<dynamic>? ?? [];
    final quizAttempts = quizAttemptsJson
        .map((q) => QuizAttemptItem.fromJson(q as Map<String, dynamic>))
        .toList();
    
    return StudentGradesMock(
      absenceTimes: json['absenceTimes'] as int? ?? 0,
      subjectName: json['subjectName'] as String? ?? '',
      grades: grades,
      quizAttempts: quizAttempts,
      firstName: json['firstName'] as String? ?? '',
      secondName: json['secondName'] as String? ?? '',
      thirdName: json['thirdName'] as String? ?? '',
    );
  }

  /// الاسم الكامل
  String get fullName => '$firstName $secondName $thirdName'.trim();

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'absenceTimes': absenceTimes,
      'subjectName': subjectName,
      'grades': grades.map((g) => g.toJson()).toList(),
      'quizAttempts': quizAttempts.map((q) => q.toJson()).toList(),
      'firstName': firstName,
      'secondName': secondName,
      'thirdName': thirdName,
    };
  }
}

/// عنصر درجة
class GradeItem {
  final String title;
  final double grade;
  final double maxGrade;

  GradeItem({
    required this.title,
    required this.grade,
    required this.maxGrade,
  });

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      title: json['title'] as String? ?? '',
      grade: (json['grade'] as num?)?.toDouble() ?? 0.0,
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'grade': grade,
      'maxGrade': maxGrade,
    };
  }
}

/// محاولة كويز
class QuizAttemptItem {
  final String quizTitle;
  final double maxGrade;
  final double grade;

  QuizAttemptItem({
    required this.quizTitle,
    required this.maxGrade,
    required this.grade,
  });

  factory QuizAttemptItem.fromJson(Map<String, dynamic> json) {
    return QuizAttemptItem(
      quizTitle: json['quizTitle'] as String? ?? '',
      maxGrade: (json['maxGrade'] as num?)?.toDouble() ?? 0.0,
      grade: (json['grade'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizTitle': quizTitle,
      'maxGrade': maxGrade,
      'grade': grade,
    };
  }
}

/// دالة لتحويل List<dynamic> JSON إلى قائمة StudentGradesMock
List<StudentGradesMock> parseStudentGradesMockList(List<dynamic> jsonList) {
  print('🔄 Parsing ${jsonList.length} student grades...');
  
  return jsonList
      .map((json) => StudentGradesMock.fromJson(json as Map<String, dynamic>))
      .toList();
}
