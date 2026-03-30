import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cribs_agents/provider/agent_provider.dart';
import 'package:cribs_agents/screens/chat/chat_list_screen.dart';
import 'package:cribs_agents/screens/notification/notification_screen.dart';
import 'package:cribs_agents/screens/chat/conversation.dart';
import 'package:cribs_agents/screens/transactions/transaction_details_screen.dart';
import 'package:cribs_agents/screens/schedule/schedule_screen.dart';
import 'package:cribs_agents/main.dart' as app_main;

class App extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  const App({super.key, this.navigatorKey});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AgentProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            navigatorKey: widget.navigatorKey,
            navigatorObservers: [app_main.routeObserver],
            title: 'Cribs Agents',
            debugShowCheckedModeBanner: true,
            theme: ThemeData(
              primarySwatch: Colors.indigo,
              scaffoldBackgroundColor: kGrey100,
              fontFamily: GoogleFonts.roboto().fontFamily,
              textTheme: GoogleFonts.robotoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            home: const SplashScreen(),
            routes: {
              '/chat-list': (context) => const ChatListScreen(),
              '/notifications': (context) => const NotificationScreen(),
              '/wallet': (context) =>
                  const NotificationScreen(), // Fallback for now
              '/inspections': (context) => const MyScheduleScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/chat') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => ConversationScreen(
                    conversationId: args['conversationId']?.toString() ?? '',
                    otherParticipantId:
                        args['otherParticipantId']?.toString() ??
                            args['senderId']?.toString() ??
                            '',
                    participantName: args['participantName']?.toString() ??
                        args['senderName']?.toString() ??
                        'User',
                    participantImageUrl:
                        args['participantImageUrl']?.toString() ??
                            args['senderImage']?.toString() ??
                            '',
                    initialMessage: args['initialMessage']?.toString(),
                  ),
                );
              }

              if (settings.name == '/transaction_details') {
                final args = settings.arguments as Map<String, dynamic>;
                final int transactionId =
                    int.tryParse(args['transactionId']?.toString() ?? '') ??
                        int.tryParse(args['id']?.toString() ?? '') ??
                        0;
                return MaterialPageRoute(
                  builder: (context) => TransactionDetailsScreen(
                    transactionId: transactionId,
                    transactionTitle: args['transactionTitle']?.toString(),
                  ),
                );
              }

              if (settings.name == '/inspection_details') {
                // Since we don't have a dedicated InspectionDetailsScreen yet,
                // we navigate to ScheduleScreen which might highlight or filter.
                // For now, we'll use a Placeholder or just Schedule.
                return MaterialPageRoute(
                  builder: (context) => const MyScheduleScreen(),
                );
              }

              if (settings.name == '/property_details') {
                // ViewPropertyScreen requires a Property object, which we might not have.
                // For now, navigate to properties list.
                return MaterialPageRoute(
                  builder: (context) =>
                      const PlaceholderScreen(title: 'Property Details'),
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }
}

// Placeholder screen for demonstration (consistent with Arena)
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('This is the $title screen.'),
      ),
    );
  }
}
