import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notika_teacher/data/models/grade_components.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../data/models/profile_models.dart';
import '../../../di/injector.dart';
import '../../../data/repositories/profile_repository.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  String currentSemester = 'الثاني';
  String gradeType = 'يومية'; // 'يومية' or 'فصلية'
  late final ProfileBloc _profileBloc;

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
      if ((c.subjectName ?? '').trim().isNotEmpty)
        set.add(c.subjectName!.trim());
    }
    return set.toList();
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
    _profileBloc = ProfileBloc(sl<ProfileRepository>())
      ..add(const FetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final gradeComponents = context.watch<GradeComponents>().components;

    // Initialize student data with current components
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStudentData(gradeComponents);
    });
    return Directionality(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 8),
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
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          onTap: () {
                                            setState(() {
                                              selectedSchool = school;
                                              selectedStage = null;
                                              selectedSection = null;
                                              selectedSubject = null;
                                            });
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
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 8),
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
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            onTap: () {
                                              setState(() {
                                                selectedStage = stage;
                                                selectedSection = null;
                                                selectedSubject = null;
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                gradient: isSelected
                                                    ? const LinearGradient(
                                                        colors: [
                                                          Color(0xFF1976D2),
                                                          Color(0xFF64B5F6)
                                                        ],
                                                        begin: Alignment
                                                            .centerRight,
                                                        end: Alignment
                                                            .centerLeft,
                                                      )
                                                    : null,
                                                color: isSelected
                                                    ? null
                                                    : Theme.of(context)
                                                        .cardColor,
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
                                                stage,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Theme.of(context)
                                                              .textTheme
                                                              .titleMedium
                                                              ?.color ??
                                                          const Color(
                                                              0xFF233A5A),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                textDirection:
                                                    TextDirection.rtl,
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
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 8),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: sections.map((section) {
                                      final isSelected =
                                          selectedSection == section;
                                      return Container(
                                        margin: const EdgeInsets.only(left: 12),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            onTap: () {
                                              setState(() {
                                                selectedSection = section;
                                                selectedSubject = null;
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                gradient: isSelected
                                                    ? const LinearGradient(
                                                        colors: [
                                                          Color(0xFF1976D2),
                                                          Color(0xFF64B5F6)
                                                        ],
                                                        begin: Alignment
                                                            .centerRight,
                                                        end: Alignment
                                                            .centerLeft,
                                                      )
                                                    : null,
                                                color: isSelected
                                                    ? null
                                                    : Theme.of(context)
                                                        .cardColor,
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
                                                section,
                                                style: TextStyle(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Theme.of(context)
                                                              .textTheme
                                                              .titleMedium
                                                              ?.color ??
                                                          const Color(
                                                              0xFF233A5A),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                textDirection:
                                                    TextDirection.rtl,
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
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: subjects.map((subject) {
                                          final isSelected =
                                              selectedSubject == subject;
                                          return Container(
                                            margin:
                                                const EdgeInsets.only(left: 12),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                onTap: () {
                                                  setState(() {
                                                    selectedSubject = subject;
                                                  });
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                  decoration: BoxDecoration(
                                                    gradient: isSelected
                                                        ? const LinearGradient(
                                                            colors: [
                                                              Color(0xFF1976D2),
                                                              Color(0xFF64B5F6)
                                                            ],
                                                            begin: Alignment
                                                                .centerRight,
                                                            end: Alignment
                                                                .centerLeft,
                                                          )
                                                        : null,
                                                    color: isSelected
                                                        ? null
                                                        : Theme.of(context)
                                                            .cardColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
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
                                                              const Color(
                                                                  0xFF233A5A),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                    textDirection:
                                                        TextDirection.rtl,
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
                                            child:
                                                _buildGradeTypeButton('يومية'),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child:
                                                _buildGradeTypeButton('فصلية'),
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
                                child: Row(
                                  children: [
                                    // الفصل الأول
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => currentSemester = 'الأول'),
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
                                                    begin:
                                                        Alignment.centerRight,
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
                                            boxShadow: currentSemester ==
                                                    'الأول'
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withOpacity(0.2),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 4),
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
                                            gradient: currentSemester ==
                                                    'الثاني'
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
                                            color: currentSemester == 'الثاني'
                                                ? null
                                                : Colors.grey[200],
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                              left: Radius.circular(16),
                                              right: Radius.zero,
                                            ),
                                            boxShadow: currentSemester ==
                                                    'الثاني'
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.blue
                                                          .withOpacity(0.2),
                                                      blurRadius: 10,
                                                      offset:
                                                          const Offset(0, 4),
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
                                ),
                              ),
                            // جدول الطلاب (يختلف حسب نوع الدرجات)
                            if (selectedSubject != null) ...[
                              if (gradeType == 'فصلية')
                                _buildTermGradesTable()
                              else
                                Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    // رأس الجدول
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Row(
                                        children: [
                                          // Student Name Column
                                          const Expanded(
                                            flex: 2,
                                            child: Text(
                                              'اسم الطالب',
                                              style: TextStyle(
                                                color: Color(0xFF1976D2),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.center,
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ),
                                          // Fixed Absence Column
                                          const Expanded(
                                            child: Text(
                                              'إجمالي الغياب',
                                              style: TextStyle(
                                                color: Color(0xFF1976D2),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                              textDirection: TextDirection.rtl,
                                            ),
                                          ),
                                          // Dynamic Components (excluding absence)
                                          ...gradeComponents
                                              .where(
                                                  (c) => c != 'إجمالي الغياب')
                                              .map((component) => Expanded(
                                                    child: Text(
                                                      component,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF1976D2),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      textDirection:
                                                          TextDirection.rtl,
                                                    ),
                                                  )),
                                        ],
                                      ),
                                    ),
                                    const Divider(thickness: 1.2),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          (sectionStudents[selectedSection] ?? [])
                                              .length,
                                      itemBuilder: (context, index) {
                                        final student =
                                            (sectionStudents[selectedSection] ?? [])
                                                [index];
                                        // رقم غياب عشوائي
                                        // Initialize student data if not already done
                                        if (student.length <= 1) {
                                          // Only has name and absence
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
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4),
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
                                                      onChanged:
                                                          currentSemester ==
                                                                  'الثاني'
                                                              ? (value) {
                                                                  setState(() {
                                                                    student[component] =
                                                                        value;
                                                                  });
                                                                }
                                                              : null,
                                                      readOnly:
                                                          currentSemester !=
                                                              'الثاني',
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    // Show save button only for second semester
                                    if (currentSemester == 'الثاني')
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                              )
                          ]),
                    ),
                  );
                })));
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  // بناء زر نوع الدرجات
  Widget _buildGradeTypeButton(String type) {
    final isSelected = gradeType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            gradeType = type;
          });
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
            rows: selectedSection != null
                ? List<DataRow>.generate(
                    (sectionStudents[selectedSection] ?? []).length,
                    (index) {
                      final student =
                          (sectionStudents[selectedSection] ?? [])[index];

                      student['firstTermAvg'] = student['firstTermAvg'] ?? '0';
                      student['midtermExam'] = student['midtermExam'] ?? '0';
                      student['secondTermAvg'] =
                          student['secondTermAvg'] ?? '0';
                      student['annualAvg'] = _calculateAnnualAverage(student);

                      return DataRow(
                        cells: [
                          // Student Name
                          DataCell(
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              alignment: Alignment.centerRight,
                              child: Text(
                                student['name'] ?? '',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          // First Term Average
                          DataCell(
                            TextFormField(
                              initialValue:
                                  student['firstTermAvg']?.toString() ?? '0',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                setState(() {
                                  student['firstTermAvg'] = value;
                                  student['annualAvg'] =
                                      _calculateAnnualAverage(student);
                                });
                              },
                            ),
                          ),
                          // Midterm Exam (read-only)
                          DataCell(
                            TextFormField(
                              initialValue:
                                  student['midtermExam']?.toString() ?? '0',
                              enabled: false,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Second Term Average
                          DataCell(
                            TextFormField(
                              initialValue:
                                  student['secondTermAvg']?.toString() ?? '0',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              onChanged: (value) {
                                setState(() {
                                  student['secondTermAvg'] = value;
                                  student['annualAvg'] =
                                      _calculateAnnualAverage(student);
                                });
                              },
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
                                student['annualAvg']?.toString() ?? '0.00',
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
        // زر الحفظ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveGrades,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'حفظ الدرجات الفصلية',
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
  }

  void _saveGrades() {
    // Here you can add logic to save the grades
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ ${gradeType == 'يومية' ? 'الدرجات' : 'الدرجات الفصلية'} بنجاح',
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

    // Return to the previous screen after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }
}
