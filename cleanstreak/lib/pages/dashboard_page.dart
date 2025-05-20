import 'package:cleanstreak/widgets/calendar_utils.dart';
import 'package:cleanstreak/dialogs/add_chore.dart';
import 'package:cleanstreak/firestore_db/firebase_storage.dart';
import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/widgets/chore_container.dart';
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

  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  /// ************************************************************************************************
  /// Functions for Calendar                                                                          *
  /// ************************************************************************************************
  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    return kEvents[day] ?? [];
  }
  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
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
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOn;
        //displayEvent = true;
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
      //displayEvent = true;
    });

    // `start` or `end` could be null
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
  Widget _displayCalendarEvent(BuildContext context){
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
                    'Upcoming Deadlines/Events',
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
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
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
                                return AlertDialog(
                                  title: Text(
                                    '${value[index]}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  contentPadding: const EdgeInsets.all(24),
                                  content: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Description",
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "*Insert Event/Chore Description*",
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text(
                                        'Close',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            title: Text(
                              '${value[index]}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.primary,
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
    return Container(
      width: MediaQuery.of(context).size.width * 0.33, // 1/3 of screen width
      height: MediaQuery.of(context).size.height * 0.67, // 2/3 of screen height
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                  Icons.cleaning_services,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Master Chores List',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chores.length,
              itemBuilder: (context, index) {
                final chore = chores[index];
                return Dismissible(
                  key: Key(chore.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    _deleteChore(chore.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${chore.name} deleted')),
                    );
                  },
                  child: ChoreContainer(
                    chore: chore,
                    onSelect: (selectedChore) {
                      setState(() {
                        this.selectedChore = selectedChore;
                      });
                    },
                    onDelete: (chore) {
                      _deleteChore(chore.id);
                    },
                    onToggleComplete: (chore, isCompleted) {
                      _toggleCompletion(chore.id, isCompleted);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All Chores: ${chores.length}'),
                SizedBox(
                  width: 45, // Adjust button size
                  height: 45,
                  child: FloatingActionButton(
                    onPressed: () {
                      _showAddChoreDialog();
                    },
                    child: const Icon(
                      Icons.add,
                      size: 20, // Adjust icon size
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  /// ************************************************************************************************
  /// Displays Details of the selected Chore
  /// ************************************************************************************************
  Widget _displayChoreDetails() {
    if (selectedChore == null) return const SizedBox();

    return Container(
      width: 300,
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
              border: const Border(bottom: BorderSide(width: 1)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7.0),
                topRight: Radius.circular(7.0),
              ),
            ),
            child: Text(
              'Chore Details: ${selectedChore!.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4), // Add a small space
                Text(
                  selectedChore!.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Completion Status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text('Completed'),
                  value: selectedChore!.isCompleted,
                  onChanged: (bool? value) {
                    if (value != null && selectedChore != null) {
                      _toggleCompletion(selectedChore!.id, value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddChoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddChoreDialog(
          onChoreAdded: (String name, String description) {
            _addChore(name, description);
          },
        );
      },
    );
  }


  void _addChore(String name, String description) {
    Chore newChore = Chore(
      id: chores.length, 
      name: name, 
      description: description, 
      isCompleted: false
    );
    chores.add(newChore);
    setState(() {
      _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
      _saveChores();
    });
  }

  void _deleteChore(int id) {
    for (int i = 0; i < chores.length; i++) {
      if (chores[i].id == id) {
        if (selectedChore != null && selectedChore!.id == id) {
          selectedChore = null; // Clear the details panel
        }
        chores.removeAt(i);
        _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
        break;
      }
    }
    setState(() {
      _saveChores();
    });
  }


  void _toggleCompletion(int id, bool isCompleted) {
    setState(() {
      for (var chore in chores) {
        if (chore.id == id) {
          chore.isCompleted = isCompleted;
          break;
        }
      }
      _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
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
    List<Chore> loadedChores = await widget.storage.readChoreList();
    setState(() {
      chores = loadedChores;
      _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
    });
  }

  Future<void> _saveChores() async {
    await widget.storage.writeChoreList(chores);
  }

  @override
  void initState() {
    super.initState();
    _loadChores();
    _unfinishedChoresCount = chores.where((chore) => !chore.isCompleted).length;
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "This Week at a Glance",
                    style: TextStyle(
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _displayCalendar(),
                const SizedBox(height: 50),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _displayMasterChoresList(context),
                      _displayCalendarEvent(context),
                    ]
                  ),
                ),
              ]
            )
    );
  }
}
