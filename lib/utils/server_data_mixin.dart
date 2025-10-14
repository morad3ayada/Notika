import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/blocs/base/base_state.dart';

/// Mixin للشاشات التي تحتاج إلى جلب البيانات من السيرفر
mixin ServerDataMixin<T extends StatefulWidget> on State<T> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadServerData();
      });
    }
  }

  /// دالة لجلب البيانات من السيرفر - يجب override في كل شاشة
  Future<void> loadServerData();

  /// دالة مساعدة للتحقق من حالة البيانات
  bool isDataLoaded(BaseState state) {
    return state is BaseLoadedState;
  }

  /// دالة مساعدة للتحقق من حالة الخطأ
  bool hasError(BaseState state) {
    return state is BaseErrorState;
  }

  /// دالة مساعدة للتحقق من حالة التحميل
  bool isLoading(BaseState state) {
    return state is BaseLoadingState;
  }

  /// دالة لإعادة جلب البيانات
  void refreshData() {
    loadServerData();
  }
}

/// Widget wrapper للشاشات التي تستخدم ServerDataMixin
class ServerDataProvider<T extends BlocBase<BaseState>, S extends StatefulWidget> extends StatefulWidget {
  final Widget child;
  final T bloc;
  final VoidCallback? onDataLoaded;

  const ServerDataProvider({
    super.key,
    required this.child,
    required this.bloc,
    this.onDataLoaded,
  });

  @override
  State<ServerDataProvider> createState() => _ServerDataProviderState<T, S>();
}

class _ServerDataProviderState<T extends BlocBase<BaseState>, S extends StatefulWidget>
    extends State<ServerDataProvider> {

  @override
  void initState() {
    super.initState();
    // الاستماع لحالات البلوك لتنفيذ onDataLoaded عند نجاح التحميل
    widget.bloc.stream.listen((state) {
      if (state is BaseLoadedState && widget.onDataLoaded != null) {
        widget.onDataLoaded!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<T>.value(
      value: widget.bloc as T,
      child: widget.child,
    );
  }
}

/// Widget لعرض حالات التحميل والخطأ
class DataStateHandler extends StatelessWidget {
  final BaseState state;
  final Widget child;
  final VoidCallback? onRetry;

  const DataStateHandler({
    super.key,
    required this.state,
    required this.child,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state is BaseLoadingState) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('جاري التحميل...'),
            ],
          ),
        ),
      );
    }

    if (state is BaseErrorState) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                (state as BaseErrorState).message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('إعادة المحاولة'),
                ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}
