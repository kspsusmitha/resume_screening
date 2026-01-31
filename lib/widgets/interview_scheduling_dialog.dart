import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InterviewSchedulingDialog extends StatefulWidget {
  final String candidateName;
  final Function({
    required DateTime interviewDate,
    required String interviewTime,
    required String interviewerName,
    required String interviewLocation,
    String? interviewNotes,
  }) onSchedule;

  const InterviewSchedulingDialog({
    super.key,
    required this.candidateName,
    required this.onSchedule,
  });

  @override
  State<InterviewSchedulingDialog> createState() => _InterviewSchedulingDialogState();
}

class _InterviewSchedulingDialogState extends State<InterviewSchedulingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _interviewerNameController = TextEditingController();
  final _interviewLocationController = TextEditingController();
  final _interviewTimeController = TextEditingController();
  final _interviewNotesController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _interviewerNameController.dispose();
    _interviewLocationController.dispose();
    _interviewTimeController.dispose();
    _interviewNotesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _interviewTimeController.text = picked.format(context);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select interview date')),
        );
        return;
      }
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select interview time')),
        );
        return;
      }

      widget.onSchedule(
        interviewDate: _selectedDate!,
        interviewTime: _interviewTimeController.text,
        interviewerName: _interviewerNameController.text.trim(),
        interviewLocation: _interviewLocationController.text.trim(),
        interviewNotes: _interviewNotesController.text.trim().isEmpty
            ? null
            : _interviewNotesController.text.trim(),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Schedule Interview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Candidate: ${widget.candidateName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              // Interview Date
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _selectedDate != null
                      ? DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate!)
                      : '',
                ),
                decoration: InputDecoration(
                  labelText: 'Interview Date *',
                  hintText: 'Select date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Please select interview date';
                  }
                  return null;
                },
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              // Interview Time
              TextFormField(
                readOnly: true,
                controller: _interviewTimeController,
                decoration: InputDecoration(
                  labelText: 'Interview Time *',
                  hintText: 'Select time',
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () => _selectTime(context),
                  ),
                ),
                validator: (value) {
                  if (_selectedTime == null) {
                    return 'Please select interview time';
                  }
                  return null;
                },
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 16),
              // Interviewer Name
              TextFormField(
                controller: _interviewerNameController,
                decoration: const InputDecoration(
                  labelText: 'Interviewer Name *',
                  hintText: 'e.g., John Doe (Senior Developer)',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter interviewer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Interview Location
              TextFormField(
                controller: _interviewLocationController,
                decoration: const InputDecoration(
                  labelText: 'Location/Meeting Link *',
                  hintText: 'Office address or Zoom/Meet link',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter interview location or meeting link';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Interview Notes
              TextFormField(
                controller: _interviewNotesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any special instructions for the candidate',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send),
          label: const Text('Schedule Interview'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
