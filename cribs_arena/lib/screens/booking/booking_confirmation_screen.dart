import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';
import 'package:intl/intl.dart';
import 'package:cribs_arena/screens/schedule/schedule_screen.dart';
import 'package:cribs_arena/screens/main_layout.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_arena/helpers/chat_helper.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final String agentName;
  final String agentImageUrl;
  final String? propertyImageUrl;
  final DateTime selectedDate;
  final String formattedTime;

  const BookingConfirmationScreen({
    super.key,
    required this.agentName,
    required this.agentImageUrl,
    this.propertyImageUrl,
    required this.selectedDate,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kWhite, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: (agentImageUrl.isNotEmpty)
                          ? NetworkImage(
                              ChatHelper.getFullImageUrl(agentImageUrl),
                            )
                          : const AssetImage(
                                  'assets/images/default_profile.jpg')
                              as ImageProvider,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You have successfully booked',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: kPrimaryColor.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                agentName,
                textAlign: TextAlign.center,
                style: kConfirmationTitleStyle,
              ),
              const SizedBox(height: 32),
              _buildStepper(),
              const SizedBox(height: 24),
              _buildBookingDetailsCard(context),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyScheduleScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kPrimaryColor),
                  minimumSize: const Size(double.infinity, kSizedBoxH48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'View Schedule',
                  style: GoogleFonts.roboto(
                    color: kPrimaryColor,
                    fontSize: kFontSize14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to home or my feed and clear the stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainLayout()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  minimumSize: const Size(double.infinity, kSizedBoxH48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Return to my feed',
                  style: GoogleFonts.roboto(
                    color: kWhite,
                    fontSize: kFontSize14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Column(
      children: [
        const Text(
          'Success',
          style: kConfirmationSubTitleStyle,
        ),
        const SizedBox(height: 16),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetailsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              image: DecorationImage(
                image: propertyImageUrl != null && propertyImageUrl!.isNotEmpty
                    ? NetworkImage(ChatHelper.getFullImageUrl(propertyImageUrl))
                        as ImageProvider
                    : const AssetImage('assets/images/property_skeleton.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyScheduleScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(
                    100), // Make it circular for the InkWell effect
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/calender.svg',
                    colorFilter:
                        const ColorFilter.mode(kWhite, BlendMode.srcIn),
                    height: 32,
                    width: 32,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(selectedDate),
                  style: kConfirmationDateStyle,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: kLightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      formattedTime,
                      style: kConfirmationTimeStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
