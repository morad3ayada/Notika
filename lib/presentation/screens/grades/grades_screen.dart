import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notika_teacher/data/models/grade_components.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/class_students/class_students_barrel.dart';

import '../../../logic/blocs/daily_grade_titles/daily_grade_titles_barrel.dart';
import '../../../logic/blocs/daily_grades/daily_grades_barrel.dart';
import '../../../logic/blocs/term_grades/term_grades_barrel.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/models/class_students_model.dart';
import '../../../data/models/daily_grade_titles_model.dart';
import '../../../data/models/daily_grades_model.dart';
import '../../../data/models/term_grades_model.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/class_students_repository.dart';
import '../../../data/repositories/daily_grade_titles_repository.dart';
import '../../../data/repositories/daily_grades_repository.dart';
import '../../../data/repositories/term_grades_repository.dart';
import '../../../di/injector.dart';
import '../../../utils/teacher_class_matcher.dart';
import '../../../utils/server_data_mixin.dart';
import '../../../logic/blocs/base/base_state.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> with ServerDataMixin<GradesScreen> {
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  String currentSemester = _getCurrentSemester();
  String gradeType = 'يومية'; // 'يومية' or 'فصلية'
  DateTime selectedDate = DateTime.now();
  
  /// تحديد الفصل الدراسي بناءً على التاريخ الحالي
  /// الفصل الأول: من أغسطس (8) إلى يناير (1)
  /// الفصل الثاني: من فبراير (2) إلى يوليو (7)
  static String _getCurrentSemester() {
    final now = DateTime.now();
    final month = now.month;
    
    // الفصل الثاني: من فبراير (2) إلى يوليو (7)
    // الفصل الأول: من أغسطس (8) إلى يناير (1)
    if (month >= 2 && month <= 7) {
      return 'الثاني';
    } else {
      return 'الأول';
    }
  }
  
  /// التحقق من إمكانية عرض الفصل الثاني
  /// الفصل الثاني يظهر فقط من شهر فبراير (2) إلى يوليو (7)
  static bool _canShowSecondSemester() {
    final now = DateTime.now();
    return now.month >= 2 && now.month <= 7;
  }
  late final ProfileBloc _profileBloc;
  late final ClassStudentsBloc _classStudentsBloc;
  late final DailyGradeTitlesBloc _dailyGradeTitlesBloc;
  late final DailyGradesBloc _dailyGradesBloc;
  late final TermGradesBloc _termGradesBloc;

  // قائمة الطلاب المجلوبة من السيرفر
  List<Student> _serverStudents = [];

  // قائمة عناوين الدرجات المجلوبة من السيرفر
  List<String> _serverGradeTitles = [];
  
  // قائمة الدرجات الفصلية من السيرفر
  List<StudentTermGrades> _termGrades = [];

  // Map لحفظ الدرجات: studentId -> (gradeTitleId -> grade)
  final Map<String, Map<String, TextEditingController>> _gradeControllers = {};

  // Map لحفظ عدد مرات الغياب: studentId -> absenceTimes
  final Map<String, int> _absenceTimes = {};

  // قوائم الكويزات والاسيمنتات من السيرفر
  List<QuizGrade> _allQuizzes = [];
  List<AssignmentGrade> _allAssignments = [];
  
  // Map لحفظ درجات الكويزات: studentId -> List<QuizGrade>
  final Map<String, List<QuizGrade>> _studentQuizzes = {};
  
  // Map لحفظ درجات الاسيمنتات: studentId -> List<AssignmentGrade>
  final Map<String, List<AssignmentGrade>> _studentAssignments = {};

  // متغير لحالة الحفظ
  bool _isSaving = false;

  // القوائم الديناميكية تُشتق من بيانات السيرفر (TeacherClass)
  List<String> _buildSchools(List<TeacherClass> classes) {
    final set = <String>{};
    for (final c in classes) {
      if ((c.schoolName ?? '').trim().isNotEmpty) set.add(c.schoolName!.trim());
    }
    return set.toList();
  }

  List<String> _buildStages(List<TeacherClass> classes, String? school) {
    if (school == null) return const [];
    final set = <String>{};
    for (final c in classes.where((e) => e.schoolName == school)) {
      if ((c.levelName ?? '').trim().isNotEmpty) set.add(c.levelName!.trim());
    }
    return set.toList();
  }

  List<String> _buildSections(
      List<TeacherClass> classes, String? school, String? stage) {
    if (school == null || stage == null) return const [];
    final set = <String>{};
    for (final c in classes
        .where((e) => e.schoolName == school && e.levelName == stage)) {
      if ((c.className ?? '').trim().isNotEmpty) set.add(c.className!.trim());
    }
    return set.toList();
  }

  List<String> _buildSubjects(List<TeacherClass> classes, String? school,
      String? stage, String? section) {
    if (school == null || stage == null || section == null) return const [];
    final set = <String>{};
    for (final c in classes.where((e) =>
        e.schoolName == school &&
        e.levelName == stage &&
        e.className == section)) {
        set.add(c.subjectName!.trim());
    }
    return set.toList();
  }

  /// بناء صف الطالب من بيانات السيرفر - بدون scroll داخلي
  Widget _buildStudentRow(
      Student student, List<DailyGradeTitle> gradeTitles, int index) {
    print('🎓 عرض الطالب: ${student.displayName} (ID: ${student.id})');

    // الحصول على عدد مرات الغياب
    final absenceTimes = _absenceTimes[student.id] ?? 0;
    
    // الحصول على كويزات واسيمنتات الطالب
    final studentQuizzes = _studentQuizzes[student.id] ?? [];
    final studentAssignments = _studentAssignments[student.id] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Row(
        children: [
          // اسم الطالب - ثابت
          Container(
            width: 120,
            height: 60,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: index.isEven
                    ? const Color(0xFFE3F2FD)
                    : const Color(0xFFBBDEFB),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Text(
                student.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // عمود عدد مرات الغياب
          Container(
            width: 80,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: absenceTimes > 0 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: absenceTimes > 0 
                    ? Colors.red.withOpacity(0.3)
                    : Colors.green.withOpacity(0.3),
              ),
            ),
            child: Text(
              absenceTimes.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: absenceTimes > 0 ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // حقول الدرجات من السيرفر - بدون scroll
          ...gradeTitles.map((gradeTitle) {
            // الحصول على أو إنشاء controller للطالب والعنوان
            if (!_gradeControllers.containsKey(student.id)) {
              _gradeControllers[student.id!] = {};
            }
            if (!_gradeControllers[student.id]!.containsKey(gradeTitle.id)) {
              _gradeControllers[student.id]![gradeTitle.id!] = TextEditingController();
            }
            
            final controller = _gradeControllers[student.id]![gradeTitle.id!]!;
            
            return Container(
              width: 100,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.5),
                    fontSize: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 12,
                ),
                // السماح بالتعديل في كلا الفصلين
                readOnly: false,
              ),
            );
          }).toList(),
          
          // أعمدة الكويزات
          ..._allQuizzes.map((quiz) {
            // البحث عن درجة الطالب في هذا الكويز
            final studentQuiz = studentQuizzes.firstWhere(
              (q) => q.title == quiz.title,
              orElse: () => QuizGrade(title: quiz.title, grade: 0),
            );
            
            return Container(
              width: 100,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                ),
              ),
              child: Text(
                studentQuiz.grade > 0 ? studentQuiz.grade.toStringAsFixed(0) : '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
          
          // أعمدة الاسيمنتات
          ..._allAssignments.map((assignment) {
            // البحث عن درجة الطالب في هذا الاسيمنت
            final studentAssignment = studentAssignments.firstWhere(
              (a) => a.title == assignment.title,
              orElse: () => AssignmentGrade(title: assignment.title, grade: 0),
            );
            
            return Container(
              width: 100,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Text(
                studentAssignment.grade > 0 ? studentAssignment.grade.toStringAsFixed(0) : '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// دالة جلب عناوين الدرجات والدرجات تلقائياً عند اختيار المادة
  void _loadGradeTitles(List<TeacherClass> classes) {
    if (selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null ||
        selectedSubject == null) {
      print('⚠️ لم يتم اختيار جميع الحقول المطلوبة');
      return;
    }

    print('🔍 البحث عن TeacherClass المطابق...');
    print('   المدرسة المختارة: $selectedSchool');
    print('   المرحلة المختارة: $selectedStage');
    print('   الشعبة المختارة: $selectedSection');
    print('   المادة المختارة: $selectedSubject');
    
    // طباعة جميع الـ classes المتاحة للتشخيص
    print('📚 عدد الـ classes المتاحة: ${classes.length}');
    for (var i = 0; i < classes.length && i < 3; i++) {
      final c = classes[i];
      print('   Class $i: school="${c.schoolName}", level="${c.levelName}", class="${c.className}", subject="${c.subjectName}"');
      print('      IDs: levelSubjectId="${c.levelSubjectId}", levelId="${c.levelId}", classId="${c.classId}"');
    }

    // البحث عن TeacherClass المطابق
    TeacherClass? matchingClass;
    try {
      matchingClass = classes.firstWhere(
        (c) =>
            c.schoolName?.trim() == selectedSchool?.trim() &&
            c.levelName?.trim() == selectedStage?.trim() &&
            c.className?.trim() == selectedSection?.trim() &&
            c.subjectName?.trim() == selectedSubject?.trim(),
      );
    } catch (e) {
      print('❌ لم يتم العثور على TeacherClass مطابق');
      print('   الخطأ: $e');
    }

    // التحقق من وجود جميع المعرفات المطلوبة
    if (matchingClass != null &&
        matchingClass.subjectId != null &&
        matchingClass.levelId != null &&
        matchingClass.classId != null &&
        matchingClass.levelSubjectId != null) {
      
      print('═══════════════════════════════════════════════════════');
      print('✅ تم العثور على TeacherClass المطابق');
      print('═══════════════════════════════════════════════════════');
      print('📋 بيانات الفصل من Profile:');
      print('   - School: ${matchingClass.schoolName}');
      print('   - Stage: ${matchingClass.levelName}');
      print('   - Section: ${matchingClass.className}');
      print('   - Subject: ${matchingClass.subjectName}');
      print('');
      print('📊 المعرفات (IDs) التي سيتم إرسالها للسيرفر:');
      print('   - SubjectId: ${matchingClass.subjectId}  ← من Profile');
      print('   - LevelId: ${matchingClass.levelId}');
      print('   - ClassId: ${matchingClass.classId}');
      print('   - LevelSubjectId: ${matchingClass.levelSubjectId} (للعناوين فقط)');
      print('');
      
      // تنسيق التاريخ بصيغة ISO 8601 (YYYY-MM-DD) كما يتوقع السيرفر
      final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      print('📅 التاريخ المحدد:');
      print('   - التاريخ الأصلي: $selectedDate');
      print('   - التاريخ المنسق (YYYY-MM-DD): $formattedDate');
      print('═══════════════════════════════════════════════════════');
      print('');

      // جلب عناوين الدرجات
      print('🔄 جلب عناوين الدرجات...');
      _dailyGradeTitlesBloc.add(LoadDailyGradeTitlesEvent(
        levelSubjectId: matchingClass.levelSubjectId!,
        levelId: matchingClass.levelId!,
        classId: matchingClass.classId!,
      ));
      
      print('🔄 جلب درجات الطلاب...');
      _dailyGradesBloc.add(LoadClassStudentsGradesEvent(
        subjectId: matchingClass.subjectId!,  // ✅ subjectId الفعلي من Profile
        levelId: matchingClass.levelId!,
        classId: matchingClass.classId!,
        date: formattedDate,
      ));
    } else {
      print('❌ لم يتم العثور على معرفات المرحلة والفصل والمادة');
      if (matchingClass != null) {
        print('   SubjectId: ${matchingClass.subjectId}');
        print('   LevelSubjectId: ${matchingClass.levelSubjectId}');
        print('   LevelId: ${matchingClass.levelId}');
        print('   ClassId: ${matchingClass.classId}');
      } else {
        print('   matchingClass is null');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لم يتم العثور على معرفات الفصل والمادة'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// دالة جلب الطلاب عند اختيار المرحلة والشعبة
  void _loadClassStudents(List<TeacherClass> classes) {
    if (selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null) {
      return;
    }

    // البحث عن TeacherClass المطابق
    final matchingClass = classes.firstWhere(
      (c) =>
          c.schoolName == selectedSchool &&
          c.levelName == selectedStage &&
          c.className == selectedSection,
      orElse: () => TeacherClass(),
    );

    if (matchingClass.levelId != null && matchingClass.classId != null) {
      print('🔄 جلب طلاب الفصل...');
      print('📚 LevelId: ${matchingClass.levelId}');
      print('📚 ClassId: ${matchingClass.classId}');

      _classStudentsBloc.add(LoadClassStudentsEvent(
        levelId: matchingClass.levelId!,
        classId: matchingClass.classId!,
      ));
    } else {
      print('❌ لم يتم العثور على معرفات المرحلة والفصل');
    }
  }

  /// دالة جلب الدرجات الفصلية عند اختيار المادة
  void _loadTermGrades(List<TeacherClass> classes) {
    if (selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null ||
        selectedSubject == null) {
      print('⚠️ لم يتم اختيار جميع الحقول المطلوبة للدرجات الفصلية');
      return;
    }

    print('🔍 البحث عن TeacherClass المطابق للدرجات الفصلية...');
    
    // البحث عن TeacherClass المطابق
    TeacherClass? matchingClass;
    try {
      matchingClass = classes.firstWhere(
        (c) =>
            c.schoolName?.trim() == selectedSchool?.trim() &&
            c.levelName?.trim() == selectedStage?.trim() &&
            c.className?.trim() == selectedSection?.trim() &&
            c.subjectName?.trim() == selectedSubject?.trim(),
      );
    } catch (e) {
      print('❌ لم يتم العثور على TeacherClass مطابق');
    }

    // التحقق من وجود جميع المعرفات المطلوبة
    if (matchingClass != null &&
        matchingClass.subjectId != null &&
        matchingClass.levelId != null &&
        matchingClass.classId != null) {
      
      print('═══════════════════════════════════════════════════════');
      print('✅ جلب الدرجات الفصلية');
      print('═══════════════════════════════════════════════════════');
      print('📋 بيانات الفصل:');
      print('   - School: ${matchingClass.schoolName}');
      print('   - Stage: ${matchingClass.levelName}');
      print('   - Section: ${matchingClass.className}');
      print('   - Subject: ${matchingClass.subjectName}');
      print('');
      print('📊 المعرفات:');
      print('   - SubjectId: ${matchingClass.subjectId}');
      print('   - LevelId: ${matchingClass.levelId}');
      print('   - ClassId: ${matchingClass.classId}');
      print('═══════════════════════════════════════════════════════');
      
      _termGradesBloc.add(LoadTermGradesEvent(
        subjectId: matchingClass.subjectId!,
        levelId: matchingClass.levelId!,
        classId: matchingClass.classId!,
      ));
    } else {
      print('❌ لم يتم العثور على معرفات الفصل والمادة للدرجات الفصلية');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لم يتم العثور على معرفات الفصل والمادة'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Students data with dynamic components
  final Map<String, List<Map<String, dynamic>>> sectionStudents = {
    'شعبة أ': [
      {'name': 'أحمد محمد', 'إجمالي الغياب': '2'},
      {'name': 'فاطمة علي', 'إجمالي الغياب': '0'},
      {'name': 'محمد حسن', 'إجمالي الغياب': '1'},
      {'name': 'عائشة أحمد', 'إجمالي الغياب': '3'},
    ],
    'شعبة ب': [
      {'name': 'علي محمود', 'إجمالي الغياب': '0'},
      {'name': 'مريم سعيد', 'إجمالي الغياب': '1'},
      {'name': 'حسن عبدالله', 'إجمالي الغياب': '2'},
      {'name': 'زينب محمد', 'إجمالي الغياب': '0'},
    ],
    'شعبة ج': [
      {'name': 'عبدالله أحمد', 'إجمالي الغياب': '1'},
      {'name': 'نور الهدى', 'إجمالي الغياب': '0'},
      {'name': 'يوسف علي', 'إجمالي الغياب': '0'},
      {'name': 'سارة محمود', 'إجمالي الغياب': '2'},
    ],
    'شعبة د': [
      {'name': 'محمود حسن', 'إجمالي الغياب': '0'},
      {'name': 'ليلى أحمد', 'إجمالي الغياب': '1'},
      {'name': 'كريم محمد', 'إجمالي الغياب': '0'},
      {'name': 'رنا علي', 'إجمالي الغياب': '0'},
    ],
  };

  // Initialize student data with empty values for components
  void _initializeStudentData(List<String> components) {
    sectionStudents.forEach((section, students) {
      for (var student in students) {
        // Ensure student has the absence field
        if (!student.containsKey('إجمالي الغياب')) {
          student['إجمالي الغياب'] = '0';
        }

        // Initialize other components
        for (var component in components) {
          if (component != 'إجمالي الغياب' && !student.containsKey(component)) {
            student[component] = '';
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _profileBloc = ProfileBloc(sl<ProfileRepository>())..add(const FetchProfile());
    _classStudentsBloc = ClassStudentsBloc(sl<ClassStudentsRepository>());
    _dailyGradeTitlesBloc = DailyGradeTitlesBloc(sl<DailyGradeTitlesRepository>());
    _dailyGradesBloc = DailyGradesBloc(sl<DailyGradesRepository>());
    _termGradesBloc = TermGradesBloc(sl<TermGradesRepository>());
    
    // طباعة عند بداية الشاشة
    final now = DateTime.now();
    final canShow = now.month >= 2 && now.month <= 7;
    print('═══════════════════════════════════════════');
    print('🎓 شاشة الدرجات - تم البدء');
    print('📅 التاريخ الحالي: ${now.day}/${now.month}/${now.year}');
    print('📅 الشهر الحالي: ${now.month}');
    print('📊 هل يظهر الفصل الثاني؟ ${canShow ? "نعم ✅ (شهر 2-7)" : "لا ❌ (خارج 2-7)"}');
    print('═══════════════════════════════════════════');
  }

  @override
  void dispose() {
    // تنظيف controllers
    for (final studentControllers in _gradeControllers.values) {
      for (final controller in studentControllers.values) {
        controller.dispose();
      }
    }
    _gradeControllers.clear();
    
    _profileBloc.close();
    _classStudentsBloc.close();
    _dailyGradeTitlesBloc.close();
    _dailyGradesBloc.close();
    _termGradesBloc.close();
    super.dispose();
  }

  @override
  Future<void> loadServerData() async {
    // جلب البيانات من السيرفر عند الدخول للشاشة
    _profileBloc.add(const FetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final gradeComponents = context.watch<GradeComponents>().components;
    
    // التحقق من إمكانية عرض الفصل الثاني (من شهر 2 إلى شهر 7 فقط)
    final now = DateTime.now();
    final canShowSecondSemester = now.month >= 2 && now.month <= 7;
    
    // طباعة للتشخيص
    debugPrint('📅 الشهر الحالي: ${now.month}');
    debugPrint('📊 عرض الفصل الثاني: ${canShowSecondSemester ? "نعم ✅" : "لا ❌"}');
    debugPrint('📚 الفصل الحالي: $currentSemester');

    // Initialize student data with current components
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStudentData(gradeComponents);
    });

    return MultiBlocListener(
      listeners: [
        // مستمع لعناوين الدرجات
        BlocListener<DailyGradeTitlesBloc, DailyGradeTitlesState>(
          bloc: _dailyGradeTitlesBloc,
          listener: (context, state) {
            if (state is DailyGradeTitlesLoaded) {
              setState(() {
                _serverGradeTitles = state.titleNames;
              });
              print(
                  '✅ تم تحديث عناوين الدرجات: ${state.titleNames.join(', ')}');
            } else if (state is DailyGradeTitlesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ في جلب عناوين الدرجات: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is DailyGradeTitlesEmpty) {
              setState(() {
                _serverGradeTitles = [];
              });
              print('📭 لا توجد عناوين درجات محددة');
            }
          },
        ),
        // مستمع للدرجات
        BlocListener<DailyGradesBloc, DailyGradesState>(
          bloc: _dailyGradesBloc,
          listener: (context, state) {
            if (state is DailyGradesLoaded) {
              print('✅ تم جلب درجات ${state.studentGrades.length} طالب من السيرفر');
              
              // جمع جميع الكويزات والاسيمنتات المتوفرة
              final allQuizzesSet = <String, QuizGrade>{};
              final allAssignmentsSet = <String, AssignmentGrade>{};
              
              print('🔍 بدء معالجة درجات ${state.studentGrades.length} طالب');
              
              // تحديث الـ controllers بالدرجات من السيرفر
              for (final studentGrade in state.studentGrades) {
                final studentId = studentGrade.studentId;
                
                print('👤 معالجة الطالب: $studentId');
                print('   - الكويزات: ${studentGrade.quizzes.length}');
                print('   - الاسيمنتات: ${studentGrade.assignments.length}');
                
                // حفظ عدد مرات الغياب
                if (studentGrade.absenceTimes != null) {
                  _absenceTimes[studentId] = studentGrade.absenceTimes!;
                  print('   - absenceTimes: ${studentGrade.absenceTimes}');
                }
                
                // حفظ الكويزات
                _studentQuizzes[studentId] = studentGrade.quizzes;
                for (final quiz in studentGrade.quizzes) {
                  allQuizzesSet[quiz.title] = quiz;
                  print('   - كويز: ${quiz.title} = ${quiz.grade}/${quiz.maxGrade}');
                }
                
                // حفظ الاسيمنتات
                _studentAssignments[studentId] = studentGrade.assignments;
                for (final assignment in studentGrade.assignments) {
                  allAssignmentsSet[assignment.title] = assignment;
                  print('   - اسيمنت: ${assignment.title} = ${assignment.grade}/${assignment.maxGrade}');
                }
                
                // التأكد من وجود map للطالب
                if (!_gradeControllers.containsKey(studentId)) {
                  _gradeControllers[studentId] = {};
                }
                
                // تحديث كل درجة
                for (final grade in studentGrade.dailyGrades) {
                  final titleId = grade.dailyGradeTitleId;
                  
                  if (!_gradeControllers[studentId]!.containsKey(titleId)) {
                    _gradeControllers[studentId]![titleId] = TextEditingController();
                  }
                  
                  // تحديث القيمة
                  _gradeControllers[studentId]![titleId]!.text = 
                      grade.grade.toInt().toString();
                }
              }
              
              setState(() {
                // حفظ قوائم الكويزات والاسيمنتات
                _allQuizzes = allQuizzesSet.values.toList();
                _allAssignments = allAssignmentsSet.values.toList();
                
                print('✅ إجمالي الكويزات المختلفة: ${_allQuizzes.length}');
                for (final quiz in _allQuizzes) {
                  print('   📝 ${quiz.title}');
                }
                
                print('✅ إجمالي الاسيمنتات المختلفة: ${_allAssignments.length}');
                for (final assignment in _allAssignments) {
                  print('   📋 ${assignment.title}');
                }
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم جلب درجات ${state.studentGrades.length} طالب بنجاح'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is DailyGradesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ في جلب الدرجات: ${state.message}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is DailyGradesEmpty) {
              print('📭 لا توجد درجات مسجلة لهذا التاريخ');
              // تنظيف الـ controllers و absenceTimes
              setState(() {
                for (final studentControllers in _gradeControllers.values) {
                  for (final controller in studentControllers.values) {
                    controller.clear();
                  }
                }
                _absenceTimes.clear();
                _studentQuizzes.clear();
                _studentAssignments.clear();
                _allQuizzes.clear();
                _allAssignments.clear();
              });
            }
          },
        ),
        // مستمع للدرجات الفصلية
        BlocListener<TermGradesBloc, TermGradesState>(
          bloc: _termGradesBloc,
          listener: (context, state) {
            if (state is TermGradesLoaded) {
              print('✅ تم جلب درجات ${state.studentGrades.length} طالب من السيرفر (فصلية)');
              setState(() {
                _termGrades = state.studentGrades;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم جلب درجات ${state.studentGrades.length} طالب بنجاح'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is TermGradesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ في جلب الدرجات الفصلية: ${state.message}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is TermGradesEmpty) {
              print('📭 لا توجد درجات فصلية مسجلة');
              setState(() {
                _termGrades = [];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لا توجد درجات فصلية مسجلة لهذا الفصل'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF233A5A), Color(0xFF1976D2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "إدخال الدرجات",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: BlocBuilder<ProfileBloc, ProfileState>(
            bloc: _profileBloc,
            builder: (context, state) {
              if (state is ProfileLoading || state is ProfileInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProfileError) {
                return Center(
                  child: Text(
                    state.message,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                );
              }

              final loaded = state as ProfileLoaded;
              final classes = loaded.classes;
              final schools = _buildSchools(classes);
              final stages = _buildStages(classes, selectedSchool);
              final sections =
                  _buildSections(classes, selectedSchool, selectedStage);
              final subjects = _buildSubjects(
                  classes, selectedSchool, selectedStage, selectedSection);

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اختيار المدرسة
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: schools.map((school) {
                              final isSelected = selectedSchool == school;
                              return Container(
                                margin: const EdgeInsets.only(left: 12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(25),
                                    onTap: () {
                                      setState(() {
                                        selectedSchool = school;
                                        selectedStage = null;
                                        selectedSection = null;
                                        selectedSubject = null;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFF1976D2),
                                                  Color(0xFF64B5F6)
                                                ],
                                                begin: Alignment.centerRight,
                                                end: Alignment.centerLeft,
                                              )
                                            : null,
                                        color: isSelected
                                            ? null
                                            : Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        school,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color ??
                                                  const Color(0xFF233A5A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // اختيار المرحلة
                      if (selectedSchool != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: stages.map((stage) {
                                final isSelected = selectedStage == stage;
                                return Container(
                                  margin: const EdgeInsets.only(left: 12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: () {
                                        setState(() {
                                          selectedStage = stage;
                                          selectedSection = null;
                                          selectedSubject = null;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFF1976D2),
                                                    Color(0xFF64B5F6)
                                                  ],
                                                  begin: Alignment.centerRight,
                                                  end: Alignment.centerLeft,
                                                )
                                              : null,
                                          color: isSelected
                                              ? null
                                              : Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          stage,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.color ??
                                                    const Color(0xFF233A5A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      // اختيار الشعبة
                      if (selectedStage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: sections.map((section) {
                                final isSelected = selectedSection == section;
                                return Container(
                                  margin: const EdgeInsets.only(left: 12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: () {
                                        setState(() {
                                          selectedSection = section;
                                          selectedSubject = null;
                                        });
                                        // جلب الطلاب عند اختيار الشعبة
                                        _loadClassStudents(classes);
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                        decoration: BoxDecoration(
                                          gradient: isSelected
                                              ? const LinearGradient(
                                                  colors: [
                                                    Color(0xFF1976D2),
                                                    Color(0xFF64B5F6)
                                                  ],
                                                  begin: Alignment.centerRight,
                                                  end: Alignment.centerLeft,
                                                )
                                              : null,
                                          color: isSelected
                                              ? null
                                              : Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          section,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.color ??
                                                    const Color(0xFF233A5A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      // اختيار المادة
                      if (selectedSection != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: subjects.map((subject) {
                                    final isSelected =
                                        selectedSubject == subject;
                                    return Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          onTap: () {
                                            setState(() {
                                              selectedSubject = subject;
                                            });
                                            // جلب عناوين الدرجات عند اختيار المادة
                                            _loadGradeTitles(classes);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Color(0xFF1976D2),
                                                        Color(0xFF64B5F6)
                                                      ],
                                                      begin:
                                                          Alignment.centerRight,
                                                      end: Alignment.centerLeft,
                                                    )
                                                  : null,
                                              color: isSelected
                                                  ? null
                                                  : Theme.of(context).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              subject,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.color ??
                                                        const Color(0xFF233A5A),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            // اختيار نوع الدرجات
                            if (selectedSubject != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildGradeTypeButton('يومية', classes),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildGradeTypeButton('فصلية', classes),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                      // اختيار الفصل الدراسي (يظهر فقط في حالة الدرجات اليومية)
                      if (selectedSubject != null && gradeType == 'يومية')
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12),
                          child: Builder(
                            builder: (context) {
                              print('🔍 بناء أزرار الفصول الدراسية');
                              print('   - الشهر الحالي: ${DateTime.now().month}');
                              print('   - canShowSecondSemester: $canShowSecondSemester');
                              print('   - سيتم عرض: ${canShowSecondSemester ? "زرين (الأول + الثاني)" : "زر واحد (الأول فقط)"}');
                              
                              return canShowSecondSemester
                              ? Row(
                                  children: [
                                    // الفصل الأول
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => currentSemester = 'الأول'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          decoration: BoxDecoration(
                                            gradient: currentSemester == 'الأول'
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFF1976D2),
                                                      Color(0xFF64B5F6)
                                                    ],
                                                    begin: Alignment.centerRight,
                                                    end: Alignment.centerLeft,
                                                  )
                                                : null,
                                            color: currentSemester == 'الأول'
                                                ? null
                                                : Colors.grey[200],
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              right: Radius.circular(16),
                                              left: Radius.zero,
                                            ),
                                            boxShadow: currentSemester == 'الأول'
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withOpacity(0.2),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            'الفصل الأول',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: currentSemester == 'الأول'
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // الفصل الثاني
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => currentSemester = 'الثاني'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          decoration: BoxDecoration(
                                            gradient: currentSemester == 'الثاني'
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFF1976D2),
                                                      Color(0xFF64B5F6)
                                                    ],
                                                    begin: Alignment.centerRight,
                                                    end: Alignment.centerLeft,
                                                  )
                                                : null,
                                            color: currentSemester == 'الثاني'
                                                ? null
                                                : Colors.grey[200],
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              left: Radius.circular(16),
                                              right: Radius.zero,
                                            ),
                                            boxShadow: currentSemester == 'الثاني'
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withOpacity(0.2),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Text(
                                            'الفصل الثاني',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: currentSemester == 'الثاني'
                                            ? Colors.white
                                            : Colors.grey[700],
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                              : // خارج شهر 2-7: عرض الفصل الأول فقط بعرض الشاشة الكامل
                              SizedBox(
                                  width: double.infinity,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => currentSemester = 'الأول'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1976D2),
                                            Color(0xFF64B5F6)
                                          ],
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'الفصل الأول',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                            },
                          ),
                        ),
                      
                      // جدول الطلاب (يختلف حسب نوع الدرجات)
                        if (selectedSubject != null) ...[
                        if (gradeType == 'فصلية')
                          _buildTermGradesTable()
                        else
                          BlocBuilder<DailyGradeTitlesBloc, DailyGradeTitlesState>(
                            bloc: _dailyGradeTitlesBloc,
                            builder: (context, titlesState) {
                              // معالجة حالة التحميل
                              if (titlesState is DailyGradeTitlesLoading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 10),
                                        Text('جاري تحميل عناوين الدرجات...'),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              // معالجة حالة الخطأ
                              if (titlesState is DailyGradeTitlesError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                                        const SizedBox(height: 10),
                                        Text(
                                          'خطأ: ${titlesState.message}',
                                          style: const TextStyle(color: Colors.red),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: () => _loadGradeTitles(
                                            (state as ProfileLoaded).classes,
                                          ),
                                          child: const Text('إعادة المحاولة'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              // معالجة حالة القائمة الفارغة
                              if (titlesState is DailyGradeTitlesEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
                                        const SizedBox(height: 10),
                                        Text(
                                          'لا توجد عناوين درجات محددة لهذه المادة',
                                          style: TextStyle(color: Colors.grey[600]),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              final gradeTitles = titlesState is DailyGradeTitlesLoaded 
                                  ? titlesState.titles 
                                  : <DailyGradeTitle>[];
                              
                              print('📊 عدد عناوين الدرجات المحملة: ${gradeTitles.length}');
                              
                              return Column(
                                children: [
                                  const SizedBox(height: 12),
                                  // الجدول بالكامل مع scroll أفقي موحد
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Column(
                                      children: [
                                        // رأس الجدول
                                        Row(
                                          children: [
                                            // عمود اسم الطالب
                                            Container(
                                              width: 120,
                                              height: 50,
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: const Text(
                                                'اسم الطالب',
                                                style: TextStyle(
                                                  color: Color(0xFF1976D2),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            
                                            // عمود عدد مرات الغياب
                                            Container(
                                              width: 80,
                                              height: 50,
                                              alignment: Alignment.center,
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              child: const Text(
                                                'الغياب',
                                                style: TextStyle(
                                                  color: Color(0xFF1976D2),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            
                                            // أعمدة الدرجات
                                            ...gradeTitles.map((title) {
                                              return Container(
                                                width: 100,
                                                height: 50,
                                                alignment: Alignment.center,
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      title.displayTitle,
                                                      style: const TextStyle(
                                                        color: Color(0xFF1976D2),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (title.maxGrade != null && title.maxGrade! > 0)
                                                      Text(
                                                        '(${title.maxGrade!.toStringAsFixed(title.maxGrade! % 1 == 0 ? 0 : 1)})',
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            
                                            // أعمدة الكويزات
                                            ..._allQuizzes.map((quiz) {
                                              return Container(
                                                width: 100,
                                                height: 50,
                                                alignment: Alignment.center,
                                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      quiz.title,
                                                      style: const TextStyle(
                                                        color: Colors.purple,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (quiz.maxGrade != null && quiz.maxGrade! > 0)
                                                      Text(
                                                        '(${quiz.maxGrade!.toStringAsFixed(quiz.maxGrade! % 1 == 0 ? 0 : 1)})',
                                                        style: TextStyle(
                                                          color: Colors.purple[300],
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                            
                                            // أعمدة الاسيمنتات
                                            ..._allAssignments.map((assignment) {
                                              return Container(
                                                width: 100,
                                                height: 50,
                                                alignment: Alignment.center,
                                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      assignment.title,
                                                      style: const TextStyle(
                                                        color: Colors.orange,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (assignment.maxGrade != null && assignment.maxGrade! > 0)
                                                      Text(
                                                        '(${assignment.maxGrade!.toStringAsFixed(assignment.maxGrade! % 1 == 0 ? 0 : 1)})',
                                                        style: TextStyle(
                                                          color: Colors.orange[300],
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ],
                                        ),
                                        const Divider(thickness: 1.2),
                                        // صفوف الطلاب
                                        BlocConsumer<ClassStudentsBloc, ClassStudentsState>(
                                          bloc: _classStudentsBloc,
                                          listener: (context, state) {
                                            if (state is ClassStudentsLoaded) {
                                              setState(() {
                                                _serverStudents = state.students;
                                              });
                                              print('✅ تم تحديث قائمة الطلاب: ${state.students.length} طالب');
                                            } else if (state is ClassStudentsError) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(state.message),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          builder: (context, state) {
                                            if (state is ClassStudentsLoading) {
                                              return const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(20.0),
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );
                                            } else if (state is ClassStudentsEmpty) {
                                              return Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(20.0),
                                                  child: Text(
                                                    state.message,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              );
                                            } else if (state is ClassStudentsLoaded) {
                                              // عرض صفوف الطلاب
                                              return Column(
                                                children: state.students.asMap().entries.map((entry) {
                                                  final index = entry.key;
                                                  final student = entry.value;
                                                  return _buildStudentRow(student, gradeTitles, index);
                                                }).toList(),
                                              );
                                            } else {
                                    // Fallback للبيانات المحلية القديمة
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          (sectionStudents[selectedSection] ??
                                                  [])
                                              .length,
                                      itemBuilder: (context, index) {
                                        final student =
                                            (sectionStudents[selectedSection] ??
                                                [])[index];
                                        // Initialize student data if not already done
                                        if (student.length <= 1) {
                                          for (var component
                                              in gradeComponents) {
                                            if (component != 'إجمالي الغياب' &&
                                                !student
                                                    .containsKey(component)) {
                                              student[component] = '';
                                            }
                                          }
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 4),
                                          child: Row(
                                            children: [
                                              // Student name
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  student['name'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                              ),
                                              // Fixed Absence Cell
                                              Expanded(
                                                child: Text(
                                                  student['إجمالي الغياب'] ??
                                                      '0',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              // Dynamic Components (excluding absence)
                                              ...gradeComponents
                                                  .where((c) =>
                                                      c != 'إجمالي الغياب')
                                                  .map((component) {
                                                return Expanded(
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                                    child: TextField(
                                                      controller:
                                                          TextEditingController(
                                                              text: student[
                                                                      component] ??
                                                                  ''),
                                                      textAlign:
                                                          TextAlign.center,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: '0',
                                                        hintStyle: TextStyle(
                                                          color: Colors.grey
                                                              .withOpacity(0.5),
                                                          fontSize: 12,
                                                        ),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.3),
                                                          ),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                    0.3),
                                                          ),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          borderSide:
                                                              const BorderSide(
                                                            color: Color(
                                                                0xFF1976D2),
                                                          ),
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 8,
                                                        ),
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                            : Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.color,
                                                      ),
                                                      // السماح بالتعديل في كلا الفصلين
                                                      onChanged: (value) {
                                                        setState(() {
                                                          student[component] = value;
                                                        });
                                                      },
                                                      readOnly: false,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  // زر الحفظ متاح في كلا الفصلين
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _saveGrades,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1976D2),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 4,
                                        ),
                                        child: const Text(
                                          'حفظ الدرجات',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                      ] else
                        // رسالة عند عدم اختيار مادة
                        SizedBox(
                          height: 220,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.grade_outlined,
                                  size: 80,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'اختر المادة لعرض الطلاب',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // بناء زر نوع الدرجات
  Widget _buildGradeTypeButton(String type, List<TeacherClass> classes) {
    final isSelected = gradeType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            gradeType = type;
          });
          // جلب الدرجات الفصلية عند اختيار نوع فصلية
          if (type == 'فصلية' && selectedSubject != null) {
            _loadTermGrades(classes);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  )
                : null,
            color: isSelected ? null : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Text(
            'درجات $type',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Calculate annual average based on the formula: (firstTerm + midterm + secondTerm) / 3
  String _calculateAnnualAverage(Map<String, dynamic> student) {
    try {
      final firstTerm =
          double.tryParse(student['firstTermAvg']?.toString() ?? '0') ?? 0;
      final midterm =
          double.tryParse(student['midtermExam']?.toString() ?? '0') ?? 0;
      final secondTerm =
          double.tryParse(student['secondTermAvg']?.toString() ?? '0') ?? 0;

      final average = (firstTerm + midterm + secondTerm) / 3;
      return average.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  // بناء جدول الدرجات الفصلية
  Widget _buildTermGradesTable() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(
                label: Text(
                  'اسم الطالب',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              DataColumn(
                label: Text(
                  'معدل الفصل الأول',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'امتحان نصف السنة',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'معدل الفصل الثاني',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'المعدل السنوي',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                numeric: true,
              ),
            ],
            rows: _termGrades.isNotEmpty
                ? List<DataRow>.generate(
                    _termGrades.length,
                    (index) {
                      final student = _termGrades[index];

                      return DataRow(
                        cells: [
                          // Student Name
                          DataCell(
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.centerRight,
                              child: Text(
                                student.studentName,
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          // First Term Average
                          DataCell(
                            Container(
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.center,
                              child: Text(
                                student.firstTermAverage?.toStringAsFixed(2) ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          // Midterm Exam (read-only)
                          DataCell(
                            Container(
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.center,
                              child: Text(
                                student.midtermExam?.toStringAsFixed(2) ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          // Second Term Average
                          DataCell(
                            Container(
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.center,
                              child: Text(
                                student.secondTermAverage?.toStringAsFixed(2) ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          // Annual Average (calculated)
                          DataCell(
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                student.annualAverage?.toStringAsFixed(2) ?? '-',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : [],
          ),
        ),
      ],
    );
  }

  Future<void> _saveGrades() async {
    // التحقق من نوع الدرجات
    if (gradeType != 'يومية') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حفظ الدرجات الفصلية غير مدعوم حالياً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // التحقق من وجود اختيارات
    if (selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null ||
        selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار المدرسة والمرحلة والشعبة والمادة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // الحصول على TeacherClass
    final profileState = _profileBloc.state;
    if (profileState is! ProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: لم يتم تحميل بيانات المعلم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق من وجود classes في البيانات
    if (profileState.classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد فصول متاحة للمعلم في البيانات المحملة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🔍 البحث عن TeacherClass المطابق...');
    print('   المدرسة المختارة: $selectedSchool');
    print('   المرحلة المختارة: $selectedStage');
    print('   الشعبة المختارة: $selectedSection');
    print('   المادة المختارة: $selectedSubject');

    // طباعة جميع الـ classes المتاحة للتشخيص
    print('📚 عدد الـ classes المتاحة: ${profileState.classes.length}');
    for (var i = 0; i < profileState.classes.length && i < 5; i++) {
      final c = profileState.classes[i];
      print('   Class $i:');
      print('     schoolName: "${c.schoolName}"');
      print('     levelName: "${c.levelName}"');
      print('     className: "${c.className}"');
      print('     subjectName: "${c.subjectName}"');
      print('     levelId: ${c.levelId}');
      print('     classId: ${c.classId}');
      print('     subjectId: ${c.subjectId}');
      print('     levelSubjectId: ${c.levelSubjectId}');
    }

    // طباعة المزيد من التفاصيل للفهم
    if (profileState.classes.isNotEmpty) {
      print('🔍 تحليل البيانات الخام لأول Class:');
      // طباعة البيانات الخام من API إذا كانت متوفرة
      // هذا يساعد في فهم ما إذا كانت البيانات تأتي صحيحة من API
    }

    // التحقق من وجود classes
    if (profileState.classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد فصول متاحة للمعلم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
      profileState.classes,
      selectedSchool,
      selectedStage,
      selectedSection,
      selectedSubject,
    );

    print('🏫 TeacherClass المطابق:');
    print('   schoolName: ${matchingClass?.schoolName}');
    print('   levelName: ${matchingClass?.levelName}');
    print('   className: ${matchingClass?.className}');
    print('   subjectName: ${matchingClass?.subjectName}');
    print('   levelId: ${matchingClass?.levelId}');
    print('   classId: ${matchingClass?.classId}');
    print('   subjectId: ${matchingClass?.subjectId}');
    print('   levelSubjectId: ${matchingClass?.levelSubjectId}');

    // التحقق من أن تم العثور على TeacherClass صالح
    if (matchingClass == null ||
        matchingClass.schoolName == null ||
        matchingClass.levelName == null ||
        matchingClass.className == null ||
        matchingClass.subjectName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لم يتم العثور على فصل مطابق للاختيارات التالية:\n'
            'المدرسة: $selectedSchool\n'
            'المرحلة: $selectedStage\n'
            'الشعبة: $selectedSection\n'
            'المادة: $selectedSubject',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    if (matchingClass.levelId == null ||
        matchingClass.classId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: بيانات الفصل غير مكتملة (levelId أو classId)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // استخدام subjectId أو levelSubjectId كـ fallback
    final subjectId = matchingClass.subjectId ?? matchingClass.levelSubjectId;
    print('📚 subjectId المستخدم: $subjectId');
    if (subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: بيانات الفصل غير مكتملة (subjectId)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // جمع الدرجات من controllers
    final List<StudentDailyGrades> studentsDailyGrades = [];
    
    for (final studentId in _gradeControllers.keys) {
      final studentGrades = _gradeControllers[studentId]!;
      final List<DailyGrade> dailyGrades = [];

      for (final gradeTitleId in studentGrades.keys) {
        final controller = studentGrades[gradeTitleId]!;
        final gradeText = controller.text.trim();
        
        if (gradeText.isNotEmpty) {
          final grade = double.tryParse(gradeText) ?? 0.0;
          if (grade > 0) {
            dailyGrades.add(DailyGrade(
              dailyGradeTitleId: gradeTitleId,
              grade: grade,
            ));
          }
        }
      }

      if (dailyGrades.isNotEmpty) {
        // البحث عن studentClassSubjectId من بيانات السيرفر
        final serverStudent = _serverStudents.firstWhere(
          (student) => student.id == studentId,
          orElse: () => Student(id: studentId, fullName: 'غير محدد'),
        );

        studentsDailyGrades.add(StudentDailyGrades(
          studentId: studentId,
          studentClassSubjectId: serverStudent.studentClassSubjectId,  // ✅ إضافة studentClassSubjectId
          date: DateTime.now(),
          dailyGrades: dailyGrades,
        ));
      }
    }

    if (studentsDailyGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد درجات لحفظها'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // إنشاء الطلب
    final request = BulkDailyGradesRequest(
      levelId: matchingClass.levelId!,
      classId: matchingClass.classId!,
      subjectId: subjectId,  // استخدام subjectId المُعدل
      date: DateTime.now(),
      studentsDailyGrades: studentsDailyGrades,
    );

    // إرسال الطلب
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = sl<DailyGradesRepository>();
      final response = await repository.updateBulkDailyGrades(request);

      setState(() {
        _isSaving = false;
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            backgroundColor: const Color(0xFF43A047),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
