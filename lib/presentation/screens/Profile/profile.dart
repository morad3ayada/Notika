import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/services/auth_service.dart';
import '../auth/sign_in.dart';

class ClassInfo {
  final String id;
  final String name;
  final bool isActive;
  final Map<String, dynamic>? grades;
  final Map<String, bool>? permissions;

  ClassInfo({
    required this.id,
    required this.name,
    this.isActive = true,
    this.grades,
    this.permissions,
  });

  ClassInfo copyWith({
    bool? isActive,
    Map<String, dynamic>? grades,
    Map<String, bool>? permissions,
  }) {
    return ClassInfo(
      id: id,
      name: name,
      isActive: isActive ?? this.isActive,
      grades: grades ?? this.grades,
      permissions: permissions ?? this.permissions,
    );
  }
}

class ProfileData {
  final String userId;
  final String userName;
  final String userType;
  final String fullName;
  final String firstName;
  final String secondName;
  final String? thirdName;
  final String? fourthName;
  final String phone;
  final String? organizationName;
  final List<ClassInfo> classes;

  ProfileData({
    required this.userId,
    required this.userName,
    required this.userType,
    required this.fullName,
    required this.firstName,
    required this.secondName,
    this.thirdName,
    this.fourthName,
    required this.phone,
    this.organizationName,
    List<ClassInfo>? classes,
  }) : classes = classes ?? [
          ClassInfo(id: '1', name: 'الأول ابتدائي'),
          ClassInfo(id: '2', name: 'الثاني ابتدائي'),
          ClassInfo(id: '3', name: 'الثالث ابتدائي'),
        ];

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userType: json['userType'] ?? '',
      fullName: json['fullName']?.trim() ?? '',
      firstName: json['firstName'] ?? '',
      secondName: json['secondName'] ?? '',
      thirdName: json['thirdName'],
fourthName: json['fourthName'],
      phone: json['phone'] ?? '',
      organizationName: json['organization']?['name']?.toString() ?? json['organizationName']?.toString(),
      classes: (json['classes'] as List<dynamic>?)?.map((c) => ClassInfo(
            id: c['id']?.toString() ?? '',
            name: c['name']?.toString() ?? '',
            isActive: c['isActive'] ?? true,
            grades: c['grades'] != null ? Map<String, dynamic>.from(c['grades']) : null,
            permissions: c['permissions'] != null ? Map<String, bool>.from(c['permissions']) : null,
          )).toList(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final ProfileData profile;
  final List<Map<String, dynamic>> classes = [
    {"name": "الأول ابتدائي", "icon": Icons.looks_one, "color": Color(0xFF1976D2)},
    {"name": "الثاني ابتدائي", "icon": Icons.looks_two, "color": Color(0xFF43A047)},
    {"name": "الثالث ابتدائي", "icon": Icons.looks_3, "color": Color(0xFFFFC107)},
  ];
  
   ProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  final List<String> _gradeComponents = [
    'كويز 1',
    'كويز 2',
    'كويز 3',
    'تحريري 1',
    'تحريري 2',
    'تحريري 3',
    'واجب بيتي',
    'السلوك',
    'المشاركات',
    'النشاطات',
    'التقارير',
    'دفتر',
    'اصغاء',
    'قراءة',
    'محادثة',
    'مجموعات',
    'درجات اضافية'
  ];

  void _showGradeDistributionSheet(BuildContext context, String className, Color color) {
    final List<Map<String, dynamic>> components = [];
    final TextEditingController gradeController = TextEditingController();
    String? selectedComponent;
    int totalGrade = 0;

    void _addComponent() {
      if (selectedComponent != null && gradeController.text.isNotEmpty) {
        final int grade = int.tryParse(gradeController.text) ?? 0;
        setState(() {
          components.add({
            'name': selectedComponent!,
            'grade': grade,
          });
          totalGrade += grade;
          gradeController.clear();
          selectedComponent = null;
        });
      }
    }

    void _saveChanges() {
      if (totalGrade != 100) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطأ في التوزيع'),
            content: Text('مجموع الدرجات $totalGrade% يجب أن يكون 100%'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      } else {
        // Save logic here
        Navigator.pop(context);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.assignment, color: color, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          'توزيع درجات $className',
                          style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الدرجة النهائية: 100',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Component selection
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedComponent,
                            decoration: InputDecoration(
                              labelText: 'اختر المكون',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _gradeComponents
                                .where((component) => !components.any((c) => c['name'] == component))
                                .map((component) => DropdownMenuItem(
                                      value: component,
                                      child: Text(component),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedComponent = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: gradeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'الدرجة',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: _addComponent,
                        ),
                      ],
                    ),
                    
                    // Added components list
                    const SizedBox(height: 16),
                    if (components.isNotEmpty) ...[
                      const Text(
                        'المكونات المضافة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...components.map((component) => ListTile(
                        title: Text(component['name']),
                        trailing: Text('${component['grade']}%'),
                        leading: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              totalGrade -= (component['grade'] as int);
                              components.remove(component);
                            });
                          },
                        ),
                      )).toList(),
                      const Divider(),
                      Text(
                        'المجموع: $totalGrade%',
                        style: TextStyle(
                          color: totalGrade == 100 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'حفظ التوزيع',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  
  Widget _buildGradeItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void initState() {
    super.initState();
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: TextStyle(
              color: isTotal ? const Color(0xFF1976D2) : null,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isTotal ? const Color(0xFF1976D2) : null,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionRow(String permission, bool hasPermission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            color: hasPermission ? const Color(0xFF43A047) : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            permission,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // صورة رمزية أكبر مع ظل وحد ملون
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Color(0xFF1976D2), width: 5),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 62,
                      backgroundColor: Colors.transparent,
                      child: Text(
widget.profile.fullName.isNotEmpty ? widget.profile.fullName.characters.first : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 54,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // بيانات المعلم في كارت أفقي عصري متجاوب
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 350;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(22),
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
                          children: [
                            const Icon(Icons.person, color: Color(0xFF1976D2), size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.profile.fullName}',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : (Theme.of(context).textTheme.titleLarge?.color ?? const Color(0xFF233A5A)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Username Row
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, color: Color(0xFF1976D2), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            ' ${widget.profile.userName}',
                                            style: TextStyle(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : const Color(0xFF233A5A),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Phone Row
                                      Row(
                                        children: [
                                          const Icon(Icons.phone, color: Color(0xFF1976D2), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            widget.profile.phone,
                                            style: TextStyle(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : const Color(0xFF233A5A),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.badge, color: Color(0xFF43A047), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.profile.userType == 'Teacher' ? 'معلم' : widget.profile.userType,
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Color(0xFF1976D2),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.school, color: Color(0xFF43A047), size: 18),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Consumer<UserProvider>(
                                          builder: (context, userProvider, _) {
                                            final orgName = userProvider.organization?.name ?? widget.profile.organizationName ?? 'مدرسة الانامل الواعدة';
                                            return Text(
                                              orgName,
                                              style: TextStyle(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : Color(0xFF1976D2),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Removed phone number from the right side
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // كارت الفصول بشكل عصري
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Color(0xFF1976D2), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الفصول التي تدرّسها:',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        ...widget.classes.map((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(c["icon"] as IconData, color: c["color"] as Color, size: 26),
                              const SizedBox(width: 10),
                              Text(
                                c["name"]!,
                                style: TextStyle(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : c["color"] as Color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  // Daily Grades Distribution Section
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF1976D2), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'توزيع درجات الطلاب اليومية',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Tajawal',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 10),
                        ...[
                          {
                            'name': 'الأول ابتدائي',
                            'color': const Color(0xFF1976D2),
                          },
                          {
                            'name': 'الثاني ابتدائي',
                            'color': const Color(0xFF43A047),
                          },
                          {
                            'name': 'الثالث ابتدائي',
                            'color': const Color(0xFFFFC107),
                          },
                        ].map((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showGradeDistributionSheet(
                                      context, c['name'] as String, c['color'] as Color),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.assignment, color: c['color'] as Color, size: 26),
                                        const SizedBox(width: 10),
                                        Text(
                                          'توزيع درجات ${c['name']}',
                                          style: TextStyle(
                                            color: c['color'] as Color,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Tajawal',
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, size: 22),
                                color: c['color'] as Color,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: AlertDialog(
                                          title: Text('توزيع درجات ${c['name']}'),
                                          content: Text(
                                            'هنا يمكنك إدارة درجات طلاب ${c['name']}. اضغط على اسم الصف لفتح نافذة إدارة التوزيع.',
                                            textDirection: TextDirection.rtl,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('حسناً'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  // Student Permissions Section
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF1976D2), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, color: Color(0xFF1976D2), size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'صلاحيات الطلاب',
                              style: TextStyle(
                                color: Color(0xFF1976D2),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Tajawal',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'يمكنك التحكم في الصلاحيات التي تتيح للطلاب التواصل معك لكل صف',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontFamily: 'Tajawal',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 12),
                        ...[
                          {'name': 'الأول ابتدائي', 'color': Color(0xFF1976D2)},
                          {'name': 'الثاني ابتدائي', 'color': Color(0xFF43A047)},
                          {'name': 'الثالث ابتدائي', 'color': Color(0xFFFFC107)}
                        ].map((c) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${c['name']}',
                                style: TextStyle(
                                  color: c['color'] as Color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Tajawal',
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${true ? 'مفعل' : 'معطل'}',
                                    style: TextStyle(
                                      color: c['color'] as Color,
                                      fontSize: 14,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: true,
                                    onChanged: (value) {},
                                    activeColor: c['color'] as Color,
                                    activeTrackColor: (c['color'] as Color).withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  
                  // Change Password Button
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.lock_reset, color: Colors.white),
                    label: const Text(
                      'تغيير كلمة المرور',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    onPressed: () {
                      final currentPasswordController = TextEditingController();
                      final newPasswordController = TextEditingController();
                      final confirmPasswordController = TextEditingController();
                      final formKey = GlobalKey<FormState>();

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                                left: 24,
                                right: 24,
                                top: 24,
                              ),
                              child: Form(
                                key: formKey,
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 50,
                                          height: 5,
                                          margin: const EdgeInsets.only(bottom: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        'تغيير كلمة المرور',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                          fontFamily: 'Tajawal',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 25),
                                      TextFormField(
                                        controller: currentPasswordController,
                                        obscureText: true,
                                        style: const TextStyle(fontFamily: 'Tajawal'),
                                        decoration: InputDecoration(
                                          labelText: 'كلمة المرور الحالية',
                                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!), 
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                          ),
                                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976D2)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء إدخال كلمة المرور الحالية';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: newPasswordController,
                                        obscureText: true,
                                        style: const TextStyle(fontFamily: 'Tajawal'),
                                        decoration: InputDecoration(
                                          labelText: 'كلمة المرور الجديدة',
                                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!), 
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                          ),
                                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976D2)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء إدخال كلمة المرور الجديدة';
                                          }
                                          if (value.length < 6) {
                                            return 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: confirmPasswordController,
                                        obscureText: true,
                                        style: const TextStyle(fontFamily: 'Tajawal'),
                                        decoration: InputDecoration(
                                          labelText: 'تأكيد كلمة المرور الجديدة',
                                          labelStyle: const TextStyle(color: Color(0xFF757575)),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!), 
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                          ),
                                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF1976D2)),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء تأكيد كلمة المرور الجديدة';
                                          }
                                          if (value != newPasswordController.text) {
                                            return 'كلمة المرور غير متطابقة';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 30),
                                      SizedBox(
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (formKey.currentState!.validate()) {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => Directionality(
                                                  textDirection: TextDirection.rtl,
                                                  child: AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    title: const Text(
                                                      'تأكيد التغيير',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontFamily: 'Tajawal',
                                                      ),
                                                    ),
                                                    content: const Text(
                                                      'هل أنت متأكد من تغيير كلمة المرور؟',
                                                      style: TextStyle(
                                                        fontFamily: 'Tajawal',
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(ctx).pop(false),
                                                        child: const Text(
                                                          'إلغاء',
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontFamily: 'Tajawal',
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF1976D2),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(ctx).pop(true);
                                                          Navigator.of(context).pop();
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: const Text(
                                                                'تم تغيير كلمة المرور بنجاح',
                                                                style: TextStyle(fontFamily: 'Tajawal'),
                                                              ),
                                                              backgroundColor: const Color(0xFF1976D2),
                                                              behavior: SnackBarBehavior.floating,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                              margin: const EdgeInsets.all(16),
                                                            ),
                                                          );
                                                        },
                                                        child: const Text(
                                                          'تأكيد',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontFamily: 'Tajawal',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1976D2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            'حفظ التغييرات',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontFamily: 'Tajawal',
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Logout Button
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    onPressed: () async {
                      await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('تأكيد تسجيل الخروج'),
                          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('لا'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                              ),
                              onPressed: () async {
                                Navigator.of(ctx).pop(true); // يقفل النافذة

                                // عرض مؤشر تقدم
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(child: CircularProgressIndicator()),
                                );

                                try {
                                  await AuthService().serverLogout(requireUserAction: true);
                                } catch (_) {}

                                await context.read<UserProvider>().logout();
                                await AuthService.logout();

                                if (mounted) {
                                  Navigator.of(context).pop(); // يقفل الـ progress dialog
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const SignInScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                              child: const Text('نعم'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
