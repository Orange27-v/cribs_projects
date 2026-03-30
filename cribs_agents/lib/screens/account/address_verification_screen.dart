import 'package:flutter/material.dart';

import 'package:cribs_agents/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class AddressVerificationScreen extends StatelessWidget {
  const AddressVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(title: Text('ADDRESS VERIFICATION')),
      body: Padding(
        padding: kPaddingAll16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Image of NEPA bill',
              style: GoogleFonts.roboto(
                fontSize: kFontSize16,
                fontWeight: FontWeight.w500,
                color: kBlack,
              ),
            ),
            const SizedBox(height: kSizedBoxH16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: kGrey100,
                borderRadius: kRadius12,
                border: Border.all(color: kGrey300),
              ),
              child: const Center(
                child: Icon(Icons.cloud_upload, size: 48, color: kGrey),
              ),
            ),
            const SizedBox(height: kSizedBoxH16),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: kPrimaryColor,
                  size: kIconSize16,
                ),
                const SizedBox(width: kSizedBoxW8),
                Expanded(
                  child: Text(
                    'This must not be later than 3 months and this might take 2-3 working days to be confirmed',
                    style: GoogleFonts.roboto(
                      fontSize: kFontSize12,
                      color: kGrey,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Done',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: kSizedBoxH20),
          ],
        ),
      ),
    );
  }
}
