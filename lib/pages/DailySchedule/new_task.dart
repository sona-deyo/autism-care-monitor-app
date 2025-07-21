import 'package:flutter/material.dart';

class NewTask extends StatefulWidget {
  final String selectedDate;
  const NewTask({super.key, required this.selectedDate});

  @override
  _NewTaskState createState() => _NewTaskState();
}

class _NewTaskState extends State<NewTask> {
  final TextEditingController _taskNameController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _pickTime(bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  void _saveTask() {
    if (_taskNameController.text.isNotEmpty &&
        _startTime != null &&
        _endTime != null) {
      Navigator.pop(context, {
        'name': _taskNameController.text,
        'startTime': _startTime,
        'endTime': _endTime,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(labelText: 'Task Name'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => _pickTime(true),
                  child: Text(
                    _startTime == null
                        ? 'Select Start Time'
                        : _startTime!.format(context),
                  ),
                ),
                const SizedBox(width: 50),
                TextButton(
                  onPressed: () => _pickTime(false),
                  child: Text(
                    _endTime == null
                        ? 'Select End Time'
                        : _endTime!.format(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTask,
              child: const Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }
}
