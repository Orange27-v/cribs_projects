import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cribs_arena/constants.dart';
import 'package:intl/intl.dart';

class CalendarWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const CalendarWidget({super.key, required this.onDateSelected});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallDevice = screenHeight < 700;

    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kRadius24,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select date',
                        style: kCalendarSubTitleStyle,
                      ),
                      const SizedBox(height: 4),
                      if (_selectedDay != null)
                        Text(
                          DateFormat('EEE, MMM d').format(_selectedDay!),
                          style: kCalendarTitleStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, color: kPrimaryColor),
                ),
              ],
            ),

            Divider(height: isSmallDevice ? 16 : 32),

            /// Calendar
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.now(),
              lastDay: DateTime.utc(2100, 12, 31),
              rowHeight: isSmallDevice ? 38 : 52,
              daysOfWeekHeight: isSmallDevice ? 20 : 32,
              sixWeekMonthsEnforced: false,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                widget.onDateSelected(selectedDay);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              enabledDayPredicate: (day) {
                return !day
                    .isBefore(DateTime.now().subtract(const Duration(days: 1)));
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: const Icon(Icons.chevron_left),
                rightChevronIcon: const Icon(Icons.chevron_right),
                headerPadding: const EdgeInsets.symmetric(vertical: 0),
                titleTextFormatter: (date, locale) =>
                    DateFormat.yMMMM(locale).format(date),
                titleTextStyle: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                cellMargin: const EdgeInsets.all(4),
                defaultTextStyle: const TextStyle(fontSize: 14),
                weekendTextStyle: const TextStyle(fontSize: 14),
              ),
            ),

            SizedBox(height: isSmallDevice ? 8 : 16),

            /// Info Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kPrimaryColorOpacity005,
                borderRadius: kRadius12,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: kPrimaryColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ensure to pick a date & time suitable for you',
                      style: kCalendarInfoTextStyle.copyWith(
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
