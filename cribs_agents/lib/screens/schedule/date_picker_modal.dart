import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:intl/intl.dart';
import '../../widgets/action_elevated_button.dart';

class DatePickerModal extends StatefulWidget {
  final DateTime initialDate;

  const DatePickerModal({super.key, required this.initialDate});

  @override
  State<DatePickerModal> createState() => _DatePickerModalState();
}

class _DatePickerModalState extends State<DatePickerModal> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: kRadius12),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 24.0,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select date',
              style: TextStyle(fontSize: 14, color: kPrimaryColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  DateFormat('E, MMM d').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.edit, color: kPrimaryColor, size: 20),
              ],
            ),
            const Divider(height: 20),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: kPrimaryColor,
                  onPrimary: kWhite,
                  onSurface: kBlack,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                onDateChanged: (newDate) {
                  setState(() {
                    _selectedDate = newDate;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kLightBlue.withValues(alpha: 0.5),
                borderRadius: kRadius8,
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: kPrimaryColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ensure to pick a date & time suitable for you',
                      style: TextStyle(fontSize: 12, color: kPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ActionElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selectedDate),
              text: 'Okay',
            ),
          ],
        ),
      ),
    );
  }
}
