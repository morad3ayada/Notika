import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/all_students/all_students_barrel.dart';
import '../../../logic/blocs/conversations/conversations_barrel.dart';
import '../../../data/repositories/all_students_repository.dart';
import '../../../data/repositories/conversations_repository.dart';
import '../../../data/models/all_students_model.dart';
import '../../../data/models/conversation_model.dart';
import '../../../di/injector.dart';
import 'Chat_details_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  late final ConversationsBloc _conversationsBloc;
  late final AllStudentsBloc _allStudentsBloc;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // تهيئة BLoCs
    _conversationsBloc = ConversationsBloc(sl<ConversationsRepository>());
    _allStudentsBloc = AllStudentsBloc(sl<AllStudentsRepository>());
    
    // إضافة observer للتطبيق
    WidgetsBinding.instance.addObserver(this);
    
    // جلب البيانات عند فتح الشاشة
    _loadInitialData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // عند العودة للشاشة من background
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _conversationsBloc.close();
    _allStudentsBloc.close();
    super.dispose();
  }

  void _loadInitialData() {
    // جلب المحادثات من السيرفر
    _conversationsBloc.add(const LoadConversationsEvent());
  }

  void _refreshData() {
    // تحديث البيانات من السيرفر
    _conversationsBloc.add(const RefreshConversationsEvent());
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _isSearching = false);
      // البحث في المحادثات المحلية
      _conversationsBloc.add(SearchConversationsEvent(''));
    } else {
      setState(() => _isSearching = true);
      // البحث في جميع الطلاب من السيرفر
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
          Positioned.fill(
            child: CustomPaint(
              painter: _MeshBackgroundPainter(),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
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
                  // قائمة المحادثات أو نتائج البحث
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // تحديث البيانات عند السحب للأسفل
                        _refreshData();
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: _isSearching
                          ? _buildSearchResults()
                          : _buildConversationsList(),
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

  // قائمة المحادثات
  Widget _buildConversationsList() {
    return BlocBuilder<ConversationsBloc, ConversationsState>(
      bloc: _conversationsBloc,
      builder: (context, state) {
        // حالة التحميل
        if (state is ConversationsLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحميل المحادثات...'),
              ],
            ),
          );
        }
        
        // حالة الخطأ
        if (state is ConversationsError) {
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
                  onPressed: () => _conversationsBloc.add(const RefreshConversationsEvent()),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
        
        // حالة القائمة الفارغة
        if (state is ConversationsEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
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
        
        // حالة النجاح - عرض المحادثات
        if (state is ConversationsLoaded) {
          final conversations = state.conversations;
          
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لم يتم العثور على نتائج',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsetsDirectional.only(top: 6, bottom: 6),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationCard(conversation);
            },
          );
        }
        
        // حالة افتراضية
        return const Center(
          child: Text('لا توجد بيانات'),
        );
      },
    );
  }

  // عرض نتائج البحث في الطلاب
  Widget _buildSearchResults() {
    return BlocBuilder<AllStudentsBloc, AllStudentsState>(
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
                Text('جاري البحث...'),
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
                Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'لم يتم العثور على نتائج',
                  style: TextStyle(color: Colors.grey[600]),
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
              return _buildStudentCard(student);
            },
          );
        }
        
        // حالة افتراضية
        return const Center(
          child: Text('ابدأ البحث عن طالب'),
        );
      },
    );
  }

  // كارد للمحادثة
  Widget _buildConversationCard(Conversation conversation) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailsScreen(
                    userName: conversation.userName,
                    avatar: conversation.initial,
                    studentUserId: conversation.userId,
                  ),
                ),
              );
              // تحديث البيانات عند العودة من شاشة التفاصيل
              _refreshData();
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
                          conversation.userName,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xFF233A5A),
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          textAlign: TextAlign.start,
                        ),
                        if (conversation.lastMessage != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            conversation.lastMessage!,
                            style: const TextStyle(
                              color: Color(0xFF90A4AE),
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (conversation.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        conversation.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16, // تغيير من right: -18 إلى left: 16 لتجنب الخروج عن الحدود
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
                conversation.initial,
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
  }

  // كارد للطالب في نتائج البحث
  Widget _buildStudentCard(AllStudent student) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailsScreen(
                    userName: student.displayName,
                    avatar: student.initial,
                    studentUserId: student.userId ?? '',
                  ),
                ),
              );
              // تحديث البيانات عند العودة من شاشة التفاصيل
              _refreshData();
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
        Positioned(
          left: 16, // تغيير من right: -18 إلى left: 16 لتجنب الخروج عن الحدود
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
