import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'date_picker_modal.dart';
import 'time_picker_modal.dart';

class EditScheduleModal extends StatefulWidget {
  const EditScheduleModal({super.key});

  @override
  State<EditScheduleModal> createState() => _EditScheduleModalState();
}

class _EditScheduleModalState extends State<EditScheduleModal> {
  String _selectedInspectionType = 'House';
  final List<String> _inspectionTypes = [
    'House',
    'Land',
    'Commercial',
    'Apartment',
  ];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPaddingH24V32,
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: kRadius20Top,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDropdownRow(
            'Select Inspection type',
            _selectedInspectionType,
            _inspectionTypes,
          ),
          const SizedBox(height: 16),
          _buildSelectRow(
            SvgPicture.asset(
              'assets/icons/calender.svg',
              colorFilter: const ColorFilter.mode(kBlack54, BlendMode.srcIn),
              width: 24,
              height: 24,
            ),
            'Set Date',
            _selectedDate == null
                ? 'Select'
                : DateFormat('E, MMM d').format(_selectedDate!),
            onTap: () async {
              final pickedDate = await showDialog<DateTime>(
                context: context,
                builder: (context) => DatePickerModal(
                  initialDate: _selectedDate ?? DateTime.now(),
                ),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildSelectRow(
            const Icon(Icons.access_time_outlined, color: kBlack54),
            'Set Time',
            _selectedTime == null ? 'Select' : _selectedTime!.format(context),
            onTap: () async {
              final pickedTime = await showDialog<TimeOfDay>(
                context: context,
                builder: (context) => TimePickerModal(
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                ),
              );
              if (pickedTime != null) {
                setState(() {
                  _selectedTime = pickedTime;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kLightBlue,
                padding: kPaddingV16,
                shape: const RoundedRectangleBorder(borderRadius: kRadius30),
                elevation: 0,
              ),
              child: Text(
                'Schedule Appointment',
                style: GoogleFonts.roboto(
                  fontSize: kFontSize12,
                  fontWeight: FontWeight.w500,
                  color: kPrimaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16), // For bottom padding
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String title, String value, List<String> items) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.roboto(fontSize: kFontSize12, color: kBlack54),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedInspectionType = newValue;
            });
          }
        },
        items: items.map<DropdownMenuItem<String>>((String itemValue) {
          return DropdownMenuItem<String>(
            value: itemValue,
            child: Text(
              itemValue,
              style: GoogleFonts.roboto(
                fontSize: kFontSize12,
                color: kPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectRow(
    Widget icon,
    String title,
    String value, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: icon,
      title: Text(
        title,
        style: GoogleFonts.roboto(fontSize: kFontSize12, color: kBlack54),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.roboto(fontSize: kFontSize12, color: kBlack54),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16, color: kBlack54),
        ],
      ),
    );
  }
}
