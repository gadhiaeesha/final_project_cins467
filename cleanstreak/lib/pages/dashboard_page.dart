import 'package:cleanstreak/widgets/calendar_utils.dart';
import 'package:cleanstreak/dialogs/add_chore.dart';
import 'package:cleanstreak/dialogs/welcome_dialog.dart';
import 'package:cleanstreak/firestore_db/chore_storage.dart';
import 'package:cleanstreak/firestore_db/member_storage.dart';
import 'package:cleanstreak/firestore_db/household_storage.dart';
import 'package:cleanstreak/models/chore.dart';
import 'package:cleanstreak/models/household.dart';
import 'package:cleanstreak/models/member.dart';
import 'package:cleanstreak/models/invite.dart';
import 'package:cleanstreak/widgets/calendar_widget.dart';
import 'package:cleanstreak/widgets/chore_display_widgets.dart';
import 'package:cleanstreak/services/chore_management.dart';
import 'package:cleanstreak/services/invite_management.dart';
import 'package:cleanstreak/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  final FirebaseAuthService auth;
  final ChoreStorage storage = ChoreStorage();
  final MemberStorage memberStorage = MemberStorage();
  
  DashboardPage({super.key, required this.auth});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ChoreManagement _choreManagement = ChoreManagement(ChoreStorage());
  final HouseholdStorage _householdStorage = HouseholdStorage();
  final MemberStorage _memberStorage = MemberStorage();
  final InviteManagement _inviteManagement = InviteManagement();
  Household? _currentHousehold;
  bool _isLoading = false;
  bool _isInboxOpen = false;
  final GlobalKey _inboxButtonKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Member? _currentMember;
  List<Invite> _pendingInvites = [];

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
    final choresForDay = _choreManagement.chores.where((chore) {
      if (chore.completeBy == null) return false;
      return isSameDay(chore.completeBy!, day);
    }).toList();

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
                      final chore = _choreManagement.chores.firstWhere(
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
                          onTap: () => _showChoreDetailsDialog(context, chore),
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
  
  void _showAddChoreDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddChoreDialog(
          onChoreAdded: (String name, String description, DateTime? completeBy) {
            _choreManagement.addChore(name, description, completeBy);
          },
        );
      },
    );
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
        IconButton(
          key: _inboxButtonKey,
          icon: Stack(
            children: [
              Icon(
                Icons.inbox,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              if (_pendingInvites.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_pendingInvites.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Inbox',
          onPressed: () {
            setState(() {
              _isInboxOpen = !_isInboxOpen;
            });
          },
        ),
        Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.home_work,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            tooltip: 'Household Management',
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Text(
              _currentMember?.name ?? FirebaseAuth.instance.currentUser?.email ?? '',
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

  void _showInboxOverlay() {
    if (!_isInboxOpen) return;

    final RenderBox buttonBox = _inboxButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset buttonPosition = buttonBox.localToGlobal(Offset.zero);
    final Size buttonSize = buttonBox.size;

    final OverlayState overlayState = Overlay.of(context);
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isInboxOpen = false;
                });
                _overlayEntry?.remove();
                _overlayEntry = null;
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            top: buttonPosition.dy + buttonSize.height,
            right: MediaQuery.of(context).size.width - buttonPosition.dx - buttonSize.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 300,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                            Icons.inbox,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Inbox',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: _pendingInvites.isEmpty
                          ? Center(
                              child: Text(
                                'No invites yet',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _pendingInvites.length,
                              itemBuilder: (context, index) {
                                final invite = _pendingInvites[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                      child: Icon(
                                        Icons.home_work,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    title: Text(
                                      'Household Invite',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    subtitle: Text(
                                      'You have been invited to join a household',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.check,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          onPressed: () => _acceptInvite(invite),
                                          tooltip: 'Accept',
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                          onPressed: () => _declineInvite(invite),
                                          tooltip: 'Decline',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadMemberData();
    _checkAndShowWelcomeDialog();
    _loadUserHousehold();
    _loadPendingInvites();
  }

  Future<void> _loadMemberData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final member = await widget.memberStorage.getMember(user.uid);
      if (mounted) {
        setState(() {
          _currentMember = member;
        });
      }
    }
  }

  Future<void> _checkAndShowWelcomeDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final member = await widget.memberStorage.getMember(user.uid);
      if (member != null && (member.name == null || member.name!.isEmpty)) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WelcomeDialog(
              userId: user.uid,
              email: user.email!,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadUserHousehold() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Get the member's profile
        final member = await _memberStorage.getMember(currentUser.uid);
        if (member != null) {
          // Set the current user ID in ChoreManagement
          _choreManagement.setCurrentUserId(currentUser.uid);
          
          if (member.householdId != null) {
            // Get the household using the member's householdId
            final household = await _householdStorage.getHousehold(member.householdId!);
            if (household != null) {
              setState(() {
                _currentHousehold = household;
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading household: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPendingInvites() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final invites = await _inviteManagement.getPendingInvites(currentUser.uid);
        if (mounted) {
          setState(() {
            _pendingInvites = invites;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading invites: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _acceptInvite(Invite invite) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _inviteManagement.acceptInvite(invite.id!, currentUser.uid);
      
      // Reload invites and household data
      await _loadPendingInvites();
      await _loadUserHousehold();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invite accepted! You are now part of the household.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting invite: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _declineInvite(Invite invite) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await _inviteManagement.declineInvite(invite.id!, currentUser.uid);
      
      // Reload invites
      await _loadPendingInvites();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invite declined.'),
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining invite: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInboxOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInboxOverlay();
      });
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      endDrawer: const HouseholdDrawer(),
      body: ListenableBuilder(
        listenable: _choreManagement,
        builder: (context, _) {
          return Stack(
            children: [
              Padding(
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
                      chores: _choreManagement.chores,
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
                              chores: _choreManagement.chores,
                              selectedChore: _choreManagement.selectedChore,
                              onSelect: (chore) {
                                _showChoreDetailsDialog(context, chore);
                              },
                              onDelete: (chore) {
                                _choreManagement.deleteChore(chore.id);
                              },
                              onToggleComplete: (chore, isCompleted) {
                                _choreManagement.toggleCompletion(chore.id, isCompleted);
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
            ],
          );
        },
      ),
    );
  }

  void _showChoreDetailsDialog(BuildContext context, Chore chore) {
    showDialog(
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
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}
