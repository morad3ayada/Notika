import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../logic/blocs/profile/profile_bloc.dart';
import '../../../logic/blocs/profile/profile_event.dart';
import '../../../logic/blocs/profile/profile_state.dart';
import '../../../data/models/profile_models.dart';
import '../../../di/injector.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../logic/blocs/conferences/conferences_bloc.dart';
import '../../../logic/blocs/conferences/conferences_event.dart';
import '../../../logic/blocs/conferences/conferences_state.dart';
import '../../../data/models/conference_model.dart';
import '../../../data/repositories/conferences_repository.dart';
import '../../../utils/teacher_class_matcher.dart';

class ConferencesScreen extends StatefulWidget {
  const ConferencesScreen({super.key});

  @override
  State<ConferencesScreen> createState() => _ConferencesScreenState();
}

class _ConferencesScreenState extends State<ConferencesScreen> {
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;
  late final ProfileBloc _profileBloc;
  late final ConferencesBloc _conferencesBloc;

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

  // Helper method to convert ConferenceModel to Map for existing UI components
  Map<String, dynamic> _conferenceToMap(ConferenceModel conference,
      {bool isUpcoming = true}) {
    final startDate = conference.startAt;
    final duration = '${conference.durationMinutes} دقيقة';

    return {
      'title': conference.title.isNotEmpty
          ? conference.title
          : '${conference.subjectName} - ${conference.className}',
      'date':
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
      'time':
          '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
      'duration': duration,
      'meetingLink': conference.link,
      if (!isUpcoming)
        'attended': true, // For past conferences, assume attended
    };
  }

  // Helper method to launch meeting URL
  Future<void> _launchMeetingUrl(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط الجلسة غير متوفر'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Clean and validate URL
      String cleanUrl = url.trim();
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final Uri uri = Uri.parse(cleanUrl);
      debugPrint('🔗 Attempting to launch URL: $cleanUrl');

      // Try different launch modes in order of preference
      bool launched = false;

      // First try: Launch in external application (preferred for meeting apps)
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ Launched in external application');
      } catch (e) {
        debugPrint('⚠️ External application launch failed: $e');
      }

      // Second try: Launch in external browser if external app failed
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          debugPrint('✅ Launched in external non-browser application');
        } catch (e) {
          debugPrint('⚠️ External non-browser launch failed: $e');
        }
      }

      // Third try: Launch in browser
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
          debugPrint('✅ Launched with platform default');
        } catch (e) {
          debugPrint('⚠️ Platform default launch failed: $e');
        }
      }

      // If all methods failed, show options to user
      if (!launched) {
        _showLaunchOptionsDialog(cleanUrl);
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      _showLaunchOptionsDialog(url);
    }
  }

  // Show dialog with options when URL launch fails
  void _showLaunchOptionsDialog(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('فتح رابط الجلسة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'لا يمكن فتح الرابط تلقائياً. يرجى اختيار أحد الخيارات التالية:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    url,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _copyToClipboard(url);
                },
                child: const Text('نسخ الرابط'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    // Force launch in browser
                    await launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.inAppBrowserView,
                    );
                  } catch (e) {
                    _copyToClipboard(url);
                  }
                },
                child: const Text('فتح في المتصفح'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to copy text to clipboard
  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ الرابط إلى الحافظة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error copying to clipboard: $e');
    }
  }

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Widget _buildHorizontalSelector({
    required List<String> items,
    required String? selected,
    required Function(String) onSelect,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF233A5A),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final isSelected = selected == item;
              return Container(
                margin: const EdgeInsets.only(left: 8),
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
                        color: isSelected ? null : Colors.white,
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
                              : const Color(0xFF233A5A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  void _showConferenceDetails(
      Map<String, dynamic> conference, bool isUpcoming) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.videocam,
                    color: isUpcoming ? Colors.blue : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      conference['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                  Icons.calendar_today, 'التاريخ', conference['date']),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.access_time, 'الوقت', conference['time']),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.timer_outlined, 'المدة', conference['duration']),
              if (isUpcoming) ...[
                const SizedBox(height: 12),
                _buildLinkDetailRow(Icons.link, 'رابط الاجتماع',
                    conference['meetingLink'] ?? 'لم يتم إضافة رابط'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _launchMeetingUrl(conference['meetingLink']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'انضم إلى الجلسة',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      conference['attended']
                          ? 'تمت المشاركة'
                          : 'لم يتم المشاركة',
                      style: TextStyle(
                        color:
                            conference['attended'] ? Colors.green : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Color(0xFF23459A), // Dark blue color for the value
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkDetailRow(IconData icon, String label, String value) {
    final bool hasValidLink = value.isNotEmpty && value != 'لم يتم إضافة رابط';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              if (hasValidLink)
                GestureDetector(
                  onTap: () => _launchMeetingUrl(value),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF1976D2).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.launch,
                          size: 16,
                          color: Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'اضغط للانضمام',
                            style: const TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        if (hasValidLink)
          IconButton(
            onPressed: () => _copyToClipboard(value),
            icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
            tooltip: 'نسخ الرابط',
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _profileBloc = ProfileBloc(sl<ProfileRepository>())
      ..add(const FetchProfile());
    _conferencesBloc = ConferencesBloc(sl<ConferencesRepository>())
      ..add(const LoadConferences());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _meetingLinkController.dispose();
    _profileBloc.close();
    _conferencesBloc.close();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  /// Creates a new conference by sending data to the server using BLoC
  void createConference({
    required String title,
    required String link,
    required DateTime startAt,
    required int durationMinutes,
    required String? selectedSchool,
    required String? selectedLevel,
    required String? selectedSection,
    required String? selectedSubject,
    required List<TeacherClass> teacherClasses,
  }) {
    try {
      debugPrint('🔄 Starting conference creation...');

      // Find matching TeacherClass to extract GUIDs
      final matchingTeacherClass = TeacherClassMatcher.findMatchingTeacherClass(
        teacherClasses,
        selectedSchool,
        selectedLevel,
        selectedSection,
        selectedSubject,
      );

      if (matchingTeacherClass == null) {
        throw Exception('لم يتم العثور على الفصل المطابق للاختيارات المحددة');
      }

      // Extract GUIDs from TeacherClass
      final levelSubjectId = matchingTeacherClass.levelSubjectId ??
          matchingTeacherClass.subjectId ??
          '';
      final levelId = matchingTeacherClass.levelId ?? '';
      final classId = matchingTeacherClass.classId ?? '';

      // Validate GUIDs
      if (levelSubjectId.isEmpty || levelId.isEmpty || classId.isEmpty) {
        throw Exception('معرفات الفصل غير مكتملة. يرجى التحقق من البيانات.');
      }

      debugPrint('📋 Conference data:');
      debugPrint('   Title: $title');
      debugPrint('   Link: $link');
      debugPrint('   Start At: ${startAt.toIso8601String()}');
      debugPrint('   Duration: $durationMinutes minutes');
      debugPrint('   Level Subject ID: $levelSubjectId');
      debugPrint('   Level ID: $levelId');
      debugPrint('   Class ID: $classId');

      // Prepare request body exactly as specified in curl command
      final requestBody = {
        'levelSubjectId': levelSubjectId,
        'levelId': levelId,
        'classId': classId,
        'title': title,
        'link': link,
        'startAt': startAt.toIso8601String(),
        'durationMinutes': durationMinutes,
      };

      // Send to server using ConferencesBloc
      _conferencesBloc.add(CreateConference(requestBody));
    } catch (e) {
      debugPrint('❌ Error preparing conference data: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إعداد بيانات الجلسة: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'إغلاق',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  void _showAddConferenceDialog(BuildContext context) {
    // Use local variables for instant UI feedback inside the bottom sheet
    String? localSelectedSchool = selectedSchool;
    String? localSelectedStage = selectedStage;
    String? localSelectedSection = selectedSection;
    String? localSelectedSubject = selectedSubject;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'إنشاء جلسة جديدة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(width: 48), // For proper centering
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'عنوان الجلسة',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1976D2), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          textAlign: TextAlign.right,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال عنوان الجلسة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        StatefulBuilder(
                          builder: (context, setModalState) {
                            return BlocBuilder<ProfileBloc, ProfileState>(
                              bloc: _profileBloc,
                              builder: (context, state) {
                                if (state is ProfileLoading ||
                                    state is ProfileInitial) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 16.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                if (state is ProfileError) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Text(state.message,
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold)),
                                  );
                                }
                                final loaded = state as ProfileLoaded;
                                final classes = loaded.classes;
                                final schools = _buildSchools(classes);
                                final stages =
                                    _buildStages(classes, localSelectedSchool);
                                final sections = _buildSections(classes,
                                    localSelectedSchool, localSelectedStage);
                                final subjects = _buildSubjects(
                                    classes,
                                    localSelectedSchool,
                                    localSelectedStage,
                                    localSelectedSection);

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHorizontalSelector(
                                      items: schools,
                                      selected: localSelectedSchool,
                                      onSelect: (val) {
                                        setModalState(() {
                                          localSelectedSchool = val;
                                          localSelectedStage = null;
                                          localSelectedSection = null;
                                          localSelectedSubject = null;
                                        });
                                      },
                                      label: 'المدرسة',
                                    ),
                                    const SizedBox(height: 12),
                                    if (localSelectedSchool != null)
                                      _buildHorizontalSelector(
                                        items: stages,
                                        selected: localSelectedStage,
                                        onSelect: (val) {
                                          setModalState(() {
                                            localSelectedStage = val;
                                            localSelectedSection = null;
                                            localSelectedSubject = null;
                                          });
                                        },
                                        label: 'المرحلة',
                                      ),
                                    if (localSelectedSchool != null)
                                      const SizedBox(height: 12),
                                    if (localSelectedStage != null)
                                      _buildHorizontalSelector(
                                        items: sections,
                                        selected: localSelectedSection,
                                        onSelect: (val) {
                                          setModalState(() {
                                            localSelectedSection = val;
                                            localSelectedSubject = null;
                                          });
                                        },
                                        label: 'الشعبة',
                                      ),
                                    if (localSelectedStage != null)
                                      const SizedBox(height: 12),
                                    if (localSelectedSection != null)
                                      _buildHorizontalSelector(
                                        items: subjects,
                                        selected: localSelectedSubject,
                                        onSelect: (val) {
                                          setModalState(() {
                                            localSelectedSubject = val;
                                          });
                                        },
                                        label: 'المادة',
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: InputDecoration(
                            labelText: 'تاريخ الجلسة',
                            alignLabelWithHint: true,
                            suffixIcon: const Icon(Icons.calendar_today,
                                color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1976D2), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          textAlign: TextAlign.right,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء اختيار تاريخ الجلسة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _timeController,
                          readOnly: true,
                          onTap: () => _selectTime(context),
                          decoration: InputDecoration(
                            labelText: 'وقت الجلسة',
                            alignLabelWithHint: true,
                            suffixIcon: const Icon(Icons.access_time,
                                color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1976D2), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          textAlign: TextAlign.right,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء اختيار وقت الجلسة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _durationController,
                          decoration: InputDecoration(
                            labelText: 'مدة الجلسة (بالدقائق)',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1976D2), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال مدة الجلسة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _meetingLinkController,
                          decoration: InputDecoration(
                            labelText: 'رابط الجلسة',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1976D2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1976D2), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          textAlign: TextAlign.right,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الرجاء إدخال رابط الجلسة';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: BlocBuilder<ConferencesBloc, ConferencesState>(
                            bloc: _conferencesBloc,
                            builder: (context, conferenceState) {
                              final isCreating =
                                  conferenceState is ConferenceCreating;

                              return ElevatedButton(
                                onPressed: isCreating
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          // Validate that all selections are made
                                          if (localSelectedSchool == null ||
                                              localSelectedStage == null ||
                                              localSelectedSection == null ||
                                              localSelectedSubject == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'يرجى اختيار جميع الحقول المطلوبة'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }

                                          // Validate date and time
                                          if (_selectedDate == null ||
                                              _selectedTime == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'يرجى اختيار تاريخ ووقت الجلسة'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }

                                          // Combine date and time
                                          final startAt = DateTime(
                                            _selectedDate!.year,
                                            _selectedDate!.month,
                                            _selectedDate!.day,
                                            _selectedTime!.hour,
                                            _selectedTime!.minute,
                                          );

                                          // Parse duration
                                          final durationText =
                                              _durationController.text.trim();
                                          final durationMinutes =
                                              int.tryParse(durationText);
                                          if (durationMinutes == null ||
                                              durationMinutes <= 0) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'يرجى إدخال مدة صالحة للجلسة'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }

                                          // Get teacher classes from ProfileBloc
                                          final profileState =
                                              _profileBloc.state;
                                          if (profileState is! ProfileLoaded) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'لم يتم تحميل بيانات المعلم'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          // Call createConference function (will trigger BLoC)
                                          createConference(
                                            title: _titleController.text.trim(),
                                            link: _meetingLinkController.text
                                                .trim(),
                                            startAt: startAt,
                                            durationMinutes: durationMinutes,
                                            selectedSchool: localSelectedSchool,
                                            selectedLevel: localSelectedStage,
                                            selectedSection:
                                                localSelectedSection,
                                            selectedSubject:
                                                localSelectedSubject,
                                            teacherClasses:
                                                profileState.classes,
                                          );

                                          // Persist selections back to parent state
                                          setState(() {
                                            selectedSchool =
                                                localSelectedSchool;
                                            selectedStage = localSelectedStage;
                                            selectedSection =
                                                localSelectedSection;
                                            selectedSubject =
                                                localSelectedSubject;
                                          });

                                          // Clear form
                                          _titleController.clear();
                                          _dateController.clear();
                                          _timeController.clear();
                                          _durationController.clear();
                                          _meetingLinkController.clear();
                                          _selectedDate = null;
                                          _selectedTime = null;

                                          // Close dialog
                                          Navigator.pop(context);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: BlocBuilder<ConferencesBloc,
                                    ConferencesState>(
                                  bloc: _conferencesBloc,
                                  builder: (context, conferenceState) {
                                    if (conferenceState is ConferenceCreating) {
                                      return const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'جاري الإرسال...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                    return const Text(
                                      'حفظ وإرسال',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConferenceCard(Map<String, dynamic> conference,
      {bool isUpcoming = true}) {
    return GestureDetector(
        onTap: () => _showConferenceDetails(conference, isUpcoming),
        child: Card(
          margin: const EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 8),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.videocam,
                      color: isUpcoming ? Colors.blue : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        conference['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      conference['date'],
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      conference['time'],
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Spacer(),
                    if (!isUpcoming)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: conference['attended']
                              ? Colors.green[100]
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          conference['attended'] ? 'حضر' : 'لم يحضر',
                          style: TextStyle(
                            color: conference['attended']
                                ? Colors.green[800]
                                : Colors.red[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      conference['duration'],
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Spacer(),
                    if (isUpcoming)
                      ElevatedButton(
                        onPressed: () async {
                          await _launchMeetingUrl(conference['meetingLink']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text('انضم الآن',
                            style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ));
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
                        'الجلسات التعليمية',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // For centering the title
                  ],
                ),
              ),
            ),
          ),
        ),
        body: BlocConsumer<ConferencesBloc, ConferencesState>(
            bloc: _conferencesBloc,
            listener: (context, state) {
              if (state is ConferenceCreated) {
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'تم إنشاء الجلسة بنجاح: ${state.conference.title}'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is ConferenceCreateError) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل في إنشاء الجلسة: ${state.message}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'إغلاق',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Registration section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 24),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF233A5A), Color(0xFF1976D2)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.video_call,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'إنشاء جلسة تعليمية جديدة',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'قم بإنشاء جلسة تعليمية جديدة للطلاب وحدد موعدها وروابط الاجتماع',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _showAddConferenceDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'إنشاء جلسة جديدة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Conferences Content with BLoC
                    BlocBuilder<ConferencesBloc, ConferencesState>(
                      bloc: _conferencesBloc,
                      builder: (context, state) {
                        if (state is ConferencesLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(50.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1976D2)),
                              ),
                            ),
                          );
                        }

                        if (state is ConferencesError) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'خطأ في تحميل الجلسات',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    _conferencesBloc
                                        .add(const RefreshConferences());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1976D2),
                                  ),
                                  child: const Text(
                                    'إعادة المحاولة',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state is ConferencesLoaded) {
                          final upcomingConferences = state.upcomingConferences
                              .map((c) => _conferenceToMap(c, isUpcoming: true))
                              .toList();
                          final pastConferences = state.pastConferences
                              .map(
                                  (c) => _conferenceToMap(c, isUpcoming: false))
                              .toList();

                          return Column(
                            children: [
                              // Upcoming Conferences Section with Horizontal Scroll
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.upcoming,
                                            color: Color(0xFF1976D2)),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'الجلسات القادمة',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: () {
                                            _conferencesBloc.add(
                                                const RefreshConferences());
                                          },
                                          icon: const Icon(Icons.refresh,
                                              color: Color(0xFF1976D2)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (upcomingConferences.isEmpty)
                                      Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.event_busy,
                                                size: 48, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text(
                                              'لا توجد جلسات قادمة',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 220,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: upcomingConferences.length,
                                          itemBuilder: (context, index) {
                                            return SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.85,
                                              child: _buildConferenceCard(
                                                  upcomingConferences[index]),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Past Conferences Section
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.history, color: Colors.grey),
                                        SizedBox(width: 8),
                                        Text(
                                          'الجلسات السابقة',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (pastConferences.isEmpty)
                                      Container(
                                        height: 120,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey[200]!),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.history_toggle_off,
                                                size: 48, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text(
                                              'لا توجد جلسات سابقة',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Container(
                                        constraints: BoxConstraints(
                                          minHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.3,
                                          maxHeight: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.5,
                                        ),
                                        child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: pastConferences.length,
                                          itemBuilder: (context, index) {
                                            return _buildConferenceCard(
                                              pastConferences[index],
                                              isUpcoming: false,
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        // Initial state
                        return const Padding(
                          padding: EdgeInsets.all(50.0),
                          child: Center(
                            child: Text(
                              'جاري تحميل الجلسات...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
      ),
    );
  }
}
