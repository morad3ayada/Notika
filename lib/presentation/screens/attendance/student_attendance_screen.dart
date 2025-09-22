import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/profile/profile_bloc.dart';
import '../../../bloc/profile/profile_event.dart';
import '../../../bloc/profile/profile_state.dart';
import '../../../data/models/profile_models.dart';
import '../../../di/injector.dart';
import '../../../data/repositories/profile_repository.dart';

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

  // بيانات الطلاب (مثال ثابت)
  final List<Map<String, dynamic>> students = [
    {'name': 'أحمد محمد علي', 'id': '001', 'status': 'present'},
    {'name': 'سارة أحمد حسن', 'id': '002', 'status': 'present'},
    {'name': 'محمد عبد الله', 'id': '003', 'status': 'present'},
    {'name': 'فاطمة محمود', 'id': '004', 'status': 'present'},
    {'name': 'علي حسن محمد', 'id': '005', 'status': 'present'},
  ];

  void _onAttendanceChanged(String studentId, String status) {
    setState(() {
      for (var student in students) {
        if (student['id'] == studentId) {
          student['status'] = status;
          break;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _profileBloc = ProfileBloc(sl<ProfileRepository>())..add(const FetchProfile());
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  void _submitAttendance() {
    if (selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار المدرسة والمرحلة والشعبة أولاً'),
            duration: Duration(seconds: 1)),
      );
      return;
    }
    final presentCount = students.where((s) => s['status'] == 'present').length;
    final absentCount = students.where((s) => s['status'] == 'absent').length;
    final excusedCount = students.where((s) => s['status'] == 'excused').length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'تم حفظ الحضور: حاضر $presentCount، غائب $absentCount، مجاز $excusedCount'),
        backgroundColor: const Color(0xFF43A047),
        duration: const Duration(seconds: 1),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
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

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                        },
                        label: 'المادة',
                      ),
                    if (selectedSubject != null) ...[
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
                              for (var student in students) {
                                student['status'] = 'absent';
                              }
                            });
                          } else {
                            setState(() {
                              selectAll = false;
                              // لا نغير حالة الطلاب عند إلغاء التحديد
                            });
                          }
                        },
                      ),
                      const Text('اختيار الكل كـ غياب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
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
                              child: Text(student['name'][0],
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    student['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF233A5A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'ID: ${student['id']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: DropdownButton<String>(
                                value: student['status'],
                                isDense: true,
                                underline: SizedBox(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: student['status'] == 'present'
                                      ? Color(0xFF43A047)
                                      : student['status'] == 'absent'
                                          ? Color(0xFFE53935)
                                          : Color(0xFFFB8C00),
                                  fontSize: 16,
                                ),
                                icon: const Icon(Icons.arrow_drop_down, size: 22),
                                items: [
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
                                  if (value != null) _onAttendanceChanged(student['id'], value);
                                  // إذا تم تغيير حالة أي طالب يدويًا، ألغِ اختيار الكل
                                  if (selectAll && value != 'absent') {
                                    setState(() {
                                      selectAll = false;
                                    });
                                  }
                                },
                                // احذف itemHeight نهائياً
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      )),
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
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text(
                        'إرسال الحضور',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      onPressed: _submitAttendance,
                    ),
                  ),
                ],
                    if (selectedSubject == null)
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'اختر المادة لعرض الطلاب',
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 18,
                                fontWeight: FontWeight.w500),
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
    );
  }
}
