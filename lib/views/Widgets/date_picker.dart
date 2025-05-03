import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerInput extends StatefulWidget {
  final String labelText;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime?>? onDateChanged;
  final bool isRequired;

  const DatePickerInput({
    super.key,
    required this.labelText,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.onDateChanged,
    this.isRequired = false,
  });

  @override
  State<DatePickerInput> createState() => _DatePickerInputState();
}

class _DatePickerInputState extends State<DatePickerInput> {
  late TextEditingController _controller;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Clamp the initial date to be within firstDate and lastDate
    if (widget.initialDate != null) {
      if (widget.initialDate!.isBefore(widget.firstDate)) {
        _selectedDate = widget.firstDate;
      } else if (widget.initialDate!.isAfter(widget.lastDate)) {
        _selectedDate = widget.lastDate;
      } else {
        _selectedDate = widget.initialDate;
      }
    }
    _controller = TextEditingController(
      text: _selectedDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controller.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      });
      if (widget.onDateChanged != null) {
        widget.onDateChanged!(_selectedDate);
      }
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _controller.text = '';
    });
    if (widget.onDateChanged != null) {
      widget.onDateChanged!(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true, // Prevents manual text input
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: 'e.g., 30/04/2025',
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
        ),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: _selectedDate != null
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _clearDate,
        )
            : null,
      ),
      validator: widget.isRequired
          ? (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date';
        }
        return null;
      }
          : null,
    );
  }
}