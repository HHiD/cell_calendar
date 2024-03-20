import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'calendar_event.dart';
import 'components/days_of_the_week.dart';
import 'components/days_row/days_row.dart';
import 'components/month_year_label.dart';
import 'controllers/cell_calendar_page_controller.dart';
import 'date_extension.dart';

typedef DaysBuilder = Widget Function(int dayIndex);

typedef MonthYearBuilder = Widget Function(DateTime? visibleDateTime);

final currentDateProvider = StateProvider((ref) => DateTime.now());

/// Calendar widget like a Google Calendar
///
/// Expected to be used in full screen
class CellCalendar extends HookConsumerWidget {
  final bool showMonthyearLabel;
  CellCalendar({
    this.cellCalendarPageController,
    this.events = const [],
    this.onPageChanged,
    this.onCellTapped,
    required this.selectedDate,
    this.selectedDayColor = Colors.blue,
    this.todayMarkColor = Colors.blue,
    this.todayTextColor = Colors.white,
    this.daysOfTheWeekBuilder,
    this.monthYearLabelBuilder,
    this.dateTextStyle,
    this.showMonthyearLabel = false,
  });

  final CellCalendarPageController? cellCalendarPageController;

  /// Builder to show days of the week labels
  ///
  /// 0 for Sunday, 6 for Saturday.
  /// By default, it returns English labels
  final DaysBuilder? daysOfTheWeekBuilder;

  final MonthYearBuilder? monthYearLabelBuilder;

  final TextStyle? dateTextStyle;

  final List<CalendarEvent> events;
  final void Function(DateTime firstDate, DateTime lastDate)? onPageChanged;
  final void Function(DateTime)? onCellTapped;
  final DateTime selectedDate;
  final Color selectedDayColor;
  final Color todayMarkColor;
  final Color todayTextColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      child: _CalendarPageView(
        cellCalendarPageController: cellCalendarPageController,
        daysOfTheWeekBuilder: daysOfTheWeekBuilder,
        monthYearLabelBuilder: monthYearLabelBuilder,
        dateTextStyle: dateTextStyle,
        events: events,
        selectedDate: selectedDate,
        onPageChanged: onPageChanged,
        onCellTapped: onCellTapped,
        selectedDayColor: selectedDayColor,
        todayMarkColor: todayMarkColor,
        todayTextColor: todayTextColor,
        showMonthYearLabel: this.showMonthyearLabel,
      ),
    );
  }
}

class _CalendarPageView extends HookConsumerWidget {
  const _CalendarPageView({
    Key? key,
    required this.cellCalendarPageController,
    required this.daysOfTheWeekBuilder,
    required this.monthYearLabelBuilder,
    required this.dateTextStyle,
    required this.events,
    required this.onPageChanged,
    required this.onCellTapped,
    required this.selectedDate,
    required this.selectedDayColor,
    required this.todayMarkColor,
    required this.todayTextColor,
    required this.showMonthYearLabel,
  }) : super(key: key);
  final CellCalendarPageController? cellCalendarPageController;

  /// Builder to show days of the week labels
  ///
  /// 0 for Sunday, 6 for Saturday.
  /// By default, it returns English labels
  final DaysBuilder? daysOfTheWeekBuilder;

  final MonthYearBuilder? monthYearLabelBuilder;

  final TextStyle? dateTextStyle;

  final List<CalendarEvent> events;
  final void Function(DateTime firstDate, DateTime lastDate)? onPageChanged;
  final void Function(DateTime)? onCellTapped;
  final DateTime selectedDate;
  final Color selectedDayColor;
  final Color todayMarkColor;
  final Color todayTextColor;
  final bool showMonthYearLabel;

  DateTime _getFirstDay(DateTime dateTime) {
    final firstDayOfTheMonth = DateTime(dateTime.year, dateTime.month, 1);
    return firstDayOfTheMonth.add(firstDayOfTheMonth.weekday.daysDuration);
  }

  DateTime getLastDayOfMonth(int year, int month) {
    // Get the first day of the next month
    DateTime firstDayOfNextMonth = DateTime(year, month + 1, 1);
    // Subtract one day from the first day of the next month
    // to get the last day of the current month
    return firstDayOfNextMonth.subtract(Duration(days: 1));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        this.showMonthYearLabel
            ? MonthYearLabel(monthYearLabelBuilder)
            : SizedBox.shrink(),
        Expanded(
          child: PageView.builder(
            scrollDirection: Axis.vertical,
            controller:
                cellCalendarPageController ?? CellCalendarPageController(),
            itemBuilder: (context, index) {
              return _CalendarPage(
                selectedDate: this.selectedDate,
                visiblePageDate: index.visibleDateTime,
                daysOfTheWeekBuilder: daysOfTheWeekBuilder,
                dateTextStyle: dateTextStyle,
                onCellTapped: onCellTapped,
                selectedDayColor: selectedDayColor,
                todayMarkColor: todayMarkColor,
                todayTextColor: todayTextColor,
                events: events,
              );
            },
            onPageChanged: (index) {
              ref.read(currentDateProvider.notifier).state =
                  index.visibleDateTime;
              final currentDateTime = ref.read(currentDateProvider);
              if (onPageChanged != null) {
                onPageChanged!(
                  currentDateTime,
                  getLastDayOfMonth(
                      currentDateTime.year, currentDateTime.month),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Page of [_CalendarPage]
///
/// Wrapped with [CalendarMonthController]
class _CalendarPage extends StatelessWidget {
  const _CalendarPage({
    Key? key,
    required this.visiblePageDate,
    required this.selectedDate,
    required this.daysOfTheWeekBuilder,
    required this.dateTextStyle,
    required this.onCellTapped,
    required this.selectedDayColor,
    required this.todayMarkColor,
    required this.todayTextColor,
    required this.events,
  }) : super(key: key);

  final DateTime visiblePageDate;
  final DateTime selectedDate;
  final DaysBuilder? daysOfTheWeekBuilder;
  final TextStyle? dateTextStyle;
  final void Function(DateTime)? onCellTapped;
  final Color selectedDayColor;
  final Color todayMarkColor;
  final Color todayTextColor;
  final List<CalendarEvent> events;

  List<DateTime> _getCurrentDays(DateTime dateTime) {
    final List<DateTime> result = [];
    final firstDay = _getFirstDay(dateTime);
    result.add(firstDay);
    for (int i = 0; i + 1 < 42; i++) {
      result.add(firstDay.add(Duration(days: i + 1)));
    }
    return result;
  }

  DateTime _getFirstDay(DateTime dateTime) {
    final firstDayOfTheMonth = DateTime(dateTime.year, dateTime.month, 1);
    return firstDayOfTheMonth.add(firstDayOfTheMonth.weekday.daysDuration);
  }

  @override
  Widget build(BuildContext context) {
    final days = _getCurrentDays(visiblePageDate);
    return Column(
      children: [
        DaysOfTheWeek(daysOfTheWeekBuilder),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              6,
              (index) {
                return DaysRow(
                  visiblePageDate: visiblePageDate,
                  dates: days.getRange(index * 7, (index + 1) * 7).toList(),
                  selectedDate: selectedDate,
                  dateTextStyle: dateTextStyle,
                  onCellTapped: onCellTapped,
                  selectedDayColor: selectedDayColor,
                  todayMarkColor: todayMarkColor,
                  todayTextColor: todayTextColor,
                  events: events,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
