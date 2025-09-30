import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../data/models/profile_models.dart';
import '../../../di/injector.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../logic/blocs/exam_export/exam_export_barrel.dart';
import '../../../logic/blocs/exam_schedule/exam_schedule_barrel.dart';
import '../../../logic/blocs/exam_questions/exam_questions_barrel.dart';
import '../../../data/models/exam_export_model.dart';
import '../../../data/repositories/exam_export_repository.dart';
import '../../../data/repositories/exam_schedule_repository.dart';
import '../../../data/repositories/exam_questions_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class ExamQuestionsScreen extends StatefulWidget {
  const ExamQuestionsScreen({super.key});

  @override
  State<ExamQuestionsScreen> createState() => _ExamQuestionsScreenState();
}

class _ExamQuestionsScreenState extends State<ExamQuestionsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();

  // --- selectors state and lists ---
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  late final ProfileBloc _profileBloc;
  late final ExamExportBloc _examExportBloc;
  late final ExamScheduleBloc _examScheduleBloc;
  late final ExamQuestionsBloc _examQuestionsBloc;

  // Helpers to derive dynamic lists from TeacherClass
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
      if ((c.subjectName ?? '').trim().isNotEmpty) {
        set.add(c.subjectName!.trim());
      }
    }
    return set.toList();
  }

  // Removed selectedClass as it's no longer needed
  // Removed class selection as per user request

  // Removed all class options as per user request

  static const List<Map<String, dynamic>> questionTypes = [
    {
      "label": "اختياري",
      "value": "choice",
      "icon": Icons.radio_button_checked,
      "iconColor": Color(0xFF1976D2),
    },
    {
      "label": "صح أو خطأ",
      "value": "truefalse",
      "icon": Icons.check_circle,
      "iconColor": Color(0xFF1976D2),
    },
    {
      "label": "أكمل الفراغ",
      "value": "complete",
      "icon": Icons.edit,
      "iconColor": Color(0xFF1976D2),
    },
    {
      "label": "مقالي",
      "value": "essay",
      "icon": Icons.article,
      "iconColor": Color(0xFF1976D2),
    },
  ];

  // أسئلة من كل نوع
  final Map<String, List<Map<String, dynamic>>> questionsByType = {
    "choice": [],
    "truefalse": [],
    "complete": [],
    "essay": [],
  };

  // عدد الأسئلة لكل نوع
  final Map<String, int> questionCounts = {
    "choice": 0,
    "truefalse": 0,
    "complete": 0,
    "essay": 0,
  };

  // Cache للـ widgets المتكررة
  final Map<String, Widget> _cachedSelectors = {};
  final Map<String, Widget> _cachedQuestionInputs = {};

  @override
  void dispose() {
    _profileBloc.close();
    _examExportBloc.close();
    _examScheduleBloc.close();
    _examQuestionsBloc.close();
    _cachedSelectors.clear();
    _cachedQuestionInputs.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _profileBloc = ProfileBloc(sl<ProfileRepository>())
      ..add(const FetchProfile());
    _examExportBloc = ExamExportBloc(sl<ExamExportRepository>());
    _examScheduleBloc = ExamScheduleBloc(sl<ExamScheduleRepository>());
    _examQuestionsBloc = ExamQuestionsBloc(sl<ExamQuestionsRepository>());
  }

  // دالة لاختيار أي ملف
  Future<void> _pickAnyFile() async {
    try {
      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      // إخفاء مؤشر التحميل
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            selectedFile = file;
            isFileSelected = true;
            questionInputType = 'file';
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم اختيار الملف: ${file.name}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // إخفاء مؤشر التحميل في حالة الخطأ
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // دالة لإلغاء الملف المختار
  void _cancelFile() {
    setState(() {
      selectedFile = null;
      isFileSelected = false;
      questionInputType = null;
    });
  }

  // دالة لإرسال الملف
  void _submitFile() {
    if (selectedFile == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال الملف: ${selectedFile!.name}'),
        backgroundColor: const Color(0xFF43A047),
        duration: const Duration(seconds: 2),
      ),
    );

    // يمكنك إضافة معالجة إضافية للملف هنا
    print('تم إرسال الملف: ${selectedFile!.path}');
    print('اسم الملف: ${selectedFile!.name}');
    print('حجم الملف: ${selectedFile!.size} bytes');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _addQuestion(String type) {
    if (mounted) {
      print('➕ إضافة سؤال جديد من نوع: $type');
      setState(() {
        questionsByType[type]!.add({
          "question": "",
          "options": type == "choice" ? ["", ""] : [],
          "correctOption": type == "choice" ? null : null,
          "trueFalseAnswer": type == "truefalse" ? null : null,
          "completeAnswer": type == "complete" ? "" : null,
          "essayAnswer": type == "essay" ? "" : null,
        });

        // تحديث العداد
        questionCounts[type] = questionsByType[type]!.length;
        // تنظيف الـ cache عند إضافة سؤال جديد
        _cachedQuestionInputs.clear();
      });
      print('✅ تم إضافة السؤال. العدد الحالي: ${questionCounts[type]}');
    }
  }

  void _removeQuestion(String type, int index) {
    if (mounted) {
      setState(() {
        questionsByType[type]!.removeAt(index);
        // تحديث العداد
        questionCounts[type] = questionsByType[type]!.length;
        // تنظيف الـ cache عند حذف سؤال
        _cachedQuestionInputs.clear();
      });
    }
  }

  void _updateQuestion(String type, int index, String field, dynamic value) {
    if (mounted) {
      print('🔄 تحديث السؤال: $type[$index].$field = $value');
      setState(() {
        questionsByType[type]![index][field] = value;
        // تنظيف الـ cache عند التحديث
        _cachedQuestionInputs.clear();
      });
    }
  }

  void _addOption(String type, int questionIndex) {
    if (mounted) {
      print('➕ إضافة اختيار جديد للسؤال: $type[$questionIndex]');
      setState(() {
        questionsByType[type]![questionIndex]["options"].add("");
        // تنظيف الـ cache عند إضافة اختيار جديد
        _cachedQuestionInputs.clear();
      });
    }
  }

  void _removeOption(String type, int questionIndex, int optionIndex) {
    if (mounted) {
      setState(() {
        questionsByType[type]![questionIndex]["options"].removeAt(optionIndex);
        if (questionsByType[type]![questionIndex]["correctOption"] != null &&
            questionsByType[type]![questionIndex]["correctOption"] >=
                questionsByType[type]![questionIndex]["options"].length) {
          questionsByType[type]![questionIndex]["correctOption"] = null;
        }
        // تنظيف الـ cache عند حذف اختيار
        _cachedQuestionInputs.clear();
      });
    }
  }

  void _submit() {
    if (!mounted) return;

    if (selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار المادة'),
            duration: Duration(seconds: 1)),
      );
      return;
    }

    int totalQuestions = 0;
    for (var questions in questionsByType.values) {
      totalQuestions += questions.length;
    }

    if (totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى إضافة أسئلة'), duration: Duration(seconds: 1)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال $totalQuestions سؤال لـ $selectedSubject'),
        backgroundColor: const Color(0xFF43A047),
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  /// دالة تحويل الأسئلة إلى نموذج التصدير
  ExamExportModel _convertToExamExportModel() {
    final List<ExamQuestion> allQuestions = [];
    int questionNumber = 1;

    // تحويل الأسئلة الاختيارية
    for (final questionData in questionsByType['choice']!) {
      if (questionData['question']?.toString().trim().isNotEmpty == true) {
        allQuestions.add(ExamQuestion(
          type: 'choice',
          questionText: questionData['question'].toString(),
          options: List<String>.from(questionData['options'] ?? []),
          correctAnswer: questionData['correctOption']?.toString(),
          questionNumber: questionNumber++,
        ));
      }
    }

    // تحويل أسئلة صح أو خطأ
    for (final questionData in questionsByType['truefalse']!) {
      if (questionData['question']?.toString().trim().isNotEmpty == true) {
        allQuestions.add(ExamQuestion(
          type: 'truefalse',
          questionText: questionData['question'].toString(),
          correctAnswer: questionData['trueFalseAnswer']?.toString(),
          questionNumber: questionNumber++,
        ));
      }
    }

    // تحويل أسئلة أكمل الفراغ
    for (final questionData in questionsByType['complete']!) {
      if (questionData['question']?.toString().trim().isNotEmpty == true) {
        allQuestions.add(ExamQuestion(
          type: 'complete',
          questionText: questionData['question'].toString(),
          correctAnswer: questionData['completeAnswer']?.toString(),
          questionNumber: questionNumber++,
        ));
      }
    }

    // تحويل الأسئلة المقالية
    for (final questionData in questionsByType['essay']!) {
      if (questionData['question']?.toString().trim().isNotEmpty == true) {
        allQuestions.add(ExamQuestion(
          type: 'essay',
          questionText: questionData['question'].toString(),
          correctAnswer: questionData['essayAnswer']?.toString(),
          questionNumber: questionNumber++,
        ));
      }
    }

    return ExamExportModel(
      examTitle: 'امتحان ${selectedSubject ?? ""}',
      schoolName: selectedSchool,
      stageName: selectedStage,
      sectionName: selectedSection,
      subjectName: selectedSubject,
      questions: allQuestions,
      createdAt: DateTime.now(),
    );
  }

  /// دالة تصدير الأسئلة إلى ملف Word
  void _exportToWord() {
    if (!mounted) return;

    // التحقق من وجود أسئلة
    int totalQuestions = 0;
    for (var questions in questionsByType.values) {
      totalQuestions += questions.length;
    }

    if (totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد أسئلة للتصدير'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // تحويل الأسئلة إلى نموذج التصدير
    final examData = _convertToExamExportModel();

    print('📤 بدء تصدير ${examData.totalQuestions} سؤال إلى ملف Word...');

    // إرسال حدث التصدير
    _examExportBloc.add(ExportExamToWordEvent(examData: examData));
  }

  /// إظهار رسالة نجاح التصدير مع خيارات
  void _showExportSuccessDialog(ExamExportResponse response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'تم إنشاء الملف بنجاح',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.message,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (response.fileName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            response.fileName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'ماذا تريد أن تفعل؟',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            actions: [
              // زر فتح الملف
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openFile(response.filePath);
                },
                icon: const Icon(Icons.open_in_new, color: Color(0xFF1976D2)),
                label: const Text(
                  'فتح الملف',
                  style: TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // زر مشاركة الملف
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _shareFile(response.filePath);
                },
                icon: const Icon(Icons.share, color: Color(0xFF4CAF50)),
                label: const Text(
                  'مشاركة',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // زر إغلاق
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// فتح الملف باستخدام التطبيق المناسب
  Future<void> _openFile(String? filePath) async {
    if (filePath == null) return;

    try {
      // استخدام content:// URI بدلاً من file:// لتجنب FileUriExposedException
      final uri = Uri.parse('content://com.android.externalstorage.documents/document/primary:Download/${Uri.encodeComponent(filePath.split('/').last)}');
      
      // محاولة فتح الملف
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // إذا فشل، جرب طريقة أخرى
        final fileUri = Uri.file(filePath);
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('خطأ في فتح الملف: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الملف في مجلد التحميلات\nالمسار: ${filePath.split('/').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'نسخ المسار',
              textColor: Colors.white,
              onPressed: () {
                // يمكن إضافة نسخ المسار للحافظة هنا
              },
            ),
          ),
        );
      }
    }
  }

  /// مشاركة الملف
  Future<void> _shareFile(String? filePath) async {
    if (filePath == null) return;

    try {
      // يمكن استخدام share_plus package للمشاركة
      // لكن هنا سنستخدم حل بسيط
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('مسار الملف: $filePath'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'نسخ',
            textColor: Colors.white,
            onPressed: () {
              // يمكن إضافة نسخ المسار للحافظة هنا
            },
          ),
        ),
      );
    } catch (e) {
      print('خطأ في مشاركة الملف: $e');
    }
  }

  /// دالة إرسال الأسئلة للسيرفر مع تحويلها لملف Word
  void _submitQuestionsToServer() {
    // التحقق من وجود أسئلة
    final allQuestions = <Map<String, dynamic>>[];
    
    // جمع جميع الأسئلة من جميع الأنواع
    questionsByType.forEach((type, questions) {
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        
        Map<String, dynamic> questionData = {
          'type': type,
          'questionIndex': i,
          'questionText': question['question'] ?? '',
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        // إضافة بيانات خاصة بكل نوع سؤال
        switch (type) {
          case 'choice':
            questionData.addAll({
              'options': question['options'] ?? [],
              'correctAnswer': question['correctAnswer'] ?? '',
            });
            break;
          case 'truefalse':
            questionData.addAll({
              'correctAnswer': question['correctAnswer'] ?? '',
            });
            break;
          case 'complete':
            questionData.addAll({
              'correctAnswer': question['correctAnswer'] ?? '',
            });
            break;
          case 'essay':
            questionData.addAll({
              'notes': question['notes'] ?? '',
            });
            break;
        }
        
        allQuestions.add(questionData);
      }
    });
    
    if (allQuestions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا توجد أسئلة لإرسالها'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    print('📤 تحويل ${allQuestions.length} سؤال لملف Word وإرسالها للسيرفر');

    // أولاً: تحويل الأسئلة لملف Word
    final examExportModel = ExamExportModel(
      examTitle: 'امتحان ${selectedSubject ?? 'غير محدد'}',
      schoolName: selectedSchool,
      stageName: selectedStage,
      sectionName: selectedSection,
      subjectName: selectedSubject,
      createdAt: DateTime.now(),
      questions: _convertQuestionsToExportFormat(),
    );

    // إرسال طلب تصدير الأسئلة لملف Word
    _examExportBloc.add(ExportExamToWordEvent(examData: examExportModel));
  }

  /// تحويل الأسئلة إلى تنسيق التصدير
  List<ExamQuestion> _convertQuestionsToExportFormat() {
    final List<ExamQuestion> exportQuestions = [];
    int questionNumber = 1;
    
    questionsByType.forEach((type, questions) {
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        
        switch (type) {
          case 'choice':
            exportQuestions.add(ExamQuestion(
              type: 'choice',
              questionText: question['question'] ?? '',
              options: List<String>.from(question['options'] ?? []),
              correctAnswer: question['correctAnswer'] ?? '',
              questionNumber: questionNumber++,
            ));
            break;
          case 'truefalse':
            exportQuestions.add(ExamQuestion(
              type: 'truefalse',
              questionText: question['question'] ?? '',
              correctAnswer: question['correctAnswer'] ?? '',
              questionNumber: questionNumber++,
            ));
            break;
          case 'complete':
            exportQuestions.add(ExamQuestion(
              type: 'complete',
              questionText: question['question'] ?? '',
              correctAnswer: question['correctAnswer'] ?? '',
              questionNumber: questionNumber++,
            ));
            break;
          case 'essay':
            exportQuestions.add(ExamQuestion(
              type: 'essay',
              questionText: question['question'] ?? '',
              correctAnswer: question['notes'] ?? '', // استخدام notes كإجابة للمقالي
              questionNumber: questionNumber++,
            ));
            break;
        }
      }
    });
    
    return exportQuestions;
  }

  /// دالة جلب جدول الامتحانات عند اختيار المرحلة والشعبة
  void _fetchExamSchedules() {
    print('🔍 _fetchExamSchedules called - selectedStage: $selectedStage, selectedSection: $selectedSection');
    
    if (selectedStage == null || selectedSection == null) {
      print('⚠️ لم يتم اختيار المرحلة أو الشعبة بعد');
      return;
    }

    // البحث عن TeacherClass المطابق للحصول على GUIDs
    final profileState = _profileBloc.state;
    if (profileState is! ProfileLoaded) {
      print('⚠️ بيانات المعلم غير متاحة');
      return;
    }

    final classes = profileState.classes;
    final matchingClass = classes.firstWhere(
      (c) => c.schoolName == selectedSchool &&
             c.levelName == selectedStage &&
             c.className == selectedSection,
      orElse: () => const TeacherClass(
        schoolName: '',
        levelName: '',
        className: '',
        subjectName: '',
        levelId: '',
        classId: '',
        levelSubjectId: '',
      ),
    );

    if (matchingClass.levelId?.isNotEmpty == true && 
        matchingClass.classId?.isNotEmpty == true) {
      
      print('📅 جلب جدول الامتحانات للمرحلة: ${matchingClass.levelId} والشعبة: ${matchingClass.classId}');
      
      _examScheduleBloc.add(FetchClassExamSchedulesEvent(
        levelId: matchingClass.levelId!,
        classId: matchingClass.classId!,
      ));
    } else {
      print('❌ لم يتم العثور على معرفات المرحلة والشعبة');
    }
  }

  // بناء حقول الأسئلة بدون caching لضمان التحديث الفوري
  Widget _buildQuestionInput(String type, int questionIndex) {
    final question = questionsByType[type]![questionIndex];
    
    switch (type) {
      case "choice":
        return _buildChoiceQuestion(question, type, questionIndex);
      case "truefalse":
        return _buildTrueFalseQuestion(question, type, questionIndex);
      case "complete":
        return _buildCompleteQuestion(question, type, questionIndex);
      case "essay":
        return _buildEssayQuestion(question, type, questionIndex);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChoiceQuestion(
      Map<String, dynamic> question, String type, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'نص السؤال',
            labelStyle: TextStyle(
                color: Theme.of(context).textTheme.titleMedium?.color ??
                    const Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          maxLines: 2,
          initialValue: question["question"],
          onChanged: (val) =>
              _updateQuestion(type, questionIndex, "question", val),
          validator: (val) =>
              val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.radio_button_checked,
                    color: Color(0xFF1976D2), size: 20),
                const SizedBox(width: 8),
                Text(
                  'الاختيارات:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.titleMedium?.color ??
                        const Color(0xFF233A5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: question["options"].length,
              itemBuilder: (context, optionIndex) => Container(
                margin: const EdgeInsets.only(
                    bottom: 12, right: 4, left: 4), // Added horizontal margin
                padding: const EdgeInsets.symmetric(
                    horizontal: 4), // Added horizontal padding
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: question["correctOption"] == optionIndex
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: question["correctOption"] == optionIndex
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => _updateQuestion(
                        type, questionIndex, "correctOption", optionIndex),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align items to start
                      children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: question["correctOption"] == optionIndex
                              ? const Color(0xFF4CAF50)
                              : Theme.of(context).cardColor,
                          border: Border.all(
                            color: question["correctOption"] == optionIndex
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFE0E0E0),
                            width: 2,
                          ),
                          boxShadow: question["correctOption"] == optionIndex
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Radio<int>(
                          value: optionIndex,
                          groupValue: question["correctOption"],
                          onChanged: (val) => _updateQuestion(
                              type, questionIndex, "correctOption", val),
                          activeColor: Colors.white,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      // أيقونة صح للإجابة الصحيحة
                      if (question["correctOption"] == optionIndex) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        maxLines: 2, // Allow multiple lines
                        minLines: 1,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'اختيار ${optionIndex + 1}',
                          labelStyle: const TextStyle(color: Color(0xFF607D8B)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12), // Added padding
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF1976D2), width: 2),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                        ),
                        initialValue: question["options"][optionIndex],
                        onChanged: (val) {
                          _updateQuestion(
                              type,
                              questionIndex,
                              "options",
                              List<String>.from(question["options"])
                                ..[optionIndex] = val);
                        },
                        validator: (val) => val == null || val.isEmpty
                            ? 'أدخل نص الاختيار'
                            : null,
                      ),
                    ),
                    if (question["options"].length > 2)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          icon:
                              Icon(Icons.remove_circle, color: Colors.red[400]),
                          onPressed: () =>
                              _removeOption(type, questionIndex, optionIndex),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _addOption(type, questionIndex),
                icon: const Icon(Icons.add_circle_outline,
                    color: Color(0xFF1976D2)),
                label: const Text(
                  'إضافة اختيار',
                  style: TextStyle(
                      color: Color(0xFF1976D2), fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF1976D2), width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrueFalseQuestion(
      Map<String, dynamic> question, String type, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'نص السؤال',
            labelStyle: const TextStyle(color: Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          maxLines: 2,
          initialValue: question["question"],
          onChanged: (val) =>
              _updateQuestion(type, questionIndex, "question", val),
          validator: (val) =>
              val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF1976D2), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'الإجابة:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF233A5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateQuestion(
                        type, questionIndex, "trueFalseAnswer", true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: question["trueFalseAnswer"] == true
                            ? const Color(0xFF4CAF50)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: question["trueFalseAnswer"] == true
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                        boxShadow: question["trueFalseAnswer"] == true
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: RadioListTile<bool>(
                      value: true,
                      groupValue: question["trueFalseAnswer"],
                      onChanged: (val) => _updateQuestion(
                          type, questionIndex, "trueFalseAnswer", val),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'صح',
                            style: TextStyle(
                              color: question["trueFalseAnswer"] == true
                                  ? Colors.white
                                  : const Color(0xFF233A5A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (question["trueFalseAnswer"] == true) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                        activeColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateQuestion(
                        type, questionIndex, "trueFalseAnswer", false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: question["trueFalseAnswer"] == false
                            ? const Color(0xFFFF5722)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: question["trueFalseAnswer"] == false
                              ? const Color(0xFFFF5722)
                              : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                        boxShadow: question["trueFalseAnswer"] == false
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF5722).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: RadioListTile<bool>(
                      value: false,
                      groupValue: question["trueFalseAnswer"],
                      onChanged: (val) => _updateQuestion(
                          type, questionIndex, "trueFalseAnswer", val),
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'خطأ',
                            style: TextStyle(
                              color: question["trueFalseAnswer"] == false
                                  ? Colors.white
                                  : const Color(0xFF233A5A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (question["trueFalseAnswer"] == false) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.cancel,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                        activeColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompleteQuestion(
      Map<String, dynamic> question, String type, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'نص السؤال',
            labelStyle: const TextStyle(color: Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          maxLines: 2,
          initialValue: question["question"],
          onChanged: (val) =>
              _updateQuestion(type, questionIndex, "question", val),
          validator: (val) =>
              val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'الإجابة الصحيحة:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF233A5A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 2,
                ),
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'الإجابة الصحيحة',
                  labelStyle: const TextStyle(color: Color(0xFF4CAF50)),
                  prefixIcon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                initialValue: question["completeAnswer"],
                onChanged: (val) =>
                    _updateQuestion(type, questionIndex, "completeAnswer", val),
                validator: (val) =>
                    val == null || val.isEmpty ? 'أدخل الإجابة' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEssayQuestion(
      Map<String, dynamic> question, String type, int questionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'نص السؤال',
            labelStyle: const TextStyle(color: Color(0xFF233A5A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          maxLines: 3,
          initialValue: question["question"],
          onChanged: (val) =>
              _updateQuestion(type, questionIndex, "question", val),
          validator: (val) =>
              val == null || val.isEmpty ? 'أدخل نص السؤال' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'الإجابة النموذجية (اختياري)',
            labelStyle: const TextStyle(color: Color(0xFF607D8B)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          maxLines: 4,
          initialValue: question["essayAnswer"],
          onChanged: (val) =>
              _updateQuestion(type, questionIndex, "essayAnswer", val),
        ),
      ],
    );
  }

  bool showManualForm = false;
  String? questionInputType; // 'manual' or 'file'

  // متغيرات لإدارة الملف المختار
  PlatformFile? selectedFile;
  bool isFileSelected = false;

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,
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
                        "أسئلة الامتحان",
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
        body: Stack(children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            width: double.infinity,
            height: double.infinity,
          ),
          // تحسين CustomPaint - استخدام RepaintBoundary مع تحسين الأداء
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: const _MeshBackgroundPainter(),
              isComplex: false,
              willChange: false,
            ),
          ),
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(
                  gridColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black),
              isComplex: false,
              willChange: false,
            ),
          ),
          SafeArea(
            child: BlocConsumer<ExamExportBloc, ExamExportState>(
              bloc: _examExportBloc,
              listener: (context, examExportState) {
                // معالجة حالات التصدير
                if (examExportState is ExamExportSuccess) {
                  print('✅ تم إنشاء ملف Word بنجاح: ${examExportState.response.filePath}');
                  
                  // الآن إرسال الملف للسيرفر
                  final examTableId = '03e21825-42f6-49c6-2691-08de0040eb7e'; // مثال - يجب الحصول عليه من السيرفر
                  final wordFile = File(examExportState.response.filePath!);
                  
                  // تجميع بيانات الأسئلة للإرسال
                  final allQuestions = <Map<String, dynamic>>[];
                  questionsByType.forEach((type, questions) {
                    for (int i = 0; i < questions.length; i++) {
                      final question = questions[i];
                      Map<String, dynamic> questionData = {
                        'type': type,
                        'questionIndex': i,
                        'questionText': question['question'] ?? '',
                        'createdAt': DateTime.now().toIso8601String(),
                      };
                      
                      switch (type) {
                        case 'choice':
                          questionData.addAll({
                            'options': question['options'] ?? [],
                            'correctAnswer': question['correctAnswer'] ?? '',
                          });
                          break;
                        case 'truefalse':
                          questionData.addAll({
                            'correctAnswer': question['correctAnswer'] ?? '',
                          });
                          break;
                        case 'complete':
                          questionData.addAll({
                            'correctAnswer': question['correctAnswer'] ?? '',
                          });
                          break;
                        case 'essay':
                          questionData.addAll({
                            'notes': question['notes'] ?? '',
                          });
                          break;
                      }
                      allQuestions.add(questionData);
                    }
                  });
                  
                  print('📤 إرسال ملف Word (${allQuestions.length} سؤال) للسيرفر');
                  
                  // إرسال الملف والبيانات للسيرفر
                  _examQuestionsBloc.add(SubmitExamQuestionsEvent(
                    examTableId: examTableId,
                    questions: allQuestions,
                    examFile: wordFile, // إرسال ملف Word المُنشأ
                  ));
                  
                } else if (examExportState is ExamExportFailure) {
                  // إظهار رسالة فشل في إنشاء الملف
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل في إنشاء ملف Word: ${examExportState.message}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'حسناً',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                }
              },
              builder: (context, examExportState) {
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
                final schoolsList = _buildSchools(classes);
                final stagesList = _buildStages(classes, selectedSchool);
                final sectionsList =
                    _buildSections(classes, selectedSchool, selectedStage);
                final subjectsList = _buildSubjects(
                    classes, selectedSchool, selectedStage, selectedSection);

                return SingleChildScrollView(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- selectors ---
                        // (تظهر دائماً)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: schoolsList.map((school) {
                                final isSelected = selectedSchool == school;
                                return Container(
                                  margin: const EdgeInsets.only(left: 12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: () {
                                        if (mounted) {
                                          setState(() {
                                            selectedSchool = school;
                                            selectedStage = null;
                                            selectedSection = null;
                                            selectedSubject = null;
                                            questionInputType = null;
                                          });
                                        }
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
                        if (selectedSchool != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: stagesList.map((stage) {
                                  final isSelected = selectedStage == stage;
                                  return Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              selectedStage = stage;
                                              selectedSection = null;
                                              selectedSubject = null;
                                              questionInputType = null;
                                            });
                                          }
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
                        if (selectedStage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: sectionsList.map((section) {
                                  final isSelected = selectedSection == section;
                                  return Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              selectedSection = section;
                                              selectedSubject = null;
                                              questionInputType = null;
                                            });
                                            // جلب البيانات من السيرفر (بدون عرضها)
                                            _fetchExamSchedules();
                                          }
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
                        if (selectedSection != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            margin: EdgeInsets.zero,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: subjectsList.map((subject) {
                                  final isSelected = selectedSubject == subject;
                                  return Container(
                                    margin: const EdgeInsets.only(left: 12),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () {
                                          if (mounted) {
                                            setState(() {
                                              selectedSubject = subject;
                                              questionInputType = null;
                                            });
                                          }
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
                        // --- نهاية الاختيارات ---

                        // استماع لحالة جلب البيانات (بدون عرضها)
                        BlocListener<ExamScheduleBloc, ExamScheduleState>(
                          bloc: _examScheduleBloc,
                          listener: (context, examScheduleState) {
                            if (examScheduleState is ExamScheduleError) {
                              // يمكن إضافة معالجة للأخطاء هنا إذا أردت
                              print('❌ خطأ في جلب جدول الامتحانات: ${examScheduleState.message}');
                            } else if (examScheduleState is ExamScheduleLoaded) {
                              // البيانات تم جلبها بنجاح ولكن لا نعرضها
                              print('✅ تم جلب ${examScheduleState.schedules.length} امتحان من السيرفر');
                            }
                          },
                          child: const SizedBox.shrink(), // لا نعرض أي شيء
                        ),

                        // استماع لحالة إرسال الأسئلة
                        BlocListener<ExamQuestionsBloc, ExamQuestionsState>(
                          bloc: _examQuestionsBloc,
                          listener: (context, examQuestionsState) {
                            if (examQuestionsState is ExamQuestionsLoading) {
                              // إظهار مؤشر التحميل
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            } else {
                              // إخفاء مؤشر التحميل
                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }

                              if (examQuestionsState is ExamQuestionsSuccess) {
                                print('✅ ${examQuestionsState.message}');
                                if (examQuestionsState.data != null) {
                                  print('📊 بيانات الاستجابة: ${examQuestionsState.data}');
                                }
                                
                                // إظهار رسالة نجاح بسيطة فقط
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ تم تحويل الأسئلة لملف Word وإرسالها للسيرفر بنجاح'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                    action: SnackBarAction(
                                      label: 'الرئيسية',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      },
                                    ),
                                  ),
                                );

                                // العودة للصفحة الرئيسية بعد 3 ثوانِ
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (mounted) {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  }
                                });
                              } else if (examQuestionsState is ExamQuestionsError) {
                                // إظهار رسالة خطأ
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(examQuestionsState.message),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                                print('❌ ${examQuestionsState.message}');
                              }
                            }
                          },
                          child: const SizedBox.shrink(),
                        ),

                        // بعد اختيار المادة فقط تظهر خيارات نوع الأسئلة
                        if (selectedSubject != null &&
                            questionInputType == null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24.0, horizontal: 24.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white),
                                    label: const Text('إنشاء الأسئلة يدويًا',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                    ),
                                    onPressed: () {
                                      if (mounted) {
                                        setState(() {
                                          questionInputType = 'manual';
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.insert_drive_file,
                                        color: Colors.white),
                                    label: const Text('رفع ملف',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                    ),
                                    onPressed: _pickAnyFile,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // إذا اختار يدوي تظهر واجهة الأسئلة
                        if (questionInputType == 'manual')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              ...questionTypes.map((type) {
                                final typeValue = type['value'] as String;
                                final questions = questionsByType[typeValue]!;
                                final iconColor = type['iconColor'] as Color;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(type['icon'] as IconData,
                                            color: iconColor, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          type['label'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.color ??
                                                const Color(0xFF233A5A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${questions.length} سؤال',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: questions.length,
                                      addAutomaticKeepAlives: false,
                                      addRepaintBoundaries: true,
                                      itemBuilder: (context, questionIndex) =>
                                          Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.question_mark,
                                                  color: iconColor, size: 16),
                                              const SizedBox(width: 8),
                                              Text(
                                                'سؤال ${questionIndex + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.color ??
                                                      const Color(0xFF233A5A),
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.red[400],
                                                    size: 20),
                                                onPressed: () =>
                                                    _removeQuestion(typeValue,
                                                        questionIndex),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildQuestionInput(
                                              typeValue, questionIndex),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 24),
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: iconColor,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            side: BorderSide(
                                                color: iconColor, width: 2),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                        ),
                                        icon: Icon(Icons.add_circle_outline,
                                            color: iconColor),
                                        label: Text(
                                          'إضافة سؤال ${type['label']}',
                                          style: TextStyle(
                                            color: iconColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _addQuestion(typeValue),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              const SizedBox(height: 24),
                              // زر إرسال الأسئلة (مع تحويل لملف Word)
                              Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: examExportState is ExamExportLoading 
                                          ? Colors.grey 
                                          : const Color(0xFF1976D2),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 18),
                                    ),
                                    icon: examExportState is ExamExportLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.send, color: Colors.white, size: 22),
                                    label: Text(
                                      examExportState is ExamExportLoading 
                                          ? 'جاري التحويل والإرسال...' 
                                          : 'تحويل لملف Word وإرسال',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    // تعطيل الزر أثناء التصدير
                                    onPressed: examExportState is ExamExportLoading ? null : _submitQuestionsToServer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // إذا اختار ملف يظهر الملف المختار أو حقل الرفع
                        if (questionInputType == 'file')
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 32.0, horizontal: 12),
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 500),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 32, horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (!isFileSelected) ...[
                                      // حالة عدم اختيار ملف
                                      const Icon(Icons.insert_drive_file,
                                          color: Color(0xFF1976D2), size: 48),
                                      const SizedBox(height: 18),
                                      Text(
                                        'رفع ملف لأسئلة الامتحان',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.color ??
                                                const Color(0xFF233A5A)),
                                      ),
                                      const SizedBox(height: 18),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.upload_file,
                                            color: Colors.white),
                                        label: const Text('اختر ملف',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1976D2),
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 18),
                                        ),
                                        onPressed: _pickAnyFile,
                                      ),
                                    ] else ...[
                                      // حالة اختيار ملف
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE3F2FD),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: const Color(0xFF1976D2),
                                              width: 2),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.insert_drive_file,
                                                color: Color(0xFF1976D2),
                                                size: 48),
                                            const SizedBox(height: 16),
                                            Text(
                                              selectedFile!.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1976D2),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // زر إلغاء
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.cancel,
                                                  color: Colors.white),
                                              label: const Text('إلغاء',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red[400],
                                                foregroundColor: Colors.white,
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                              ),
                                              onPressed: _cancelFile,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // زر اختيار ملف آخر
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(
                                                  Icons.file_upload,
                                                  color: Colors.white),
                                              label: const Text('ملف آخر',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFFF9800),
                                                foregroundColor: Colors.white,
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                              ),
                                              onPressed: _pickAnyFile,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // زر إرسال
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.send,
                                                  color: Colors.white),
                                              label: const Text('إرسال',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF4CAF50),
                                                foregroundColor: Colors.white,
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                              ),
                                              onPressed: _submitFile,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ));
                  }, // إغلاق ProfileBloc BlocBuilder
                );
              }, // إغلاق ExamExportBloc BlocConsumer
            ),
          ),
        ]),
      ),
    );
  }
}

// تحسين CustomPaint مع const constructors
class _MeshBackgroundPainter extends CustomPainter {
  const _MeshBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFB0BEC5).withAlpha(33)
      ..strokeWidth = 1;
    final paintDot = Paint()
      ..color = const Color(0xFF3B5998).withAlpha(25)
      ..style = PaintingStyle.fill;

    // تحسين الحلقات
    for (double y = 40; y < size.height; y += 120) {
      for (double x = 0; x < size.width; x += 180) {
        canvas.drawLine(Offset(x, y), Offset(x + 120, y + 40), paintLine);
        canvas.drawLine(Offset(x + 60, y + 80), Offset(x + 180, y), paintLine);
      }
    }

    for (double y = 30; y < size.height; y += 100) {
      for (double x = 20; x < size.width; x += 140) {
        canvas.drawCircle(Offset(x, y), 3, paintDot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  final Color gridColor;

  const _GridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withAlpha(16)
      ..strokeWidth = 1;

    const step = 40.0;

    // تحسين رسم الخطوط
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
