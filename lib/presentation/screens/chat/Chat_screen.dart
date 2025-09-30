import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/all_students/all_students_barrel.dart';
import '../../../data/repositories/all_students_repository.dart';
import '../../../data/models/all_students_model.dart';
import '../../../di/injector.dart';
import 'Chat_details_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final AllStudentsBloc _allStudentsBloc;

  @override
  void initState() {
    super.initState();
    _allStudentsBloc = AllStudentsBloc(sl<AllStudentsRepository>())
      ..add(const LoadAllStudentsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _allStudentsBloc.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      _allStudentsBloc.add(const LoadAllStudentsEvent());
    } else {
      _allStudentsBloc.add(SearchAllStudentsEvent(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          // خلفية mesh/grid مثل الرئيسية
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
            painter: _GridPainter(),
          ),
          // محتوى الصفحة: حقل البحث + قائمة الأشخاص
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  // حقل البحث
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        hintText: 'ابحث عن طالب...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF1976D2)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // قائمة الطلاب من السيرفر
                  Expanded(
                    child: BlocBuilder<AllStudentsBloc, AllStudentsState>(
                      bloc: _allStudentsBloc,
                      builder: (context, state) {
                        // حالة التحميل
                        if (state is AllStudentsLoading) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('جاري تحميل الطلاب...'),
                              ],
                            ),
                          );
                        }
                        
                        // حالة الخطأ
                        if (state is AllStudentsError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  state.message,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _allStudentsBloc.add(const RefreshAllStudentsEvent()),
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        // حالة القائمة الفارغة
                        if (state is AllStudentsEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 60, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  state.message,
                                  style: TextStyle(color: Colors.grey[600]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                        
                        // حالة النجاح - عرض الطلاب
                        if (state is AllStudentsLoaded) {
                          final students = state.students;
                          
                          return ListView.separated(
                            padding: const EdgeInsetsDirectional.only(top: 6, bottom: 6),
                            itemCount: students.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final student = students[index];
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatDetailsScreen(
                                        userName: student.displayName,
                                        avatar: student.initial,
                                        studentUserId: student.userId ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsetsDirectional.only(start: 60, end: 16, top: 14, bottom: 14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student.displayName,
                                              style: TextStyle(
                                                color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                              textAlign: TextAlign.start,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              student.nickName ?? 'طالب',
                                              style: const TextStyle(
                                                color: Color(0xFF90A4AE),
                                                fontSize: 14.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Change avatar to use only one Arabic initial
                            Positioned(
                              right: -18,
                              top: 12,
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(color: Theme.of(context).cardColor, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    student.initial,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                            },
                          );
                        }
                        
                        // حالة افتراضية
                        return const Center(
                          child: Text('لا توجد بيانات'),
                        );
                      },
                    ),
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(16)
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
