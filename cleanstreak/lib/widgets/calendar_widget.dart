import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/widgets/calendar_utils.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final CalendarFormat calendarFormat;
  final RangeSelectionMode rangeSelectionMode;
  final List<Chore> chores;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime?, DateTime?, DateTime) onRangeSelected;
  final Function(CalendarFormat) onFormatChanged;

  const CalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.rangeStart,
    required this.rangeEnd,
    required this.calendarFormat,
    required this.rangeSelectionMode,
    required this.chores,
    required this.onDaySelected,
    required this.onRangeSelected,
    required this.onFormatChanged,
  });

  List<Event> _getEventsForDay(DateTime day) {
    final choresForDay = chores.where((chore) {
      if (chore.completeBy == null) return false;
      return isSameDay(chore.completeBy!, day);
    }).toList();

    return choresForDay.map((chore) => Event(
      '${chore.name} ${chore.isCompleted ? '(Completed)' : '(Pending)'}'
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar<Event>(
      firstDay: kFirstDay,
      lastDay: kLastDay,
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      rangeStartDay: rangeStart,
      rangeEndDay: rangeEnd,
      calendarFormat: calendarFormat,
      rangeSelectionMode: rangeSelectionMode,
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendTextStyle: TextStyle(color: Colors.red[300]),
        holidayTextStyle: TextStyle(color: Colors.red[300]),
        defaultTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        formatButtonShowsNext: false,
        formatButtonDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16.0),
        ),
        formatButtonTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        titleCentered: true,
        titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: Theme.of(context).colorScheme.primary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onDaySelected: onDaySelected,
      onRangeSelected: onRangeSelected,
      onFormatChanged: onFormatChanged,
      onPageChanged: (focusedDay) {
        // Handle page change if needed
      },
    );
  }
} 