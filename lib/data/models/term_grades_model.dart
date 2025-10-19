import 'package:equatable/equatable.dart';

/// نموذج درجات الطالب الفصلية
class StudentTermGrades extends Equatable {
  final String studentId;
  final String studentName;
  final String? studentImage;
  final double? firstTermAverage;
  final double? midtermExam;
  final double? secondTermAverage;
  final double? annualAverage;

  const StudentTermGrades({
    required this.studentId,
    required this.studentName,
    this.studentImage,
    this.firstTermAverage,
    this.midtermExam,
    this.secondTermAverage,
    this.annualAverage,
  });

  factory StudentTermGrades.fromJson(Map<String, dynamic> json) {
    // بناء الاسم الكامل من الحقول المنفصلة (firstName, secondName, etc.)
    String constructFullName() {
      final firstName = json['firstName']?.toString()?.trim();
      final secondName = json['secondName']?.toString()?.trim();
      final thirdName = json['thirdName']?.toString()?.trim();
      final fourthName = json['fourthName']?.toString()?.trim();
      final nickName = json['nickName']?.toString()?.trim();
      
      if (firstName != null && firstName.isNotEmpty) {
        List<String> nameParts = [firstName];
        
        if (secondName != null && secondName.isNotEmpty && secondName != 'l') {
          nameParts.add(secondName);
        }
        if (thirdName != null && thirdName.isNotEmpty && thirdName != 'l') {
          nameParts.add(thirdName);
        }
        if (fourthName != null && fourthName.isNotEmpty && fourthName != 'l') {
          nameParts.add(fourthName);
        }
        
        final fullName = nameParts.join(' ');
        print('✅ تم بناء اسم الطالب: "$fullName" من الأجزاء: $nameParts');
        return fullName;
      }
      
      // محاولة الحصول على الاسم من حقول أخرى
      if (json['fullName'] != null && json['fullName'].toString().trim().isNotEmpty) {
        return json['fullName'].toString().trim();
      }
      if (json['studentName'] != null && json['studentName'].toString().trim().isNotEmpty) {
        return json['studentName'].toString().trim();
      }
      if (json['name'] != null && json['name'].toString().trim().isNotEmpty) {
        return json['name'].toString().trim();
      }
      if (json['displayName'] != null && json['displayName'].toString().trim().isNotEmpty) {
        return json['displayName'].toString().trim();
      }
      if (json['userName'] != null && json['userName'].toString().trim().isNotEmpty) {
        return json['userName'].toString().trim();
      }
      if (nickName != null && nickName.isNotEmpty) {
        return nickName;
      }
      
      // إذا كان هناك object للطالب
      if (json['student'] != null && json['student'] is Map) {
        final student = json['student'] as Map<String, dynamic>;
        if (student['fullName'] != null) return student['fullName'].toString().trim();
        if (student['name'] != null) return student['name'].toString().trim();
        if (student['studentName'] != null) return student['studentName'].toString().trim();
      }
      
      print('⚠️ لم يتم العثور على اسم الطالب في البيانات');
      return 'طالب غير معروف';
    }
    
    return StudentTermGrades(
      studentId: json['studentId']?.toString() ?? 
                 json['id']?.toString() ?? 
                 json['Id']?.toString() ?? '',
      studentName: constructFullName(),
      studentImage: json['studentImage']?.toString() ?? 
                    json['image']?.toString() ?? 
                    json['Image']?.toString(),
      firstTermAverage: _parseDouble(json['firstTermAverage']),
      midtermExam: _parseDouble(json['midtermExam']),
      secondTermAverage: _parseDouble(json['secondTermAverage']),
      annualAverage: _parseDouble(json['annualAverage']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentImage': studentImage,
      'firstTermAverage': firstTermAverage,
      'midtermExam': midtermExam,
      'secondTermAverage': secondTermAverage,
      'annualAverage': annualAverage,
    };
  }

  @override
  List<Object?> get props => [
        studentId,
        studentName,
        studentImage,
        firstTermAverage,
        midtermExam,
        secondTermAverage,
        annualAverage,
      ];
}
