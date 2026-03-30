import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';

class TimePickerWidget extends StatefulWidget {
  final Function(TimeOfDay) onTimeSelected;

  const TimePickerWidget({super.key, required this.onTimeSelected});

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  TimeOfDay? _selectedTime;
  final List<TimeOfDay> _timeSlots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
    const TimeOfDay(hour: 18, minute: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPaddingAll20,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kRadius24,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select time',
                    style: GoogleFonts.roboto(
                      color: kGrey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_selectedTime != null)
                    Text(
                      _selectedTime!.format(context),
                      style: GoogleFonts.roboto(
                        color: kPrimaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, color: kPrimaryColor),
              ),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final time = _timeSlots[index];
                final isSelected = _selectedTime == time;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTime = time;
                    });
                    widget.onTimeSelected(time);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? kLightBlue : kWhite,
                      borderRadius: kRadius12,
                    ),
                    child: Center(
                      child: Text(
                        time.format(context),
                        style: TextStyle(
                          color: isSelected ? kPrimaryColor : kBlack,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
