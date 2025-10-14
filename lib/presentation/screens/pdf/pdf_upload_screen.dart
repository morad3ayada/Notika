import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../logic/blocs/file_classification/file_classification_bloc.dart';
import '../../../logic/blocs/file_classification/file_classification_event.dart';
import '../../../logic/blocs/file_classification/file_classification_state.dart';
import '../../../data/models/profile_models.dart';
import '../../../data/models/file_classification_model.dart';
import '../../../di/injector.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/file_classification_repository.dart';
import '../../../data/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../utils/teacher_class_matcher.dart';

class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  State<PdfUploadScreen> createState() => _PdfUploadScreenState();
}

class _DeleteConfirmationDialog extends StatefulWidget {
  final String unitName;
  final Function(bool) onConfirm;

  const _DeleteConfirmationDialog({
    super.key,
    required this.unitName,
    required this.onConfirm,
  });

  @override
  _DeleteConfirmationDialogState createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isConfirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تأكيد حذف الوحدة/الفصل',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF233A5A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لحذف "${widget.unitName}" يرجى كتابة الاسم للتأكيد',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _isConfirmed = value == widget.unitName;
                });
              },
              decoration: InputDecoration(
                hintText: 'اكتب "${widget.unitName}"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1976D2)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Color(0xFF233A5A),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConfirmed
                        ? () {
                            widget.onConfirm(true);
                            Navigator.pop(context, true);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'تأكيد الحذف',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PdfUploadScreenState extends State<PdfUploadScreen> {
  File? selectedFile;
  File? selectedAudio;
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  String? selectedUnit; // الفصل/الوحدة المختارة
  final List<String> units = []; // قائمة الفصول/الوحدات التي ينشئها المستخدم
  late final ProfileBloc _profileBloc;
  late final FileClassificationBloc _fileClassificationBloc;

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
      if ((c.subjectName ?? '').trim().isNotEmpty)
        set.add(c.subjectName!.trim());
    }
    return set.toList();
  }

  final TextEditingController detailsController = TextEditingController();

  // File Classification Controllers
  final TextEditingController _fileClassificationNameController =
      TextEditingController();

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    _profileBloc = ProfileBloc(sl<ProfileRepository>())
      ..add(const FetchProfile());
    _fileClassificationBloc =
        FileClassificationBloc(sl<FileClassificationRepository>());
  }

  @override
  void dispose() {
    _profileBloc.close();
    _fileClassificationBloc.close();
    _recorder?.closeRecorder();
    _fileClassificationNameController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedAudio = File(result.files.single.path!);
      });
    }
  }

  Future<void> startRecording() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب السماح باستخدام الميكروفون')),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recording_${Random().nextInt(100000)}.aac';
    await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
    setState(() {
      _isRecording = true;
      _audioPath = null;
    });
  }

  Future<void> stopRecording() async {
    final path = await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
      _audioPath = path;
    });
  }

  Future<void> submit() async {
    // التحقق من الحقول المطلوبة
    if (selectedFile == null ||
        selectedSchool == null ||
        selectedStage == null ||
        selectedSection == null ||
        selectedSubject == null ||
        selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار جميع الحقول بما في ذلك الوحدة ورفع ملف')),
      );
      return;
    }

    print('════════════════════════════════════════════');
    print('📤 بدء عملية رفع الملف');
    print('════════════════════════════════════════════');

    try {
      // الحصول على البيانات من ProfileBloc
      final profileState = _profileBloc.state;
      if (profileState is! ProfileLoaded) {
        throw Exception('لم يتم تحميل بيانات المعلم');
      }

      final classes = profileState.classes;

      // العثور على الفصل المطابق
      final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
        classes,
        selectedSchool!,
        selectedStage!,
        selectedSection!,
        selectedSubject!,
      );

      if (matchingClass == null) {
        throw Exception('لم يتم العثور على الفصل المطابق');
      }

      // الحصول على FileClassificationId من BLoC
      final fileClassState = _fileClassificationBloc.state;
      String? fileClassificationId;
      
      if (fileClassState is FileClassificationsLoaded) {
        final selectedFileClass = fileClassState.fileClassifications
            .firstWhere(
              (fc) => fc.name == selectedUnit,
              orElse: () => throw Exception('لم يتم العثور على الوحدة المختارة'),
            );
        fileClassificationId = selectedFileClass.id;
      } else {
        throw Exception('لم يتم تحميل قائمة الوحدات');
      }

      if (fileClassificationId == null || fileClassificationId.isEmpty) {
        throw Exception('معرف الوحدة غير صالح');
      }

      // الحصول على معلومات الملف
      final fileName = selectedFile!.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final title = detailsController.text.trim().isNotEmpty 
          ? detailsController.text.trim() 
          : fileName.replaceAll('.$fileExtension', '');

      print('📋 بيانات الإرسال:');
      print('   - المدرسة: $selectedSchool');
      print('   - المرحلة: $selectedStage');
      print('   - الشعبة: $selectedSection');
      print('   - المادة: $selectedSubject');
      print('   - الوحدة: $selectedUnit');
      print('   - LevelSubjectId: ${matchingClass.levelSubjectId}');
      print('   - LevelId: ${matchingClass.levelId}');
      print('   - ClassId: ${matchingClass.classId ?? "غير محدد"}');
      print('   - FileClassificationId: $fileClassificationId');
      print('   - Title: $title');
      print('   - FileType: $fileExtension');
      print('   - اسم الملف: $fileName');
      print('   - حجم الملف: ${selectedFile!.lengthSync()} bytes');
      print('   - Note: ${detailsController.text.trim()}');

      // الحصول على التوكن
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('لم يتم العثور على التوكن');
      }

      print('🔑 التوكن: ${token.substring(0, 20)}...');

      // إنشاء الطلب
      final baseUrl = await AuthService.getOrganizationUrl();
      final url = Uri.parse('$baseUrl/api/file/add');
      
      print('🌐 URL: $url');
      
      final request = http.MultipartRequest('POST', url);
      
      // إضافة الـ Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      print('📨 Headers:');
      print('   - Authorization: Bearer ${token.substring(0, 20)}...');
      print('   - Accept: application/json');

      // إضافة الملف (حقل File مطلوب)
      final fileBytes = await selectedFile!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'File',
        fileBytes,
        filename: fileName,
      ));
      
      print('📎 تم إضافة الملف');

      // إضافة الحقول المطلوبة
      request.fields['LevelSubjectId'] = matchingClass.levelSubjectId ?? '';
      request.fields['LevelId'] = matchingClass.levelId ?? '';
      request.fields['FileClassificationId'] = fileClassificationId;
      request.fields['Title'] = title;
      request.fields['FileType'] = fileExtension;
      
      // الحقول الاختيارية
      if (matchingClass.classId != null && matchingClass.classId!.isNotEmpty) {
        request.fields['ClassId'] = matchingClass.classId!;
      }
      
      request.fields['Path'] = ''; // فارغ كما هو مطلوب
      
      final note = detailsController.text.trim();
      if (note.isNotEmpty) {
        request.fields['Note'] = note;
      }

      print('📝 الحقول المرسلة:');
      request.fields.forEach((key, value) {
        print('   - $key: $value');
      });

      // إرسال الطلب
      print('🚀 جاري إرسال الطلب...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📥 استجابة السيرفر:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Status: ${response.statusCode >= 200 && response.statusCode < 300 ? "نجح ✅" : "فشل ❌"}');
      print('   - Response Body:');
      print(response.body);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // نجح الرفع
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم رفع الملف بنجاح! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // مسح البيانات بعد النجاح
        setState(() {
          selectedFile = null;
          selectedAudio = null;
          selectedSchool = null;
          selectedStage = null;
          selectedSection = null;
          selectedSubject = null;
          selectedUnit = null;
          detailsController.clear();
        });
      } else {
        // فشل الرفع
        throw Exception('فشل رفع الملف: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ خطأ في رفع الملف: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openUnitSelector() async {
    final controller = TextEditingController();
    String? localSelectedUnit = selectedUnit;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BlocBuilder<FileClassificationBloc, FileClassificationState>(
        bloc: _fileClassificationBloc,
        builder: (context, fileClassState) {
          // استخدام البيانات من BLoC مباشرة
          final localUnits = fileClassState is FileClassificationsLoaded
              ? fileClassState.fileClassifications.map((fc) => fc.name).toList()
              : List<String>.from(units);
          
          print('📋 Modal - عرض ${localUnits.length} وحدة');
          
          return StatefulBuilder(
            builder: (contextModal, setModalState) {
              return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 16,
                right: 16,
                left: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الفصل / الوحدة',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'أضف خيارًا جديدًا (مثال: الفصل الأول)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BlocBuilder<FileClassificationBloc,
                          FileClassificationState>(
                        bloc: _fileClassificationBloc,
                        builder: (context, fileClassificationState) {
                          final isLoading = fileClassificationState
                              is AddFileClassificationLoading;
                          return ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    final text = controller.text.trim();
                                    if (text.isNotEmpty &&
                                        !localUnits.contains(text)) {
                                      // Set the name in the controller for BLoC submission
                                      _fileClassificationNameController.text =
                                          text;
                                      // Submit via BLoC
                                      _submitFileClassification();
                                      controller.clear();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('إضافة',
                                    style: TextStyle(color: Colors.white)),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (localUnits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child:
                          Text('لا توجد خيارات بعد — قم بإضافة خيار بالأعلى.'),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: localUnits.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (_, i) {
                          final u = localUnits[i];
                          final isSelected = localSelectedUnit == u;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(u),
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: const Color(0xFF1976D2),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                bool? deleteConfirmed =
                                    await showModalBottomSheet<bool>(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                  ),
                                  builder: (deleteCtx) =>
                                      _DeleteConfirmationDialog(
                                    unitName: u,
                                    onConfirm: (confirmed) {
                                      if (confirmed) {
                                        setModalState(() {
                                          localUnits.removeAt(i);
                                          if (localSelectedUnit == u) {
                                            localSelectedUnit =
                                                localUnits.isNotEmpty
                                                    ? localUnits[0]
                                                    : null;
                                          }
                                        });
                                      }
                                      return confirmed;
                                    },
                                  ),
                                );

                                if (deleteConfirmed == true && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم الحذف بنجاح'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            onTap: () {
                              setModalState(() {
                                localSelectedUnit = u;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          units.clear();
                          units.addAll(localUnits);
                          if (localSelectedUnit != selectedUnit) {
                            selectedUnit = localSelectedUnit;
                          }
                        });
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'حفظ التغييرات',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
            },
          );
        },
      ),
    );
  }

  void _loadFileClassifications(
    List<TeacherClass> classes,
    String? school,
    String? stage,
    String? section,
    String? subject,
  ) {
    if (school == null || stage == null || section == null || subject == null) {
      print('⚠️ لا يمكن جلب FileClassifications - بعض الاختيارات مفقودة');
      return;
    }

    // Find matching TeacherClass
    final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
      classes,
      school,
      stage,
      section,
      subject,
    );

    if (matchingClass == null) {
      print('⚠️ لم يتم العثور على الفصل المطابق');
      return;
    }

    print('🔵 تم اختيار المادة - جلب FileClassifications');
    print('   - المدرسة: $school');
    print('   - المرحلة: $stage');
    print('   - الشعبة: $section');
    print('   - المادة: $subject');

    // Dispatch LoadFileClassificationsEvent
    _fileClassificationBloc.add(LoadFileClassificationsEvent(
      levelSubjectId: matchingClass.levelSubjectId ??
          matchingClass.subjectId ??
          '00000000-0000-0000-0000-000000000000',
      levelId: matchingClass.levelId ?? '00000000-0000-0000-0000-000000000000',
      classId: matchingClass.classId ?? '00000000-0000-0000-0000-000000000000',
    ));
  }

  void _submitFileClassification() {
    // Validation
    if (_fileClassificationNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم الفصل/الوحدة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    // Get teacher classes from ProfileBloc
    final profileState = _profileBloc.state;
    if (profileState is! ProfileLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تحميل بيانات المعلم'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final classes = profileState.classes;

    // Find matching TeacherClass using TeacherClassMatcher
    final matchingClass = TeacherClassMatcher.findMatchingTeacherClass(
      classes,
      selectedSchool!,
      selectedStage!,
      selectedSection!,
      selectedSubject!,
    );

    if (matchingClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على الفصل المطابق للاختيارات'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Dispatch AddFileClassificationEvent to BLoC
    _fileClassificationBloc.add(AddFileClassificationEvent(
      levelSubjectId: matchingClass.levelSubjectId ??
          matchingClass.subjectId ??
          '00000000-0000-0000-0000-000000000000',
      levelId: matchingClass.levelId ?? '00000000-0000-0000-0000-000000000000',
      classId: matchingClass.classId ?? '00000000-0000-0000-0000-000000000000',
      name: _fileClassificationNameController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      "رفع الملفات",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
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
        ),
        CustomPaint(
          size: Size.infinite,
          painter: _MeshBackgroundPainter(),
        ),
        CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(
              gridColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
        ),
        SafeArea(
            child: BlocBuilder<ProfileBloc, ProfileState>(
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

                  return BlocConsumer<FileClassificationBloc,
                      FileClassificationState>(
                    bloc: _fileClassificationBloc,
                    listener: (context, fileClassificationState) {
                      if (fileClassificationState
                          is AddFileClassificationSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(fileClassificationState.message),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Add the new unit to the local list
                        setState(() {
                          units.add(
                              fileClassificationState.fileClassification.name);
                          selectedUnit =
                              fileClassificationState.fileClassification.name;
                        });

                        // Clear the form
                        _fileClassificationNameController.clear();
                      } else if (fileClassificationState
                          is AddFileClassificationFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(fileClassificationState.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (fileClassificationState
                          is FileClassificationsLoaded) {
                        // تحديث قائمة الوحدات عند جلبها من السيرفر
                        print('✅ تم استلام FileClassifications في الشاشة');
                        print('   - العدد: ${fileClassificationState.fileClassifications.length}');
                        
                        setState(() {
                          units.clear();
                          units.addAll(
                            fileClassificationState.fileClassifications
                                .map((fc) => fc.name)
                                .toList(),
                          );
                        });
                        
                        print('📋 تم تحديث قائمة الوحدات المحلية:');
                        for (var i = 0; i < units.length; i++) {
                          print('   ${i + 1}. ${units[i]}');
                        }
                      } else if (fileClassificationState
                          is FileClassificationError) {
                        print('❌ خطأ في جلب FileClassifications: ${fileClassificationState.message}');
                      }
                    },
                    builder: (context, fileClassificationState) {
                      return Directionality(
                        textDirection: TextDirection.rtl,
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(top: 32, bottom: 32),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // اختيارات المدرسة والمرحلة والشعبة والمادة في الأعلى
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: schoolsList.map((school) {
                                          final isSelected =
                                              selectedSchool == school;
                                          return Container(
                                            margin: const EdgeInsets.only(
                                                right: 12),
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
                                                                .centerLeft,
                                                            end: Alignment
                                                                .centerRight,
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
                                                    school,
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
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: stagesList.map((stage) {
                                            final isSelected =
                                                selectedStage == stage;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xFF1976D2),
                                                                Color(
                                                                    0xFF64B5F6)
                                                              ],
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
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
                                                          offset: const Offset(
                                                              0, 2),
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
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                    ),
                                  if (selectedStage != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: sectionsList.map((section) {
                                            final isSelected =
                                                selectedSection == section;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      gradient: isSelected
                                                          ? const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xFF1976D2),
                                                                Color(
                                                                    0xFF64B5F6)
                                                              ],
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
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
                                                          offset: const Offset(
                                                              0, 2),
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
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                    ),
                                  if (selectedSection != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 8),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: subjectsList.map((subject) {
                                            final isSelected =
                                                selectedSubject == subject;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  right: 12),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                  onTap: () {
                                                    setState(() {
                                                      selectedSubject = subject;
                                                    });
                                                    
                                                    // جلب FileClassifications عند اختيار المادة
                                                    _loadFileClassifications(
                                                      classes,
                                                      selectedSchool,
                                                      selectedStage,
                                                      selectedSection,
                                                      subject,
                                                    );
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
                                                                Color(
                                                                    0xFF1976D2),
                                                                Color(
                                                                    0xFF64B5F6)
                                                              ],
                                                              begin: Alignment
                                                                  .centerLeft,
                                                              end: Alignment
                                                                  .centerRight,
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
                                                          offset: const Offset(
                                                              0, 2),
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
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),

                                  if (selectedSubject != null) ...[
                                    const SizedBox(height: 20),
                                    // اختيار ملف (صورة/فيديو/PDF)
                                    GestureDetector(
                                      onTap: pickFile,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 22, horizontal: 18),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(
                                              color: Color(0xFF1976D2),
                                              width: 1.2),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.attach_file,
                                                color: Color(0xFF1976D2),
                                                size: 32),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                selectedFile != null
                                                    ? selectedFile!.path
                                                        .split(Platform
                                                            .pathSeparator)
                                                        .last
                                                    : 'اختر ملف (PDF/صورة/فيديو)...',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.color ??
                                                      const Color(0xFF233A5A),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // حقل الفصل/الوحدة (بتصميم مشابه لزر رفع الملف)
                                    GestureDetector(
                                      onTap: _openUnitSelector,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: Border.all(
                                              color: const Color(0xFF1976D2),
                                              width: 1.2),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.book_outlined,
                                                color: Color(0xFF1976D2),
                                                size: 28),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'الفصل / الوحدة',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    selectedUnit ??
                                                        'اضغط لإضافة أو اختيار فصل/وحدة',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                              .textTheme
                                                              .titleMedium
                                                              ?.color ??
                                                          const Color(
                                                              0xFF233A5A),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Color(0xFF1976D2)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // حقل التفاصيل أو الرابط (بتصميم مشابه لزر رفع الملف)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                        border: Border.all(
                                          color: const Color(0xFF1976D2),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 16, top: 12, left: 16),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.link,
                                                    color: Color(0xFF1976D2),
                                                    size: 24),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'تفاصيل أو رابط',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.color ??
                                                        const Color(0xFF233A5A),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16)
                                                .copyWith(top: 8),
                                            child: TextFormField(
                                              controller: detailsController,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'أدخل وصفًا أو رابطًا إضافيًا...',
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 12),
                                                filled: true,
                                                fillColor: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[900]
                                                    : Colors.grey[100],
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: const BorderSide(
                                                      color: Color(0xFF1976D2),
                                                      width: 1.5),
                                                ),
                                              ),
                                              minLines: 3,
                                              maxLines: 5,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              style:
                                                  const TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // تسجيل صوتي داخل التطبيق
                                  Container(
                                    width: double.infinity,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isRecording
                                                ? Colors.red
                                                : const Color(0xFF1976D2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 28, vertical: 12),
                                          ),
                                          icon: Icon(
                                              _isRecording
                                                  ? Icons.stop
                                                  : Icons.mic,
                                              color: Colors.white),
                                          label: Text(
                                              _isRecording
                                                  ? 'إيقاف التسجيل'
                                                  : 'تسجيل صوتي',
                                              style: const TextStyle(
                                                  color: Colors.white)),
                                          onPressed: _isRecording
                                              ? stopRecording
                                              : startRecording,
                                        ),
                                        if (_audioPath != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              'تم تسجيل الصوت: ${_audioPath!.split(Platform.pathSeparator).last}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.color ??
                                                    const Color(0xFF233A5A),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1976D2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 38, vertical: 16),
                                      elevation: 4,
                                    ),
                                    icon: const Icon(Icons.upload_file,
                                        color: Colors.white),
                                    label: const Text(
                                      'إرسال',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    onPressed: submit,
                                  ),
                                ]),
                          ),
                        ),
                      );
                    },
                  );
                }))
      ]),
    );
  }
}

class _MeshBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFB0BEC5).withAlpha(33)
      ..strokeWidth = 1;
    final paintDot = Paint()
      ..color = const Color(0xFF3B5998).withAlpha(25)
      ..style = PaintingStyle.fill;
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
  _GridPainter({this.gridColor = Colors.white});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor.withAlpha(16)
      ..strokeWidth = 1;
    const step = 40.0;
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
