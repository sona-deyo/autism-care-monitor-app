import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'new_task.dart';

class DailySchedule extends StatefulWidget {
  const DailySchedule({
    super.key,
    required String appName,
    required String appUserModelId,
    required String guid,
  });

  @override
  _DailyScheduleState createState() => _DailyScheduleState();
}

class _DailyScheduleState extends State<DailySchedule> {
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<dynamic>> _events = {};
  late String _userId;
  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadEvents();
  }

  void _getCurrentUser() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
    } else {
      _userId = '';
    }
  }

  Future<void> _addTask(
    String taskName,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final DateTime startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      startTime.hour,
      startTime.minute,
    );

    final DateTime endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      endTime.hour,
      endTime.minute,
    );

    await FirebaseFirestore.instance.collection('tasks').add({
      'taskName': taskName,
      'startTime': Timestamp.fromDate(startDateTime),
      'endTime': Timestamp.fromDate(endDateTime),
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'completed': false,
      'userId': _userId,
    });

    _loadEvents();
  }

  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
    _loadEvents();
  }

  Stream<QuerySnapshot> _getTasks() {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where(
          'date',
          isEqualTo: DateFormat('yyyy-MM-dd').format(_selectedDate),
        )
        .where('userId', isEqualTo: _userId)
        .snapshots();
  }

  Future<void> _loadEvents() async {
    try {
      final tasksSnapshot =
          await FirebaseFirestore.instance
              .collection('tasks')
              .where('userId', isEqualTo: _userId)
              .get();

      final Map<DateTime, List<dynamic>> tempEvents = {};
      for (var doc in tasksSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('date')) {
          DateTime date = DateFormat('yyyy-MM-dd').parse(data['date']);
          date = DateTime(date.year, date.month, date.day);
          tempEvents[date] = tempEvents[date] ?? [];
          tempEvents[date]!.add(data);
        }
      }

      setState(() {
        _events = tempEvents;
      });
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] != null && _events[normalizedDay]!.isNotEmpty
        ? [1]
        : [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Scheduler'),
        backgroundColor: Colors.blue[900],
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDate,
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _focusedDate = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.blue[900],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTasks(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No tasks for this date."));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!.docs;
                final sortedTasks = tasks.map((task) => task).toList();

                sortedTasks.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aTime = (aData['startTime'] as Timestamp).toDate();
                  final bTime = (bData['startTime'] as Timestamp).toDate();

                  return aTime.compareTo(bTime);
                });
                return ListView.builder(
                  itemCount: sortedTasks.length,
                  itemBuilder: (context, index) {
                    final task = sortedTasks[index];
                    final taskData = task.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(taskData['taskName']),
                      subtitle: Text(
                        "${DateFormat.jm().format(taskData['startTime'].toDate())} - ${DateFormat.jm().format(taskData['endTime'].toDate())}",
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color.fromARGB(255, 148, 36, 28),
                        ),
                        onPressed: () => _deleteTask(task.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () async {
          if (_userId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please log in to add tasks')),
            );
            return;
          }

          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => NewTask(
                    selectedDate: DateFormat(
                      'yyyy-MM-dd',
                    ).format(_selectedDate),
                  ),
            ),
          );
          if (result != null) {
            _addTask(result['name'], result['startTime'], result['endTime']);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
