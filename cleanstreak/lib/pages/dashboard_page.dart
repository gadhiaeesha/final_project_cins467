import 'package:cleanstreak/widgets/calendar_utils.dart';
import 'package:cleanstreak/dialogs/add_chore.dart';
import 'package:cleanstreak/firestore_db/firebase_storage.dart';
import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/widgets/calendar_widget.dart';
import 'package:cleanstreak/widgets/chore_display_widgets.dart';
import 'package:cleanstreak/services/chore_management.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  final FirebaseAuthService auth;
  final ChoreStorage storage = ChoreStorage();
  
  DashboardPage({super.key, required this.auth});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Chore> chores = [];
  Chore? selectedChore;
  int _unfinishedChoresCount = 0;
  late ChoreManagement _choreManagement;

  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  /// ************************************************************************************************
  /// Functions for Calendar                                                                          *
  /// ************************************************************************************************
  List<Event> _getEventsForDay(DateTime day) {
    // Filter chores that have a completeBy date matching the given day
    final choresForDay = chores.where((chore) {
      if (chore.completeBy == null) return false;
      return isSameDay(chore.completeBy!, day);
    }).toList();

    // Convert chores to events, including completion status in the title
    return choresForDay.map((chore) => Event(
      '${chore.name} ${chore.isCompleted ? '(Completed)' : '(Pending)'}'
    )).toList();
  }
  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOn;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }
  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }
  
  /// ************************************************************************************************
  /// Displays Calendar for Home Page                                                                *
  /// ************************************************************************************************
  Widget _displayCalendar(){
    return TableCalendar<Event>(
      firstDay: kFirstDay,
      lastDay: kLastDay,
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      calendarFormat: _calendarFormat,
      rangeSelectionMode: _rangeSelectionMode,
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(
        // Use `CalendarStyle` to customize the UI
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
      onDaySelected: _onDaySelected,
      onRangeSelected: _onRangeSelected,
      onFormatChanged: (format) {
        if (_calendarFormat != format) {
          setState(() {
            _calendarFormat = format;
          });
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
    );
  }

  /// ************************************************************************************************
  /// Displays Events/Deadlines                                                                      *
  /// ************************************************************************************************
  Widget _displayCalendarEvent(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 3,
      height: MediaQuery.of(context).size.height / 2,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chores for Selected Date',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  if (value.isEmpty) {
                    return Center(
                      child: Text(
                        'No chores scheduled for this date',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      final event = value[index];
                      final choreName = event.title.replaceAll(RegExp(r'\s*\(Completed\)|\s*\(Pending\)'), '');
                      final chore = chores.firstWhere(
                        (c) => c.name == choreName,
                        orElse: () => Chore(
                          id: -1,
                          name: choreName,
                          description: 'Chore not found',
                          isCompleted: false,
                          completeBy: null,
                          completionDate: null,
                        ),
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          onTap: () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                insetPadding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 24,
                                ),
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primaryContainer,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.task_alt,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                chore.name,
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.description,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Description",
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  chore.description,
                                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.task_alt,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Completion Status",
                                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: chore.isCompleted
                                                      ? Theme.of(context).colorScheme.primaryContainer
                                                      : Theme.of(context).colorScheme.errorContainer,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: chore.isCompleted
                                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                                        : Theme.of(context).colorScheme.error.withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      chore.isCompleted
                                                          ? Icons.check_circle
                                                          : Icons.pending,
                                                      color: chore.isCompleted
                                                          ? Theme.of(context).colorScheme.primary
                                                          : Theme.of(context).colorScheme.error,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      chore.isCompleted ? "Completed" : "Not Completed",
                                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                            color: chore.isCompleted
                                                                ? Theme.of(context).colorScheme.primary
                                                                : Theme.of(context).colorScheme.error,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                          border: Border(
                                            top: BorderSide(
                                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => Navigator.of(context).pop(),
                                              icon: Icon(
                                                Icons.close,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              label: Text(
                                                'Close',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          title: Text(
                            chore.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: chore.isCompleted
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  chore.isCompleted ? Icons.check_circle : Icons.pending,
                                  size: 16,
                                  color: chore.isCompleted
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  chore.isCompleted ? "Completed" : "Pending",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: chore.isCompleted
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ************************************************************************************************
  /// Displays Master List of Chores
  /// ************************************************************************************************
  Widget _displayMasterChoresList(BuildContext context) {
    return const SizedBox();
  }

  /// ************************************************************************************************
  /// Displays Details of the selected Chore
  /// ************************************************************************************************
  Widget _displayChoreDetails() {
    return const SizedBox();
  }

  void _showAddChoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddChoreDialog(
          onChoreAdded: (String name, String description, DateTime? completeBy) {
            _addChore(name, description, completeBy);
          },
        );
      },
    );
  }

  void _addChore(String name, String description, DateTime? completeBy) {
    Chore newChore = _choreManagement.addChore(name, description, completeBy, chores);
    setState(() {
      chores.add(newChore);
      _unfinishedChoresCount = _choreManagement.getUnfinishedChoresCount(chores);
      _saveChores();
    });
  }

  void _deleteChore(int id) {
    setState(() {
      _choreManagement.deleteChore(id, chores);
      if (selectedChore != null && selectedChore!.id == id) {
        selectedChore = null;
      }
      _unfinishedChoresCount = _choreManagement.getUnfinishedChoresCount(chores);
      _saveChores();
    });
  }

  void _toggleCompletion(int id, bool isCompleted) {
    setState(() {
      _choreManagement.toggleCompletion(id, isCompleted, chores);
      _unfinishedChoresCount = _choreManagement.getUnfinishedChoresCount(chores);
      _saveChores();
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Dashboard',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          tooltip: 'Sign Out',
          onPressed: () async {
            await widget.auth.signOut();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _loadChores() async {
    List<Chore> loadedChores = await _choreManagement.loadChores();
    setState(() {
      chores = loadedChores;
      _unfinishedChoresCount = _choreManagement.getUnfinishedChoresCount(chores);
    });
  }

  Future<void> _saveChores() async {
    await _choreManagement.saveChores(chores);
  }

  @override
  void initState() {
    super.initState();
    _choreManagement = ChoreManagement(widget.storage);
    _loadChores();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CalendarWidget(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    rangeStart: _rangeStart,
                    rangeEnd: _rangeEnd,
                    calendarFormat: _calendarFormat,
                    rangeSelectionMode: _rangeSelectionMode,
                    chores: chores,
                    onDaySelected: _onDaySelected,
                    onRangeSelected: _onRangeSelected,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: MasterChoresListWidget(
                            chores: chores,
                            selectedChore: selectedChore,
                            onSelect: (chore) {
                              setState(() {
                                selectedChore = chore;
                              });
                            },
                            onDelete: (chore) {
                              _deleteChore(chore.id);
                            },
                            onToggleComplete: (chore, isCompleted) {
                              _toggleCompletion(chore.id, isCompleted);
                            },
                            onAddChore: () {
                              _showAddChoreDialog();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _displayCalendarEvent(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedChore != null)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ChoreDetailsWidget(
                  selectedChore: selectedChore!,
                  onToggleComplete: (id, isCompleted) {
                    _toggleCompletion(id, isCompleted);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
