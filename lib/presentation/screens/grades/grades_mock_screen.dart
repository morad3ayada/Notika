import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../data/models/student_grades_mock.dart';

class GradesMockScreen extends StatefulWidget {
  const GradesMockScreen({super.key});

  @override
  State<GradesMockScreen> createState() => _GradesMockScreenState();
}

class _GradesMockScreenState extends State<GradesMockScreen> {
  List<StudentGradesMock> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  /// تحميل البيانات التجريبية
  void _loadMockData() {
    // البيانات التجريبية كـ JSON string
    final jsonString = '''
    [
      {
        "absenceTimes": 0,
        "subjectName": "العربية",
        "grades": [
          {
            "title": "كويز",
            "grade": 10,
            "maxGrade": 10
          },
          {
            "title": "شفوي",
            "grade": 20,
            "maxGrade": 20
          }
        ],
        "quizAttempts": [
          {
            "quizTitle": "اللغة العربية - اختبار منتصف الفصل",
            "maxGrade": 20,
            "grade": 0
          }
        ],
        "firstName": "طالب",
        "secondName": "مبرمج",
        "thirdName": "فلاتر"
      }
    ]
    ''';

    try {
      // تحويل JSON string إلى List
      final List<dynamic> jsonList = json.decode(jsonString);
      
      // تحويل إلى قائمة StudentGradesMock
      final parsedStudents = parseStudentGradesMockList(jsonList);
      
      setState(() {
        students = parsedStudents;
        isLoading = false;
      });
      
      print('✅ تم تحميل ${students.length} طالب بنجاح');
      
      // طباعة البيانات للتحقق
      for (final student in students) {
        print('👤 ${student.fullName}');
        print('   المادة: ${student.subjectName}');
        print('   الغيابات: ${student.absenceTimes}');
        print('   الدرجات: ${student.grades.length}');
        for (final grade in student.grades) {
          print('      - ${grade.title}: ${grade.grade}/${grade.maxGrade}');
        }
        print('   الاختبارات: ${student.quizAttempts.length}');
        for (final quiz in student.quizAttempts) {
          print('      - ${quiz.quizTitle}: ${quiz.grade}/${quiz.maxGrade}');
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عرض الدرجات التجريبية'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد بيانات',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : Directionality(
                  textDirection: TextDirection.rtl,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: students.map((student) {
                        return _buildStudentCard(student);
                      }).toList(),
                    ),
                  ),
                ),
    );
  }

  /// بناء كارد الطالب
  Widget _buildStudentCard(StudentGradesMock student) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس الكارد - اسم الطالب والمادة
            Row(
              children: [
                // أيقونة الطالب
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1976D2),
                  child: Text(
                    student.firstName.isNotEmpty ? student.firstName[0] : '؟',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الاسم الكامل
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF233A5A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // المادة
                      Text(
                        'المادة: ${student.subjectName}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // عدد الغيابات
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: student.absenceTimes > 0
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: student.absenceTimes > 0
                          ? Colors.red.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'الغيابات',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.absenceTimes.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: student.absenceTimes > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            
            // قسم الدرجات
            if (student.grades.isNotEmpty) ...[
              const Text(
                'الدرجات اليومية:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A5A),
                ),
              ),
              const SizedBox(height: 12),
              ...student.grades.map((grade) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        grade.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF233A5A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${grade.grade.toInt()} / ${grade.maxGrade.toInt()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            
            // قسم الاختبارات
            if (student.quizAttempts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'الاختبارات:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF233A5A),
                ),
              ),
              const SizedBox(height: 12),
              ...student.quizAttempts.map((quiz) {
                final percentage = quiz.maxGrade > 0 
                    ? (quiz.grade / quiz.maxGrade * 100)
                    : 0.0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.quizTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // شريط التقدم
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: Colors.grey.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      percentage >= 50 ? Colors.green : Colors.orange,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // الدرجة
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${quiz.grade.toInt()} / ${quiz.maxGrade.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
