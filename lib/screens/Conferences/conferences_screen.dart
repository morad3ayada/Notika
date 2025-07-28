import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

class ConferencesScreen extends StatefulWidget {
  const ConferencesScreen({super.key});

  @override
  State<ConferencesScreen> createState() => _ConferencesScreenState();
}

class _ConferencesScreenState extends State<ConferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _durationController = TextEditingController();
  final _meetingLinkController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // اختيار المدرسة والمرحلة والشعبة والمادة
  String? selectedSchool;
  String? selectedStage;
  String? selectedSection;
  String? selectedSubject;

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

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _durationController.dispose();
    _meetingLinkController.dispose();
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
        _dateController.text = "${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}";
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
        _timeController.text = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // هنا يمكن إضافة منطق حفظ البيانات
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنشاء الجلسة التعليمية بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.pop(context);
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
                                colors: [Color(0xFF233A5A), Color(0xFF1976D2)],
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
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(ResponsiveHelper.isTablet(context) ? 100 : 80),
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
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.isTablet(context) ? 24.0 : 18.0,
                  vertical: ResponsiveHelper.isTablet(context) ? 12 : 8
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        "الجلسات التعليمية",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 20,
                            tablet: 24,
                            desktop: 26,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: ResponsiveHelper.getResponsiveIconSize(
                            context,
                            mobile: 24,
                            tablet: 28,
                            desktop: 32,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 24.0 : 18.0),
            child: Column(
              children: [
                SizedBox(height: ResponsiveHelper.isTablet(context) ? 120 : 100),
                
                // بطاقة العنوان
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF233A5A), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF233A5A).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 24 : 20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.video_call,
                        size: ResponsiveHelper.getResponsiveIconSize(
                          context,
                          mobile: 48,
                          tablet: 56,
                          desktop: 64,
                        ),
                        color: Colors.white,
                      ),
                      SizedBox(height: ResponsiveHelper.isTablet(context) ? 16 : 12),
                      Text(
                        "إنشاء جلسة تعليمية جديدة",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 18,
                            tablet: 22,
                            desktop: 24,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveHelper.isTablet(context) ? 8 : 6),
                      Text(
                        "أدخل تفاصيل الجلسة التعليمية",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.isTablet(context) ? 32 : 24),
                
                // اختيارات المدرسة والمرحلة والشعبة والمادة
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
                  const SizedBox(height: 24),
                  // نموذج إدخال البيانات
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(ResponsiveHelper.isTablet(context) ? 24 : 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان المحاضرة
                          Text(
                            "عنوان المحاضرة",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.titleMedium?.color ?? Color(0xFF233A5A),
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.isTablet(context) ? 12 : 8),
                          TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: "أدخل عنوان المحاضرة",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.title, color: Color(0xFF1976D2)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال عنوان المحاضرة';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 20),
                          // رابط الميتنج
                          Text(
                            "رابط الجلسة (ميتنغ)",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.titleMedium?.color ?? Color(0xFF233A5A),
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.isTablet(context) ? 12 : 8),
                          TextFormField(
                            controller: _meetingLinkController,
                            decoration: InputDecoration(
                              hintText: "ضع رابط الجلسة (Zoom, Google Meet ...)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.link, color: Color(0xFF1976D2)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى وضع رابط الجلسة';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 20),
                          // التاريخ والوقت في صف واحد
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "التاريخ",
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.titleMedium?.color ?? Color(0xFF233A5A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                                          context,
                                          mobile: 16,
                                          tablet: 18,
                                          desktop: 20,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveHelper.isTablet(context) ? 12 : 8),
                                    TextFormField(
                                      controller: _dateController,
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                      decoration: InputDecoration(
                                        hintText: "اختر التاريخ",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF1976D2)),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'يرجى اختيار التاريخ';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.isTablet(context) ? 16 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "الوقت",
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.titleMedium?.color ?? Color(0xFF233A5A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                                          context,
                                          mobile: 16,
                                          tablet: 18,
                                          desktop: 20,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: ResponsiveHelper.isTablet(context) ? 12 : 8),
                                    TextFormField(
                                      controller: _timeController,
                                      readOnly: true,
                                      onTap: () => _selectTime(context),
                                      decoration: InputDecoration(
                                        hintText: "اختر الوقت",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                        prefixIcon: const Icon(Icons.access_time, color: Color(0xFF1976D2)),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'يرجى اختيار الوقت';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveHelper.isTablet(context) ? 24 : 20),
                          // مدة المحاضرة
                          Text(
                            "مدة المحاضرة (بالدقائق)",
                            style: TextStyle(
                              color: Theme.of(context).textTheme.titleMedium?.color ?? Color(0xFF233A5A),
                              fontWeight: FontWeight.bold,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.isTablet(context) ? 12 : 8),
                          TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "أدخل مدة المحاضرة بالدقائق",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.timer, color: Color(0xFF1976D2)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال مدة المحاضرة';
                              }
                              if (int.tryParse(value) == null) {
                                return 'يرجى إدخال رقم صحيح';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ResponsiveHelper.isTablet(context) ? 32 : 24),
                          // زر إنشاء الجلسة
                          SizedBox(
                            width: double.infinity,
                            height: ResponsiveHelper.isTablet(context) ? 56 : 50,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                                shadowColor: const Color(0xFF1976D2).withOpacity(0.3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_call,
                                    size: ResponsiveHelper.getResponsiveIconSize(
                                      context,
                                      mobile: 20,
                                      tablet: 24,
                                      desktop: 26,
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveHelper.isTablet(context) ? 12 : 8),
                                  Text(
                                    "إنشاء الجلسة التعليمية",
                                    style: TextStyle(
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                                        context,
                                        mobile: 16,
                                        tablet: 18,
                                        desktop: 20,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.isTablet(context) ? 32 : 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
} 