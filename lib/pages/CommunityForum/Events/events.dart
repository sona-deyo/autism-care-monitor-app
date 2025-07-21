import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Events', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue[900],
          bottom: TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Parents'), Tab(text: 'Children & Parents')],
          ),
        ),
        body: TabBarView(
          children: [
            EventList(collection: 'parentEvents'),
            EventList(collection: 'childParentEvents'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEventDialog(context),
          child: Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.blue[900],
        ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String eventName = "";
        String eventVenue = "";
        String eventHost = "";
        String eventMode = "Online";
        String eventLink = "";
        bool isParentEvent = true;
        DateTime? selectedDate;
        TimeOfDay? selectedTime;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Event Name'),
                      onChanged: (value) => eventName = value,
                    ),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date & Day',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text:
                            selectedDate != null
                                ? DateFormat(
                                  'EEEE, MMM d, yyyy',
                                ).format(selectedDate!)
                                : '',
                      ),
                    ),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Time',
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      controller: TextEditingController(
                        text:
                            selectedTime != null
                                ? selectedTime!.format(context)
                                : '',
                      ),
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Event Host'),
                      onChanged: (value) => eventHost = value,
                    ),
                    DropdownButtonFormField<String>(
                      value: eventMode,
                      items:
                          ['Online', 'Offline']
                              .map(
                                (mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          eventMode = value!;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Mode of Event'),
                    ),
                    eventMode == 'Online'
                        ? TextField(
                          decoration: InputDecoration(labelText: 'Online Link'),
                          onChanged: (value) => eventLink = value,
                        )
                        : TextField(
                          decoration: InputDecoration(
                            labelText: 'Venue Details',
                          ),
                          onChanged: (value) => eventVenue = value,
                        ),
                    SwitchListTile(
                      title: Text("Is this a Parent Event?"),
                      value: isParentEvent,
                      onChanged: (value) {
                        setState(() {
                          isParentEvent = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (eventName.isNotEmpty &&
                        selectedDate != null &&
                        selectedTime != null) {
                      await FirebaseFirestore.instance
                          .collection(
                            isParentEvent
                                ? 'parentEvents'
                                : 'childParentEvents',
                          )
                          .add({
                            'name': eventName,
                            'date': DateFormat(
                              'EEEE, MMM d, yyyy',
                            ).format(selectedDate!),
                            'time': selectedTime!.format(context),
                            'venue':
                                eventMode == 'Online' ? eventLink : eventVenue,
                            'host': eventHost,
                            'mode': eventMode,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class EventList extends StatelessWidget {
  final String collection;
  final Color textColor;
  EventList({required this.collection, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection(collection)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var events = snapshot.data!.docs;

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            var event = events[index].data() as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: Icon(Icons.event, color: Colors.blue[900]),
                title: Text(
                  event['name'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 6),
                        Text(event['date']),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 18, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(event['time']),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Host: ${event['host']}'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          event['mode'] == 'Online'
                              ? Icons.link
                              : Icons.location_on,
                          size: 18,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            event['venue'],
                            style: TextStyle(color: Colors.blue),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
