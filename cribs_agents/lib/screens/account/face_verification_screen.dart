import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class FaceVerificationScreen extends StatelessWidget {
  const FaceVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: const PrimaryAppBar(title: Text('FACE VERIFICATION')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kGrey300, width: 4),
              ),
              child: const CircleAvatar(
                radius: 80,
                backgroundImage: AssetImage('assets/images/agent1.jpg'),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Please position your face in the middle',
              style: GoogleFonts.roboto(fontSize: 16, color: kBlack),
            ),
            const SizedBox(height: 30),
            _buildVerificationStep('Smile', true),
            const SizedBox(height: 15),
            _buildVerificationStep('Blink', true),
            const SizedBox(height: 15),
            _buildVerificationStep('Turn head right', true),
            const SizedBox(height: 15),
            _buildVerificationStep('Turn head left', true),
            const Spacer(),
            PrimaryButton(
              text: 'Done',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationStep(String text, bool done) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        done
            ? SvgPicture.asset(
                'assets/icons/success.svg',
                height: 24,
                width: 24,
              )
            : const Icon(Icons.radio_button_unchecked, color: kGrey),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: kGrey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: GoogleFonts.roboto(fontSize: 14, color: kBlack),
          ),
        ),
      ],
    );
  }
}
