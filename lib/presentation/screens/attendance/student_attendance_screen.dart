import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/attendance/attendance_bloc.dart';
import '../../../logic/blocs/attendance/attendance_event.dart';
import '../../../logic/blocs/attendance/attendance_state.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/models/attendance_model.dart';
import '../../../di/injector.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/attendance_repository.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  bool selectAll = false;
  late final ProfileBloc _profileBloc;
  late final AttendanceBloc _attendanceBloc;

  // Dynamic students state
  List<StudentAttendance> students = [];
  DateTime selectedDate = DateTime.now();
  int classOrder = 1;

  // سيتم اشتقاق القوائم التالية من بيانات الـ BLoC بدلاً من البيانات الثابتة
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

  List<String> _buildSections(List<TeacherClass> classes, String? school, String? stage) {
    if (school == null || stage == null) return const [];
    final set = <String>{};
    for (final c in classes.where((e) => e.schoolName == school && e.levelName == stage)) {
      if ((c.className ?? '').trim().isNotEmpty) set.add(c.className!.trim());
    }
    return set.toList();
  }

  List<String> _buildSubjects(List<TeacherClass> classes, String? school, String? stage, String? section) {
    if (school == null || stage == null || section == null) return const [];
    final set = <String>{};
    for (final c in classes.where((e) => e.schoolName == school && e.levelName == stage && e.className == section)) {
      if ((c.subjectName ?? '').trim().isNotEmpty) set.add(c.subjectName!.trim());
    }
    return set.toList();
  }

  void _fetchStudentsForSelection(List<TeacherClass> classes) {
    // Need levelId and classId from current selection
    if (selectedSchool == null || selectedStage == null || selectedSection == null || selectedSubject == null) return;
    
    final match = classes.firstWhere(
      (c) => c.schoolName == selectedSchool && c.levelName == selectedStage && c.className == selectedSection && c.subjectName == selectedSubject,
      orElse: () => const TeacherClass(),
    );
    
    final subjectId = match.levelSubjectId ?? match.subjectId ?? '';
    final levelId = match.levelId ?? '';
    final classId = match.classId ?? '';
    
    if (subjectId.isEmpty || levelId.isEmpty || classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد بيانات الفصل')),
      );
      return;
    }

    // Load students using BLoC
    _attendanceBloc.add(LoadStudentsEvent(
      subjectId: subjectId,
      levelId: levelId,
      classId: classId,
    ));
  }

  void _onAttendanceChanged(String studentId, String status) {
    _attendanceBloc.add(UpdateStudentAttendanceEvent(
      studentId: studentId,
      status: status,
    ));
  }

  @override
  void initState() {
    super.initState();
    _profileBloc = ProfileBloc(sl<ProfileRepository>())..add(const FetchProfile());
    _attendanceBloc = AttendanceBloc(sl<AttendanceRepository>());
  }

  @override
  void dispose() {
    _profileBloc.close();
    _attendanceBloc.close();
    super.dispose();
  }

  void _submitAttendance() {
    if (selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null ||
        selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار المدرسة والمرحلة والشعبة والمادة أولاً')),
      );
      return;
    }
    
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد طلاب لتسجيل الحضور')),
      );
      return;
    }
    
    // Get profile state to access classes
    final profileState = _profileBloc.state;
    if (profileState is! ProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في تحميل بيانات الملف الشخصي')),
      );
      return;
    }
    
    try {
      // Create attendance submission using BLoC helper method
      final submission = AttendanceBloc.createSubmissionFromFormData(
        classes: profileState.classes,
        selectedSchool: selectedSchool!,
        selectedStage: selectedStage!,
        selectedSection: selectedSection!,
        selectedSubject: selectedSubject!,
        students: students,
        classOrder: classOrder,
        date: selectedDate,
      );
      
      // Submit via BLoC
      _attendanceBloc.add(SendAttendanceEvent(
        students: submission.students,
        subjectId: submission.subjectId,
        levelId: submission.levelId,
        classId: submission.classId,
        classOrder: submission.classOrder,
        date: submission.date,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إعداد البيانات: $e')),
      );
    }
  }

  Widget buildHorizontalSelector({
    required List<String> items,
    required String? selected,
    required Function(String) onSelect,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final isSelected = selected == item;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => onSelect(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: isSelected ? null : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        item,
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
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "حضور الطلاب",
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
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            }

            final loaded = state as ProfileLoaded;
            final classes = loaded.classes;
            final schools = _buildSchools(classes);
            final stages = _buildStages(classes, selectedSchool);
            final sections = _buildSections(classes, selectedSchool, selectedStage);
            final subjects = _buildSubjects(classes, selectedSchool, selectedStage, selectedSection);

            return BlocConsumer<AttendanceBloc, AttendanceState>(
              bloc: _attendanceBloc,
              listener: (context, attendanceState) {
                if (attendanceState is AttendanceSubmitted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(attendanceState.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Navigate back after successful submission
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.of(context).pop();
                  });
                } else if (attendanceState is AttendanceSubmissionFailed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(attendanceState.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (attendanceState is StudentsLoaded) {
                  setState(() {
                    students = attendanceState.students;
                    selectAll = false;
                  });
                } else if (attendanceState is StudentAttendanceUpdated) {
                  setState(() {
                    students = attendanceState.students;
                  });
                } else if (attendanceState is StudentsLoadingFailed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(attendanceState.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, attendanceState) {
                final isSubmitting = attendanceState is AttendanceSubmitting;
                final isLoadingStudents = attendanceState is AttendanceLoading;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    buildHorizontalSelector(
                      items: schools,
                      selected: selectedSchool,
                      onSelect: (val) {
                        setState(() {
                          selectedSchool = val;
                          selectedStage = null;
                          selectedSection = null;
                          selectedSubject = null;
                          students = [];
                        });
                      },
                      label: 'المدرسة',
                    ),
                    const SizedBox(height: 12),
                    if (selectedSchool != null)
                      buildHorizontalSelector(
                        items: stages,
                        selected: selectedStage,
                        onSelect: (val) {
                          setState(() {
                            selectedStage = val;
                            selectedSection = null;
                            selectedSubject = null;
                            students = [];
                          });
                        },
                        label: 'المرحلة',
                      ),
                    if (selectedSchool != null) const SizedBox(height: 12),
                    if (selectedStage != null)
                      buildHorizontalSelector(
                        items: sections,
                        selected: selectedSection,
                        onSelect: (val) {
                          setState(() {
                            selectedSection = val;
                            selectedSubject = null;
                            students = [];
                          });
                        },
                        label: 'الشعبة',
                      ),
                    if (selectedStage != null) const SizedBox(height: 12),
                    if (selectedSection != null)
                      buildHorizontalSelector(
                        items: subjects,
                        selected: selectedSubject,
                        onSelect: (val) {
                          setState(() {
                            selectedSubject = val;
                          });
                          _fetchStudentsForSelection(classes);
                        },
                        label: 'المادة',
                      ),
                    if (selectedSection != null) ...[
                  const SizedBox(height: 16),
                  // اختيار الكل
                  Row(
                    children: [
                      Checkbox(
                        value: selectAll,
                        onChanged: (val) {
                          if (val == true) {
                            setState(() {
                              selectAll = true;
                              for (var i = 0; i < students.length; i++) {
                                _onAttendanceChanged(students[i].studentId, 'absent');
                              }
                            });
                          } else {
                            setState(() {
                              selectAll = false;
                            });
                          }
                        },
                      ),
                      const Text('اختيار الكل كـ غياب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                
                // Date and Class Order Selection
                if (selectedSubject != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ الحضور', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 7)),
                                );
                                if (date != null) {
                                  setState(() {
                                    selectedDate = date;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 8),
                                    Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('رقم الدرس', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              value: classOrder,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: List.generate(8, (index) => index + 1)
                                  .map((order) => DropdownMenuItem(
                                        value: order,
                                        child: Text('الدرس $order'),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    classOrder = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (isLoadingStudents) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ] else if (students.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        selectedSubject == null ? 'اختر المادة لعرض الطلاب' : 'لا يوجد طلاب لهذه المادة',
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
                
                if (students.isNotEmpty) ...[
                  ...students.map((student) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF1976D2),
                              child: Text(student.name.isNotEmpty ? student.name[0] : 'ط',
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF233A5A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: DropdownButton<String>(
                                value: student.status,
                                isDense: true,
                                underline: SizedBox(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: student.status == 'present'
                                      ? const Color(0xFF43A047)
                                      : student.status == 'absent'
                                          ? const Color(0xFFE53935)
                                          : const Color(0xFFFB8C00),
                                  fontSize: 16,
                                ),
                                icon: const Icon(Icons.arrow_drop_down, size: 22),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'present',
                                    child: Text('حاضر', style: TextStyle(color: Color(0xFF43A047), fontWeight: FontWeight.bold)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'absent',
                                    child: Text('غائب', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'excused',
                                    child: Text('مجاز', style: TextStyle(color: Color(0xFFFB8C00), fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    _onAttendanceChanged(student.studentId, value);
                                    // إذا تم تغيير حالة أي طالب يدويًا، ألغِ اختيار الكل
                                    if (selectAll && value != 'absent') {
                                      setState(() {
                                        selectAll = false;
                                      });
                                    }
                                  }
                                },
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      )),
                  ],
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      isSubmitting ? 'جاري الإرسال...' : 'إرسال الحضور',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    onPressed: isSubmitting ? null : _submitAttendance,
                  ),
                )]]
                      ,
                    ),
                  ),
                );
}
                      );
                    },
                  ),
                ),
              );
            }
          }
