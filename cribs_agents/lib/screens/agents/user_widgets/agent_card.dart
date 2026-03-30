import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';

import '../../../models/agent.dart';
import '../../../constants.dart';

class AgentCard extends StatelessWidget {
  final Agent agent;
  final VoidCallback? onChatPressed; // Optional callback for chat action

  const AgentCard({
    super.key,
    required this.agent,
    this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: kPaddingAll16,
      decoration: const BoxDecoration(
        color: kLightCyan,
        borderRadius: kRadius16,
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: kRadius35,
                backgroundImage: AssetImage(agent.imageUrl),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: kSizedBoxW12,
                  height: kSizedBoxH12,
                  decoration: BoxDecoration(
                    color: kGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: kWhite, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: kSizedBoxH12),
          Text(
            agent.name,
            style: GoogleFonts.roboto(
              fontSize: kFontSize18,
              fontWeight: FontWeight.w500,
              color: kPrimaryColorDark,
            ),
          ),
          const SizedBox(height: kSizedBoxH2),
          const Text(
            'Licensed Agent',
            style: TextStyle(
              fontSize: kFontSize12,
              color: kDarkTextColor,
            ),
          ),
          const SizedBox(height: kSizedBoxH8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HeroIcon(
                HeroIcons.star,
                style: HeroIconStyle.solid,
                color: kPrimaryColorDark,
                size: kIconSize18,
              ),
              const SizedBox(width: kSizedBoxW4),
              Text(
                agent.rating.toString(),
                style: GoogleFonts.roboto(
                  fontSize: kFontSize14,
                  fontWeight: FontWeight.bold,
                  color: kDarkTextColor,
                ),
              ),
              const SizedBox(width: kSizedBoxW4),
              Flexible(
                child: Text(
                  '• ${agent.reviews} reviews',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: kFontSize12,
                    color: kPrimaryColorDark,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onChatPressed ??
                () {
                  // Default action - you can customize this or leave empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Chat with ${agent.name}'),
                      duration: kDuration2s,
                    ),
                  );
                },
            child: Container(
              width: kSizedBoxW50,
              height: kSizedBoxH50,
              decoration: const BoxDecoration(
                color: kWhite,
                shape: BoxShape.circle,
              ),
              child: const HeroIcon(
                HeroIcons.chatBubbleLeft,
                color: kPrimaryColorDark,
                size: kIconSize25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
