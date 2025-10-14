import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/assignments/assignment_barrel.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/repositories/assignment_repository.dart';
import '../../../utils/teacher_class_matcher.dart';
import '../../../utils/server_data_mixin.dart';
import '../../../logic/blocs/base/base_state.dart';
import '../../../di/injector.dart';
import '../../../data/repositories/profile_repository.dart';
import '../home/home_screen.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> with ServerDataMixin<AssignmentsScreen> {
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  late final ProfileBloc _profileBloc;
  late final AssignmentBloc _assignmentBloc;

  // القوائم سيتم بناؤها من بيانات الـ BLoC
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

  // حقول الواجب الجديد
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  DateTime? _selectedDeadline;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _profileBloc = ProfileBloc(sl<ProfileRepository>())..add(const FetchProfile());
    _assignmentBloc = AssignmentBloc(sl<AssignmentRepository>());
  }

  @override
  Future<void> loadServerData() async {
    // جلب البيانات من السيرفر عند الدخول للشاشة
    _profileBloc.add(const FetchProfile());
  }

  Future<void> _selectDeadline() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _submitAssignment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedSchool == null || selectedStage == null || selectedSection == null || selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار جميع الحقول المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار موعد التسليم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find matching TeacherClass to get GUIDs
    final profileState = _profileBloc.state;
    if (profileState is! ProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ في تحميل بيانات المعلم'),
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

    if (matchingClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على الفصل المطابق'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = CreateAssignmentRequest(
      levelSubjectId: matchingClass.levelSubjectId ?? '',
      levelId: matchingClass.levelId ?? '',
      classId: matchingClass.classId ?? '',
      title: _titleController.text.trim(),
      deadline: _selectedDeadline!.toIso8601String(),
      maxGrade: 0,
      contentType: 'text',
      content: _contentController.text.trim(),
    );

    _assignmentBloc.add(CreateAssignment(request));
  }

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedDeadline = null;
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
                        "تحديد الواجبات",
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
        body: BlocConsumer<AssignmentBloc, AssignmentState>(
          bloc: _assignmentBloc,
          listener: (context, assignmentState) {
            if (assignmentState is AssignmentCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إنشاء الواجب بنجاح'),
                  backgroundColor: Colors.green,
                ),
              );
              _clearForm();
              // Navigate back after success
              Future.delayed(const Duration(seconds: 1), () {
                Navigator.of(context).pop();
              });
            } else if (assignmentState is AssignmentCreateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('خطأ: ${assignmentState.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, assignmentState) {
            return BlocBuilder<ProfileBloc, ProfileState>(
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
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اختيارات المدرسة والمرحلة والشعبة
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, right: 8, left: 8),
                    child: buildHorizontalSelector(
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
                  ),
                  if (selectedSchool != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8.0, right: 8, left: 8),
                      child: buildHorizontalSelector(
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
                    ),
                  if (selectedStage != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8.0, right: 8, left: 8),
                      child: buildHorizontalSelector(
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
                    ),
                  if (selectedSection != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 8.0, right: 8, left: 8),
                      child: buildHorizontalSelector(
                        items: subjects,
                        selected: selectedSubject,
                        onSelect: (val) {
                          setState(() {
                            selectedSubject = val;
                          });
                        },
                        label: 'المادة',
                      ),
                    ),
                  if (selectedSubject != null) ...[
                    const SizedBox(height: 12),
                    // رأس النموذج
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment_add,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'إنشاء واجب جديد',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // النموذج
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // عنوان الواجب
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: TextFormField(
                                controller: _titleController,
                                keyboardType: TextInputType.text,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color,
                                    ),
                                decoration: InputDecoration(
                                  labelText: 'عنوان الواجب *',
                                      labelStyle: TextStyle(
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.color ??
                                              const Color(0xFF233A5A)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE0E0E0)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFF1976D2), width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).cardColor,
                                  prefixIcon: const Icon(Icons.title,
                                      color: Color(0xFF1976D2)),
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'أدخل عنوان الواجب';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            // موعد التسليم
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: _selectDeadline,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE0E0E0)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(context).cardColor,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule, color: Color(0xFF1976D2)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedDeadline == null
                                              ? 'اختر موعد التسليم *'
                                              : 'موعد التسليم: ${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year} - ${_selectedDeadline!.hour}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: _selectedDeadline == null
                                                ? Colors.grey
                                                : Theme.of(context).textTheme.bodyMedium?.color,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // محتوى الواجب
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: TextFormField(
                                controller: _contentController,
                                maxLines: 4,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'محتوى الواجب *',
                                  labelStyle: TextStyle(
                                      color: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.color ??
                                          const Color(0xFF233A5A)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF1976D2), width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context).cardColor,
                                  prefixIcon: const Icon(Icons.description,
                                      color: Color(0xFF1976D2)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'أدخل محتوى الواجب';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            // زر إرسال الواجب
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: assignmentState is AssignmentCreating ? null : _submitAssignment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                icon: assignmentState is AssignmentCreating 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: Text(
                                  assignmentState is AssignmentCreating ? 'جاري الإرسال...' : 'إرسال الواجب',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // رسالة عند عدم اختيار المادة
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'اختر المدرسة والمرحلة والشعبة والمادة لإنشاء واجب',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ));
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _profileBloc.close();
    _assignmentBloc.close();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
