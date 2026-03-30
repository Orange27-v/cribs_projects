import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/onboarding_content.dart';
import 'widgets/onboarding_title.dart';
// import 'dart:io';

const kPrimaryColor = Color(0xFF006BC2);
const kPrimaryColorDark = Color(0xFF026DE3);
const kBlueAccent = Colors.blueAccent;
const kAmber = Colors.amber;
const kOrange = Colors.orange;
const kGreen = Colors.green;
const kRed = Colors.red;
const kError = kRed; // Added for consistency with SnackbarHelper
const kPrimary = kPrimaryColor; // Added for consistency with SnackbarHelper
const kBlue = Colors.blue;
const kCyan = Colors.cyan;
const kDarkBlue = Color(0xFF1976D2);

const kWhite = Colors.white;
const kBlack = Colors.black;
const kBlack54 = Colors.black54;
const kBlack87 = Colors.black87;
const kGrey = Colors.grey;
const kGrey100 = Color(0xFFF5F5F5);
const kGrey200 = Color(0xFFEEEEEE);
const kGrey300 = Color(0xFFE0E0E0);
const kGrey400 = Color(0xFFBDBDBD);
const kGrey500 = Color(0xFF9E9E9E);
const kGrey600 = Color(0xFF757575);
const kGrey700 = Color(0xFF616161);
const kGrey800 = Color(0xFF424242);
const kGrey900 = Color.fromARGB(255, 71, 71, 71);
const kBorderGrey = Color(0xFFE0E0E0);

// --- API Base URLs ---
// String get _localHost {
//   if (Platform.isAndroid) {
//     return '10.0.2.2';
//   }
//   return '127.0.0.1';
// }

// String get kChatBaseUrl => 'http://$_localHost:5001';
// String get kBaseUrl => 'http://$_localHost:8000/api';
// String get kUserBaseUrl => 'http://$_localHost:8000/api/user';
// String get kAgentBaseUrl => 'http://$_localHost:8000/api/agent';
// String get kMainBaseUrl => 'http://$_localHost:8000/';

const kChatBaseUrl = 'https://node-k8.cribsarena.com';
const String kBaseUrl = 'https://api-n9.cribsarena.com/api';
const String kUserBaseUrl = 'https://api-n9.cribsarena.com/api/user';
const String kAgentBaseUrl = 'https://api-n9.cribsarena.com/api/agent';
const String kMainBaseUrl = 'https://api-n9.cribsarena.com/';

// --- API Keys & Secrets (Public Keys are fine, true secrets should be in backend/environment variables) ---
const String nairaSymbol = '\u{20A6}';
const String kAuthTokenKey = 'auth_token';
const String kPendingFCMTokenKey = 'pending_fcm_token';

const kLightPurple = Color(0xFFEDE4FF);
const kLightBlue = Color(0xFFC8F1FF);
const kLightCyan = Color(0xFFE0F7FA);

const kSelectedTileColor = Color(0xFFE3F0FB);
const kBookingButtonColor = Color(0xFF0077B6);
const kOtpResendColor = Color(0xFF0066CC);
const kCircleBg = Color(0xFFFFFFFF);
const kMapBackgroundColor = Color(0xFFF0F0F0);
const kConversationBackgroundColor = Color(0xFFF8F9FA);

const kDarkTextColor = Color(0xFF0F172A);
const kDarkGreyText = Color(0xFF4A4A4A);
const kLightGrey = Color(0xFFD1D1D1);

const kBlue50 = Color(0xFFE3F2FD);
const kBlue600 = Color(0xFF2196F3);
const kBlue700 = Color(0xFF007AFF);
const kOrange50 = Color(0xFFFFF3E0);
const kOrange600 = Color(0xFFFB8C00);
const kGreen50 = Color(0xFFE8F5E9);
const kGreen600 = Color(0xFF43A047);
const kPurple50 = Color(0xFFF3E5F5);
const kPurple600 = Color(0xFF8E24AA);
const kTeal50 = Color(0xFFE0F2F1);
const kTeal600 = Color(0xFF00897B);
const kRed50 = Color(0xFFFFEBEE);
const kRed600 = Color(0xFFE53935);
const kRed700 = Color(0xFFD93025);
const kDeepPurple = Colors.deepPurple;

const kBlackOpacity08 = Color(0xCC000000);
const kBlackOpacity01 = Color(0x1A000000);
const kGrey100Opacity06 = Color(0x99F5F5F5);
const kGreyOpacity02 = Color(0x339E9E9E);
const kGreyOpacity03 = Color(0x4D9E9E9E);
const kGreyOpacity015 = Color(0x269E9E9E);
const kGreyOpacity006 = Color(0x0F9E9E9E);
const kBlackOpacity015 = Color(0x25000000);
const kPrimaryColorOpacity005 = Color(0x0D006BC2);
const kBlackOpacity005 = Color(0x0D000000);
const kPrimaryColorOpacity02 = Color(0x33006BC2);
const kWhiteOpacity01 = Color(0x1AFFFFFF);
const kWhiteOpacity005 = Color(0x0DFFFFFF);
const kLightBlueOpacity05 = Color(0x80C8F1FF);
const kPrimaryColorOpacity08 = Color(0xCC006BC2);
const kPrimaryColorOpacity03 = Color(0x4D006BC2);
const kBlackOpacity07 = Color(0xB3000000);
const kGreyOpacity01 = Color(0x1A9E9E9E);
const kGreyOpacity05 = Color(0x809E9E9E);
const kGrey100Opacity09 = Color(0xE6F5F5F5);
const kBlackOpacity001 = Color(0x03000000);
const kBlackOpacity04 = Color(0x66000000);
const kPrimaryColorOpacity01 = Color(0x1A006BC2);
const kBlackOpacity03 = Color(0x4D000000);
const kGrey100Opacity05 = Color(0x80F5F5F5);
const kBlackOpacity065 = Color(0xA6000000);
const kBlackOpacity045 = Color(0x73000000);
const kPrimaryColorOpacity06 = Color(0x99006BC2);
const kWhiteOpacity08 = Color(0xCCFFFFFF);
const kWhiteOpacity09 = Color(0xE6FFFFFF);
const kWhiteOpacity03 = Color(0x4DFFFFFF);
const kBlackOpacity06 = Color.fromRGBO(0, 0, 0, 0.06);
const kBlack12 = Color(0x1F000000);
const kBlack26 = Color(0x42000000);

const kMaxSliderValue = 100.0;

// Sizing
const double kSizedBoxH0 = 0.0;
const double kSizedBoxH1 = 1.0;
const double kSizedBoxH1_4 = 1.4;
const double kSizedBoxH2 = 2.0;
const double kSizedBoxH3 = 3.0;
const double kSizedBoxH4 = 4.0;
const double kSizedBoxH6 = 6.0;
const double kSizedBoxH8 = 8.0;
const double kSizedBoxH10 = 10.0;
const double kSizedBoxH12 = 12.0;
const double kSizedBoxH14 = 14.0;
const double kSizedBoxH16 = 16.0;
const double kSizedBoxH20 = 20.0;
const double kSizedBoxH24 = 24.0;
const double kSizedBoxH28 = 28.0;
const double kSizedBoxH30 = 30.0;
const double kSizedBoxH32 = 32.0;
const double kSizedBoxH35 = 35.0;
const double kSizedBoxH36 = 36.0;
const double kSizedBoxH40 = 40.0;
const double kSizedBoxH48 = 48.0;
const double kSizedBoxH50 = 50.0;
const double kSizedBoxH56 = 56.0;
const double kSizedBoxH60 = 60.0;
const double kSizedBoxH70 = 70.0;
const double kSizedBoxH80 = 80.0;
const double kSizedBoxH90 = 90.0;
const double kSizedBoxH100 = 100.0;
const double kSizedBoxH120 = 120.0;
const double kSizedBoxH150 = 150.0;
const double kSizedBoxH180 = 180.0;
const double kSizedBoxH240 = 240.0;
const double kSizedBoxH250 = 250.0;

const double kSizedBoxW0 = 0.0;
const double kSizedBoxW2 = 2.0;
const double kSizedBoxW4 = 4.0;
const double kSizedBoxW5 = 5.0;
const double kSizedBoxW6 = 6.0;
const double kSizedBoxW8 = 8.0;
const double kSizedBoxW10 = 10.0;
const double kSizedBoxW12 = 12.0;
const double kSizedBoxW14 = 14.0;
const double kSizedBoxW16 = 16.0;
const double kSizedBoxW20 = 20.0;
const double kSizedBoxW28 = 28.0;
const double kSizedBoxW32 = 32.0;
const double kSizedBoxW35 = 35.0;
const double kSizedBoxW36 = 36.0;
const double kSizedBoxW40 = 40.0;
const double kSizedBoxW50 = 50.0;
const double kSizedBoxW56 = 56.0;
const double kSizedBoxW80 = 80.0;
const double kSizedBoxW100 = 100.0;
const double kSizedBoxW180 = 180.0;
const double kSizedBoxW420 = 420.0;

const double kSize12 = 12.0;
const double kSize24 = 24.0;
const double kSize60 = 60.0;

// Font Sizes
const double kFontSize4 = 4.0;
const double kFontSize6 = 6.0;
const double kFontSize8 = 8.0;
const double kFontSize10 = 10.0;
const double kFontSize11 = 11.0;
const double kFontSize12 = 12.0;
const double kFontSize13 = 13.0;
const double kFontSize14 = 14.0;
const double kFontSize15 = 15.0;
const double kFontSize16 = 16.0;
const double kFontSize18 = 18.0;
const double kFontSize20 = 20.0;
const double kFontSize22 = 22.0;
const double kFontSize24 = 24.0;
const double kFontSize28 = 28.0;
const double kFontSize32 = 32.0;
const double kFontSize40 = 40.0;

// Icon Sizes
const double kIconSize10 = 10.0;
const double kIconSize12 = 12.0;
const double kIconSize14 = 14.0;
const double kIconSize16 = 16.0;
const double kIconSize18 = 18.0;
const double kIconSize20 = 20.0;
const double kIconSize22 = 22.0;
const double kIconSize24 = 24.0;
const double kIconSize25 = 25.0;
const double kIconSize32 = 32.0;
const double kIconSize40 = 40.0;
const double kIconSize80 = 80.0;

// Radii
const kRadius2 = BorderRadius.all(Radius.circular(2));
const kRadius4 = BorderRadius.all(Radius.circular(4));
const kRadius8 = BorderRadius.all(Radius.circular(8));
const kRadius10 = BorderRadius.all(Radius.circular(10));
const kRadius12 = BorderRadius.all(Radius.circular(12));
const kRadius14 = BorderRadius.all(Radius.circular(14));
const kRadius16 = BorderRadius.all(Radius.circular(16));
const kRadius20 = BorderRadius.all(Radius.circular(20));
const kRadius24 = BorderRadius.all(Radius.circular(24));
const kRadius25 = BorderRadius.all(Radius.circular(25));
const kRadius27 = 27.0;
const kRadius28 = BorderRadius.all(Radius.circular(28));
const kRadius30 = BorderRadius.all(Radius.circular(30));
const double kRadiusDouble30 = 30.0;
const kRadius32 = BorderRadius.all(Radius.circular(32));
const kRadius35 = 35.0;
const kRadius15Top = BorderRadius.only(
    topLeft: Radius.circular(15), topRight: Radius.circular(15));
const kRadius16Bottom = BorderRadius.only(
    bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16));
const kRadius20Bottom = BorderRadius.vertical(bottom: Radius.circular(20));
const kRadius20Top = BorderRadius.only(
    topLeft: Radius.circular(20), topRight: Radius.circular(20));

//Elevations
const double kElevation0 = 0.0;
const double kElevation05 = 0.5;
const double kElevation8 = 8.0;
const double kElevation12 = 12.0;

// Offsets
const Offset kOffset01 = Offset(0, 1);
const Offset kOffset02 = Offset(0, 2);
const Offset kOffset04 = Offset(0, 4);
const Offset kOffset015 = Offset(0, 15);
const Offset kOffset0Neg2 = Offset(0, -2);

// Blur Radii
const double kBlurRadius3 = 3.0;
const double kBlurRadius4 = 4.0;
const double kBlurRadius6 = 6.0;
const double kBlurRadius8 = 8.0;
const double kBlurRadius10 = 10.0;
const double kBlurRadius16 = 16.0;
const double kBlurRadius30 = 30.0;

// Stroke Widths
const double kStrokeWidth1_5 = 1.5;
const double kStrokeWidth2 = 2.0;
const double kStrokeWidth3 = 3.0;

// Layout & Animation Multipliers
const double kMapHeightMultiplier = 0.3;
const double kAspectRatio16_9 = 16 / 9;
const double kPropertyCardItemHeightMultiplier = 1.5;
const double kPropertyCardImageHeightMultiplier = 0.58;
const double kScaleAnimationEnd095 = 0.95;
const double kPulseAnimationEnd = 1.1;
const double kPopupScaleBegin = 0.7;
const double kPopupOpacityBegin = 0.0;
const double kCloseButtonScaleEnd = 0.9;
const double kInitialChildSize07 = 0.7;
const double kMaxChildSize095 = 0.95;
const double kMinChildSize05 = 0.5;
const double kMinHeight07 = 0.7;
const double kMaxHeight09 = 0.9;
const double kMaxWidth075 = 0.75;
const double kMaxWidth08 = 0.8;
const double kMaxWidth085 = 0.85;
const double kMaxWidth09 = 0.9;
const double kMinWidth18 = 18.0;
const double kMinHeight18 = 18.0;
const double kMinWidth250 = 250.0;
const double kMinHeight200 = 200.0;

// Map & Positioning
const double kAndroidMinMapHeight = 250.0;
const double kIOSMinMapHeight = 200.0;
const int kMaxRetries = 5;
const int kAndroidInitialPositioningDelay = 1200;
const int kIOSInitialPositioningDelay = 600;
const int kAndroidCameraAnimationDelay = 800;
const int kIOSCameraAnimationDelay = 300;
const int kAndroidSecondUpdateDelay = 200;
const int kRetryTimerMultiplier = 1000;
const double kAndroidMapPadding = 120.0;
const double kIOSMapPadding = 80.0;

// Platform-specific zoom levels
const double kInitialMapZoomIOS = 12.0;
const double kInitialMapZoomAndroid = 14.0; // Higher zoom for Android
const double kFixedZoomLevelIOS = 15.0;
const double kFixedZoomLevelAndroid = 17.0; // Higher zoom for Android
const double kDefaultUserLocationZoom =
    15.0; // Default zoom when centering on user location

// Map Search & Nearby
const double kDefaultSearchRadius = 50.0; // Default search radius in kilometers
const Duration kMarkerDisplayDelay = Duration(milliseconds: 300);
const Duration kApiTimeout = Duration(seconds: 30);

// --- PADDINGS & MARGINS ---
const kPaddingZero = EdgeInsets.zero;
const kPaddingAll4 = EdgeInsets.all(4);
const kPaddingAll5 = EdgeInsets.all(5);
const kPaddingAll6 = EdgeInsets.all(6);
const kPaddingAll7 = EdgeInsets.all(7);
const kPaddingAll8 = EdgeInsets.all(8);
const kPaddingAll12 = EdgeInsets.all(12);
const kPaddingAll14 = EdgeInsets.all(14);
const kPaddingAll16 = EdgeInsets.all(16);
const kPaddingAll20 = EdgeInsets.all(20);
const kPaddingAll24 = EdgeInsets.all(24);
const kPaddingAll32 = EdgeInsets.all(32);

const kPaddingH8 = EdgeInsets.symmetric(horizontal: 8.0);
const kPaddingH10 = EdgeInsets.symmetric(horizontal: 10);
const kPaddingH12 = EdgeInsets.symmetric(horizontal: 12);
const kPaddingH14 = EdgeInsets.symmetric(horizontal: 14.0);
const kPaddingH16 = EdgeInsets.symmetric(horizontal: 16);
const kPaddingH20 = EdgeInsets.symmetric(horizontal: 20);
const kPaddingH32 = EdgeInsets.symmetric(horizontal: 32.0);

const kPaddingV3 = EdgeInsets.symmetric(vertical: 3);
const kPaddingV4 = EdgeInsets.symmetric(vertical: 4.0);
const kPaddingV5 = EdgeInsets.symmetric(vertical: 5);
const kPaddingV10 = EdgeInsets.symmetric(vertical: 10);
const kPaddingV12 = EdgeInsets.symmetric(vertical: 12);
const kPaddingV14 = EdgeInsets.symmetric(vertical: 14);
const kPaddingV15 = EdgeInsets.symmetric(vertical: 15);
const kPaddingV16 = EdgeInsets.symmetric(vertical: 16);

const kPaddingH2V2 = EdgeInsets.symmetric(horizontal: 2, vertical: 2);
const kPaddingH4V8 = EdgeInsets.symmetric(horizontal: 4, vertical: 8);
const kPaddingH6V2 = EdgeInsets.symmetric(horizontal: 6, vertical: 2);
const kPaddingH8V0 = EdgeInsets.symmetric(horizontal: 8, vertical: 0);
const kPaddingH8V4 = EdgeInsets.symmetric(horizontal: 8, vertical: 4);
const kPaddingH8V12 = EdgeInsets.symmetric(horizontal: 8, vertical: 12);
const kPaddingH10V2 = EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0);
const kPaddingH10V4 = EdgeInsets.symmetric(horizontal: 10, vertical: 4);
const kPaddingH10V5 = EdgeInsets.symmetric(horizontal: 10, vertical: 5);
const kPaddingH12V6 = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
const kPaddingH12V8 = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
const kPaddingH12V12 = EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0);
const kPaddingH16V6 = EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0);
const kPaddingH16V8 = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
const kPaddingH16V10 = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
const kPaddingH16V12 = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
const kPaddingH20V0 = EdgeInsets.symmetric(horizontal: 20, vertical: 0);
const kPaddingH20V12 = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
const kPaddingH20V14 = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
const kPaddingH24V16 = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);
const kPaddingH24V32 = EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0);
const kPaddingH30V15 = EdgeInsets.symmetric(horizontal: 30, vertical: 15);

const kPaddingOnlyTop4 = EdgeInsets.only(top: 4);
const kPaddingOnlyTop6 = EdgeInsets.only(top: 6);
const kPaddingOnlyTop8 = EdgeInsets.only(top: 8);
const kPaddingOnlyBottom10 = EdgeInsets.only(bottom: 10);
const kPaddingOnlyBottom16 = EdgeInsets.only(bottom: 16.0);
const kPaddingOnlyBottom40 = EdgeInsets.only(bottom: 40);
const kPaddingOnlyBottom100 = EdgeInsets.only(bottom: 100);
const kPaddingOnlyLeft4 = EdgeInsets.only(left: 4);
const kPaddingOnlyRight12 = EdgeInsets.only(right: 12);
const kPaddingOnlyRight16 = EdgeInsets.only(right: 16);
const kPaddingOnlyLeft16Bottom8 = EdgeInsets.only(left: 16.0, bottom: 8.0);
const kPaddingOnlyBottom10H10 =
    EdgeInsets.only(bottom: 10, left: 10, right: 10);
const kPaddingOnlyLeftRight4Bottom10Top5 =
    EdgeInsets.only(left: 4, right: 4, bottom: 10, top: 5);

const kPaddingFromLTRB8_16_16_8 = EdgeInsets.fromLTRB(8, 16, 16, 8);
const kPaddingFromLTRB16_8_16_16 = EdgeInsets.fromLTRB(16, 8, 16, 16);
const kPaddingFromLTRB16_16_16_8 = EdgeInsets.fromLTRB(16, 16, 16, 8);
const kPaddingFromLTRB16_16_16_12 = EdgeInsets.fromLTRB(16, 16, 16, 12);

const double kPaddingTopNeg2 = -2.0;
const double kPaddingRightNeg2 = -2.0;
const double kPaddingBottom2 = 2.0;
const kPaddingOnlyBottom2 = EdgeInsets.only(bottom: 2);
const double kPaddingRight8 = 8.0;
const double kBottomNeg5 = -5.0;
const double kRightNeg5 = -5.0;
const double kTopNeg10 = -10.0;
const double kTopNeg15 = -15.0;
const double kRightNeg15 = -15.0;

// --- DURATIONS ---
const kDuration150ms = Duration(milliseconds: 150);
const kDuration200ms = Duration(milliseconds: 200);
const kDuration300ms = Duration(milliseconds: 300);
const kDuration1500ms = Duration(milliseconds: 1500);
const kDuration2s = Duration(seconds: 2);
const kDuration15s =
    Duration(milliseconds: 15); // This seems like a typo, maybe 1.5s or 15s?

// --- TEXT STYLES ---

// Const TextStyles
final TextStyle kAuthBodyTextStyle =
    GoogleFonts.roboto(fontSize: 14, color: Colors.black87);
final TextStyle kOtpResendTextStyle =
    GoogleFonts.roboto(color: Color(0xFF0066CC), fontWeight: FontWeight.bold);
final TextStyle kAppBarTextStyle =
    GoogleFonts.roboto(color: kPrimaryColor, fontSize: 12);
final TextStyle kBookingTitleStyle = GoogleFonts.roboto(
    color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold);
final TextStyle kBookingSubTitleStyle = GoogleFonts.roboto(
    color: kPrimaryColor, fontSize: 18, fontWeight: FontWeight.w500);
final TextStyle kPayButtonTextStyle = GoogleFonts.roboto(
    color: kWhite, fontWeight: FontWeight.bold, fontSize: 16);
final TextStyle kConfirmationTitleStyle = GoogleFonts.roboto(
    color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold);
final TextStyle kConfirmationSubTitleStyle = GoogleFonts.roboto(
    color: kPrimaryColor, fontSize: 18, fontWeight: FontWeight.w500);
final TextStyle kConfirmationDateStyle = GoogleFonts.roboto(
    color: kPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold);
final TextStyle kConfirmationTimeStyle = GoogleFonts.roboto(
    color: kPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold);
final TextStyle kReturnToFeedButtonStyle = GoogleFonts.roboto(
    color: kWhite, fontSize: 16, fontWeight: FontWeight.bold);
final TextStyle kCalendarTitleStyle = GoogleFonts.roboto(
    color: kPrimaryColor, fontSize: 22, fontWeight: FontWeight.bold);
final TextStyle kCalendarSubTitleStyle =
    GoogleFonts.roboto(color: kGrey, fontSize: 14);
final TextStyle kCalendarInfoTextStyle =
    GoogleFonts.roboto(color: kPrimaryColor, fontSize: 10);
final TextStyle kContinueButtonTextStyle = GoogleFonts.roboto(
    color: kWhite, fontSize: 16, fontWeight: FontWeight.bold);
final TextStyle kPrimaryColorBoldDefaultTextStyle =
    GoogleFonts.roboto(color: kPrimaryColor, fontWeight: FontWeight.bold);
final TextStyle kDialogTitleStyle = GoogleFonts.roboto(
    fontSize: 22, fontWeight: FontWeight.bold, color: kBlack);

// Final (Google Fonts) TextStyles
final kTitleStyle = GoogleFonts.roboto(
    fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.5);
final kSubtitleStyle = GoogleFonts.roboto(
    fontSize: 16, color: kBlack54, fontWeight: FontWeight.w500);
final kDialogButtonTextStyle = GoogleFonts.roboto(
    fontSize: 17, fontWeight: FontWeight.w500, color: kWhite);
final kAuthHeaderTitleStyle = GoogleFonts.roboto(
    fontSize: 16.0, fontWeight: FontWeight.w500, color: kDarkTextColor);
final kAuthTextButtonStyle = GoogleFonts.roboto(
    color: kPrimaryColor, fontWeight: FontWeight.w500, fontSize: 12);
final kSocialButtonTextStyle =
    GoogleFonts.roboto(fontSize: 16, color: kBlack87);
final kDisclaimerTextStyle =
    GoogleFonts.roboto(fontSize: 12, color: kBlueAccent);
final kAreaSubtitleTextStyle =
    GoogleFonts.roboto(fontSize: 14, color: kBlack54);
final kOnboardingDescriptionStyle =
    GoogleFonts.roboto(fontSize: 15, color: kBlack87);

final kNairaSymbolTextStyle = GoogleFonts.roboto(
    fontSize: kFontSize10, color: kPrimaryColor, fontWeight: FontWeight.w500);

// --- DECORATIONS ---

// Input Decorations
final InputDecoration kPhoneFieldInputDecoration = InputDecoration(
  labelText: kSignupPhoneNumberLabel,
  labelStyle: GoogleFonts.roboto(
      color: kBlack54, fontSize: 16, fontWeight: FontWeight.w500),
  hintText: 'Phone Number',
  hintStyle: GoogleFonts.roboto(color: kGrey400, fontSize: 16),
  border: OutlineInputBorder(
      borderRadius: kRadius16,
      borderSide: BorderSide(color: kPrimaryColor, width: 1.5)),
  enabledBorder: OutlineInputBorder(
      borderRadius: kRadius16,
      borderSide: BorderSide(color: kGrey300, width: 1.5)),
  focusedBorder: OutlineInputBorder(
      borderRadius: kRadius16,
      borderSide: BorderSide(color: kPrimaryColor, width: 2.0)),
  errorBorder: OutlineInputBorder(
      borderRadius: kRadius16, borderSide: BorderSide(color: kRed, width: 1.5)),
  focusedErrorBorder: OutlineInputBorder(
      borderRadius: kRadius16, borderSide: BorderSide(color: kRed, width: 2.0)),
  contentPadding: EdgeInsets.only(top: 18, bottom: 18, left: 180, right: 10),
  filled: true,
  fillColor: kWhite,
  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
);

// Box Decorations
const BoxDecoration kPhoneFieldDropdownDecoration = BoxDecoration(
  color: kBlue50,
  borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
  border: Border.fromBorderSide(BorderSide(color: kGrey300, width: 1.5)),
);

// Box Shadows
const kCircleBoxShadow = [
  BoxShadow(color: Color(0x09050404), blurRadius: 30, offset: Offset(20, 22)),
];

// --- ASSET PATHS ---
const kAgent1ImagePath = 'assets/images/default_profile.jpg';
const kMapSearchIconPath = 'assets/icons/map_search.svg';
const kNotificationIconPath = 'assets/icons/notification.svg';
const kCalendarIconPath = 'assets/icons/calender.svg';
const kLocationIconPath = 'assets/images/location_icon.png';

// --- TEXT STRINGS ---

// General UI
const kAppNameText = 'Cribs Arena';
const kAppLocationText = 'Lekki, Lagos NG';
const kBackText = 'Back';
const kContinueText = 'Continue';
const kOrText = 'OR';
const kSearchText = 'Search';
const kMyFeedText = 'My Feed';
const kSeeAllText = 'see all';
const kReadMoreText = 'Read more';

// Auth & Onboarding
const kSignInText = 'Sign In';
const kSignUpText = 'Sign Up';
const kSignOutText = 'Sign out';
const kAllowText = 'Allow';
const kDontAllowText = "Don't Allow";
const kProcessingDataText = 'Processing Data';
const kSmsSentText = 'SMS sent';
const kLoginEmailPhoneHint = 'Email or Phone';
const kLoginPasswordHint = 'Password';
const kSignupFirstNameHint = 'First Name';
const kSignupLastNameHint = 'Last Name';
const kSignupPhoneNumberLabel = 'Phone Number';
const kSignupSelectAreaHint = 'Select Area';
const kSignupVerifiableEmailHint = 'Email Address';
const kSignupPasswordHint = 'Password';
const kRegisterWithEmailText = 'Register with Email';
const kContinueWithGoogleText = 'Continue with Google';
const kContinueWithAppleText = 'Continue with Apple';
const kContinueWithFacebookText = 'Continue with Facebook';
const kLoginDisclaimerText =
    'By continuing, you agree to our Terms of Service and Privacy Policy';
const kEnterEmailPhoneError = 'Please enter your email or phone number';
const kEnterPasswordError = 'Please enter your password';
const kPasswordLengthError = 'Password must be at least 6 characters long';
const kSignupFillAllFieldsError = 'Please fill all fields';
const kFindAgentsNearMeText = 'Find Agents Near Me';

// Area Selection
const kSelectAreaText = 'Select Area';
const kSelectYourAreaTitle = 'Select Your Area';
const kSearchAreaHint = 'Search Area';
const kSearchAreaExampleHint = 'e.g., Victoria Island';

// Property & Search
const kSearchHintText = 'Location, City, Property, Agent name';
const kSearchPropertyHint = 'Search property';
const kPropertyText = 'Property';
const kPriceRangeText = 'Price Range';
const kBedroomCountText = 'Bedroom Count';
const kBathroomCountText = 'Bathroom Count';
const kFurnishingStatusText = 'Furnishing Status';
const kBuyingText = 'Buying';
const kRentingText = 'Renting';
const kZeroText = '0';
const kFiveText = '5';
const kTenPlusText = '10+';
const kNewListingsTitle = 'NEW LISTING';
const kRecommendedPropertiesTitle = 'RECOMMENDED PROPERTIES';
const kAvailablePropertiesTitle = 'Available properties from Oghenetejiri';
const kNoPropertiesFoundText = 'No Properties Found';
const kAdjustSearchCriteriaText = 'Try adjusting your search criteria.';
const kPropertyListedByText = 'Oghenetejiri Okiemute listed this property';
const kTimeAgoText = '17 minutes ago';
const kOwnerText = 'Owner';
const kPropertyTitleText = 'Duplex, Lekki Phase 1';
const kPropertyPriceText = '₦85,500,000';
const kPropertyDescriptionTitleText =
    'Elegant 4-Bedroom Duplex for Sale in Lekki Phase 1\nWhere Luxury Meets Lifestyle';
const kPropertyDescriptionText =
    'Discover a stunning blend of modern architecture and serene living in this beautifully finished 4-bedroom duplex nestled in the heart of Lekki Phase 1 – one of Lagos\'s most prestigious neighborhoods.';
const kBookInspectionText = 'Book Inspection';
const kSeeOtherPropertiesText = 'See other properties from this Agent';

// Agent & Chat
const kLicensedAgentText = 'Licensed Agent';
const kLagosNigeriaLocationText = 'Lagos, Nigeria';
const kViewAgentProfileText = 'View Agent Profile';
const kFlagUserText = 'Flag User';
const kTypeAMessageText = 'Type a message...';
const kNoConversationsText = 'No conversations yet';
const kConnectAgentsText =
    'Connect with agents to start chatting about properties';
const kFindAgentsNearYouText = 'Find agents near you';
const kChatTitleText = 'CHAT';
const kRecentConversationsText = 'Recent conversations';
const kSuperstarAgentText = 'Superstar Agent';
const kLocationNotAvailableText = 'Location not available';
const kChatText = 'Chat';
const kCloseToYouText = 'Close to you';
const kDistance800mText = '800m';
const kFemaleText = 'Female';
const k5YrsExpText = '5 yrs Exp';
const kSearchingText = 'Searching...';

// Profile & Settings
const kProfileTitleText = 'PROFILE';
const kNotificationCountText = '3';
const kProfileNameText = 'Eric Undisputed';
const kProfileEmailText = 'eric.undisputed99@gmail.com';
const kProfileMemberSinceText = 'Member since August 2025';
const kAccountSectionTitle = 'ACCOUNT';
const kSettingsSectionTitle = 'SETTINGS';
const kSupportFeedbackSectionTitle = 'SUPPORT & FEEDBACK';
const kLegalSectionTitle = 'LEGAL';
const kEditProfileText = 'Edit Profile';
const kChangePasswordText = 'Change Password';
const kPrivacySecurityText = 'Privacy & Security';
const kSearchPreferencesText = 'Search preferences';
const kNotificationSettingsText = 'Notification settings';
const kLocationSettingsText = 'Location settings';
const kHelpFAQText = 'Help and FAQ';
const kCustomerSupportText = 'Customer support';
const kRateOurAppText = 'Rate our app';
const kPrivacyPolicyText = 'Privacy Policy';

const kTermsOfServiceText = 'Terms of Service'; // Added this, was missing

// All Agents Screen
const kAllAgentsTitle = 'ALL AGENTS';
const kSearchAgentHint = 'Search agents';

// Attachments
const kSendAttachmentText = 'Send attachment';
const kCameraText = 'Camera';
const kGalleryText = 'Gallery';
const kDocumentText = 'Document';

// --- MISCELLANEOUS ---

// --- MISCELLANEOUS ---
const kChatTabIndex = 2;
const List<double> kGradientStops = [0.5, 1.0];

// --- DUMMY DATA ---
// Sample agents data - you would typically load this from an API or database
// --- DUMMY DATA ---
// Sample agents data - you would typically load this from an API or database
final List<Map<String, dynamic>> agents = [
  {
    'id': '1',
    'name': 'Sarah Johnson',
    'image': 'assets/images/default_profile.jpg',
    'lat': 6.5244,
    'lon': 3.3792,
    'count': 6,
    'isActive': true,
    'isOnline': true,
    'location': 'Victoria Island, Lagos',
  },
  {
    'id': '2',
    'name': 'Michael Chen',
    'image': 'assets/images/agent2.jpg',
    'lat': 6.5261,
    'lon': 3.3748,
    'count': 4,
    'isActive': false,
    'isOnline': true,
    'location': 'Lekki Phase 1, Lagos',
  },
  {
    'id': '3',
    'name': 'Amina Abdullahi',
    'image': 'assets/images/agent3.jpg',
    'lat': 6.5287,
    'lon': 3.3825,
    'count': 6,
    'isActive': true,
    'isOnline': false,
    'location': 'Oniru, Lagos',
  },
  {
    'id': '4',
    'name': 'David Okafor',
    'image': 'assets/images/agent4.jpg',
    'lat': 6.5229,
    'lon': 3.3760,
    'count': 2,
    'isActive': false,
    'isOnline': true,
    'location': 'Ikoyi, Lagos',
  },
  {
    'id': '5',
    'name': 'Grace Adebayo',
    'image': 'assets/images/agent5.jpg',
    'lat': 6.5215,
    'lon': 3.3841,
    'count': 8,
    'isActive': true,
    'isOnline': true,
    'location': 'Obalende, Lagos',
  },
];

LinearGradient kEarningsCardGradient(double goalProgress) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      kPrimaryColor,
      Color.lerp(kPrimaryColor, kLightBlue, goalProgress)!,
    ],
    stops: [0.0, goalProgress],
  );
}

// Onboarding Contents
List<OnboardingContent> contents = [
  OnboardingContent(
    title: const OnboardingTitle(
      title: 'MAP YOUR',
      subtitle: 'CLIENTS',
    ),
    image: 'assets/images/agents_glass_2.png',
    description:
        'Pin your properties, get messages from serious potential tenants & buyers',
  ),
  OnboardingContent(
    title: const OnboardingTitle(
      title: 'BUILD YOUR',
      subtitle: 'EMPIRE',
    ),
    image: 'assets/images/agents_glass_1.png',
    description:
        'CribsArena connects you to more clients, more inspections, and more income.',
  )
];
