import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:permission_handler/permission_handler.dart';

class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  State<PdfUploadScreen> createState() => _PdfUploadScreenState();
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
  final List<String> schools = [
    'مدرسة بغداد',
    'مدرسة الكوفة',
    'مدرسة البصرة',
  ];
  final List<String> stages = [
    'الأول ابتدائي',
    'الثاني ابتدائي',
    'الثالث ابتدائي',
    'الرابع ابتدائي',
    'الخامس ابتدائي',
    'السادس ابتدائي',
  ];
  final List<String> sections = ['شعبة أ', 'شعبة ب', 'شعبة ج', 'شعبة د'];
  final List<String> subjects = ['اللغة العربية', 'التربية الإسلامية'];
  final TextEditingController detailsController = TextEditingController();

  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    super.dispose();
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

  Future<void> _openUnitSelector() async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isNotEmpty && !units.contains(text)) {
                          setState(() {
                            units.add(text);
                          });
                          controller.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                      child: const Text('إضافة', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (units.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('لا توجد خيارات بعد — قم بإضافة خيار بالأعلى.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: units.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (_, i) {
                        final u = units[i];
                        final isSelected = selectedUnit == u;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(u),
                          leading: Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: const Color(0xFF1976D2)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                if (selectedUnit == u) selectedUnit = null;
                                units.removeAt(i);
                              });
                            },
                          ),
                          onTap: () {
                            setState(() {
                              selectedUnit = u;
                            });
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void submit() {
    if (selectedFile == null || selectedSchool == null || selectedStage == null || selectedSection == null || selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار جميع الحقول ورفع ملف')),
      );
      return;
    }
    // هنا يمكنك تنفيذ رفع الملف فعلياً
    String details = detailsController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم رفع الملف بنجاح!')),
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
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
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
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
            painter: _GridPainter(gridColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          ),
          SafeArea(
            child: Directionality(
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
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: schools.map((school) {
                              final isSelected = selectedSchool == school;
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
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
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                        school,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
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
                      ),
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
                                  margin: const EdgeInsets.only(right: 12),
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
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                          stage,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
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
                        ),
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
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: () {
                                        setState(() {
                                          selectedSection = section;
                                          selectedSubject = null;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                          section,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
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
                        ),
                      if (selectedSection != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: subjects.map((subject) {
                                final isSelected = selectedSubject == subject;
                                return Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: () {
                                        setState(() {
                                          selectedSubject = subject;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                          subject,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
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
                        ),
                      if (selectedSubject != null) ...[
                        const SizedBox(height: 20),
                        // اختيار ملف (صورة/فيديو/PDF)
                        GestureDetector(
                          onTap: pickFile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Color(0xFF1976D2), width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.attach_file, color: Color(0xFF1976D2), size: 32),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    selectedFile != null
                                        ? selectedFile!.path.split(Platform.pathSeparator).last
                                        : 'اختر ملف (PDF/صورة/فيديو)...',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
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
                        // حقل الفصل/الوحدة (اختيارات يضيفها المستخدم)
                        GestureDetector(
                          onTap: _openUnitSelector,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'الفصل / الوحدة',
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
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              suffixIcon: const Icon(Icons.expand_more, color: Color(0xFF1976D2)),
                            ),
                            child: Text(
                              selectedUnit ?? 'اختر الفصل/الوحدة أو أضف خيارًا جديدًا',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // حقل تفاصيل أو رابط
                        TextFormField(
                          controller: detailsController,
                          decoration: InputDecoration(
                            labelText: 'تفاصيل أو رابط',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                            ),
                            prefixIcon: const Icon(Icons.link, color: Color(0xFF1976D2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          minLines: 1,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                        ),
                        const SizedBox(height: 16),
                      ],
                    
                      // تسجيل صوتي داخل التطبيق
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isRecording ? Colors.red : const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                              ),
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
                            label: Text(_isRecording ? 'إيقاف التسجيل' : 'تسجيل صوتي', style: const TextStyle(color: Colors.white)),
                            onPressed: _isRecording ? stopRecording : startRecording,
                          ),
                          if (_audioPath != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'تم تسجيل الصوت: ${_audioPath!.split(Platform.pathSeparator).last}',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
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
                        padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 16),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.upload_file, color: Colors.white),
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
          ),
        ),
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