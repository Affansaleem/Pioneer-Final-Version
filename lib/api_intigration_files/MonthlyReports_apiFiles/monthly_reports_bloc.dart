import 'dart:async';
import 'package:bloc/bloc.dart';
import '../models/MonthlyReports_model.dart';
import '../repository/MonthlyReports_repository.dart';

part 'monthly_reports_event.dart';
part 'monthly_reports_state.dart';

class MonthlyReportsBloc extends Bloc<MonthlyReportsEvent, MonthlyReportsState> {
  final MonthlyReportsRepository repository;

  MonthlyReportsBloc({required this.repository}) : super(MonthlyReportsInitial()) {
    on<FetchMonthlyReports>((event, emit) async {
      if (event is FetchMonthlyReports) {
        emit(MonthlyReportsLoading());

        try {
          final reports = await repository.getMonthlyReports(
            corporateId: event.corporateId,
            employeeId: event.employeeId,
            month: event.month,
          );

          emit(MonthlyReportsLoaded(reports: reports));
        } catch (e) {
          emit(MonthlyReportsError(error: 'Failed to load daily reports: $e'));
        }
      }
    });
  }

  @override
  Stream<MonthlyReportsState> mapEventToState(MonthlyReportsEvent event) async* {
    // You don't need to add event handling logic here anymore,
    // as it's handled by the registered event handler using 'on'.
  }
}
