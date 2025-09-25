import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';
import '../../../data/repositories/schedule_repository.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository repository;

  ScheduleBloc({required this.repository}) : super(const ScheduleInitial()) {
    on<FetchScheduleEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchScheduleEvent event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(const ScheduleLoading());
    try {
      final schedules = await repository.getSchedule();
      emit(ScheduleLoaded(schedules));
    } catch (e) {
      debugPrint('ScheduleBloc error: $e');
      emit(ScheduleError(e.toString()));
    }
  }
}
