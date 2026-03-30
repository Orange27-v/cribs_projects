import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:intl/intl.dart';
import '../../widgets/action_elevated_button.dart';

class TimePickerModal extends StatefulWidget {
  final TimeOfDay initialTime;

  const TimePickerModal({super.key, required this.initialTime});

  @override
  State<TimePickerModal> createState() => _TimePickerModalState();
}

class _TimePickerModalState extends State<TimePickerModal> {
  late TimeOfDay _selectedTime;
  final List<TimeOfDay> _timeSlots = List.generate(
    11,
    (index) => TimeOfDay(hour: 8 + index, minute: 0),
  ); // 8 AM to 6 PM

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
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
              'Select time',
              style: TextStyle(fontSize: 14, color: kPrimaryColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  DateFormat('h:00 a').format(
                    DateTime(
                      2023,
                      1,
                      1,
                      _selectedTime.hour,
                      _selectedTime.minute,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.edit, color: kPrimaryColor, size: 20),
              ],
            ),
            const Divider(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final time = _timeSlots[index];
                final isSelected = time.hour == _selectedTime.hour;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTime = time;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? kLightBlue : kGrey100,
                      borderRadius: kRadius12,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat(
                        'h:00 a',
                      ).format(DateTime(2023, 1, 1, time.hour, time.minute)),
                      style: TextStyle(
                        color: isSelected ? kPrimaryColor : kBlack,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ActionElevatedButton(
              onPressed: () => Navigator.of(context).pop(_selectedTime),
              text: 'Okay',
            ),
          ],
        ),
      ),
    );
  }
}
