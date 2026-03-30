import 'package:flutter/material.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/services/agent_service.dart';
import 'package:cribs_arena/screens/agents/agent_card.dart'; // Reusing existing AgentCard
import 'package:cribs_arena/screens/agents/agent_card_skeleton.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class AllAgentsScreen extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;

  const AllAgentsScreen({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<AllAgentsScreen> createState() => _AllAgentsScreenState();
}

class _AllAgentsScreenState extends State<AllAgentsScreen> {
  List<Agent> _agents = [];
  List<Agent> _originalAgents = []; // Added for search functionality
  bool _isLoading = true;
  String _error = '';
  String searchQuery = ''; // Added for search functionality

  final AgentService _agentService = AgentService();

  @override
  void initState() {
    super.initState();
    _fetchNearbyAgents();
  }

  Future<void> _fetchNearbyAgents() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final fetchedAgents = await _agentService.findNearbyAgents(
        widget.userLatitude,
        widget.userLongitude,
        50.0, // Same radius as in MyFeedScreen
      );
      setState(() {
        _agents = fetchedAgents;
        _originalAgents = fetchedAgents; // Populate original list
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  // Added for search functionality
  void _filterAgents(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        _agents = _originalAgents;
      } else {
        final q = query.toLowerCase();
        _agents = _originalAgents
            .where((agent) =>
                agent.fullName.toLowerCase().contains(q) ||
                (agent.area?.toLowerCase().contains(q) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite, // Changed to kWhite for consistency
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header with back
            Padding(
              padding: kPaddingFromLTRB16_16_16_8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back,
                        color: kPrimaryColor, size: kIconSize24),
                    const SizedBox(width: kSizedBoxW8),
                    Text(
                      kBackText,
                      style: GoogleFonts.roboto(
                        color: kPrimaryColor,
                        fontSize: kFontSize16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kSizedBoxH12),

            // title
            Padding(
              padding: kPaddingH16,
              child: Text(
                kAllAgentsTitle, // Using new constant
                style: GoogleFonts.roboto(
                  fontSize: kFontSize16,
                  fontWeight: FontWeight.w400,
                  color: kDarkTextColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(
                height:
                    kSizedBoxH8), // Commented out as in recommended_property_screen.dart

            // search
            Padding(
              padding: kPaddingH16,
              child: TextField(
                style: GoogleFonts.roboto(color: kDarkTextColor),
                onChanged: _filterAgents, // Using new filter method
                decoration: InputDecoration(
                  hintText: kSearchAgentHint, // Using new constant
                  hintStyle: GoogleFonts.roboto(color: kGrey500),
                  prefixIcon: const Icon(Icons.search, color: kGrey500),
                  filled: true,
                  fillColor: kGrey100,
                  contentPadding: kPaddingV14,
                  border: const OutlineInputBorder(
                    borderRadius: kRadius12,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: kSizedBoxH12),

            // Agents Grid
            Expanded(
              child: CustomRefreshIndicator(
                onRefresh: _fetchNearbyAgents,
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(kSizedBoxW10),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: kSizedBoxW14,
                            mainAxisSpacing: kSizedBoxH14,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            return const AgentCardSkeleton();
                          },
                        ),
                      )
                    : _error.isNotEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(child: Text(_error)),
                            ),
                          )
                        : _agents.isEmpty
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.6,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const CircleImageContainer(
                                          imagePath:
                                              'assets/images/magnifier.png',
                                          size: 100,
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'No agents found near you.',
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            color: kGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(kSizedBoxW10),
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: kSizedBoxW14,
                                    mainAxisSpacing: kSizedBoxH14,
                                    childAspectRatio: 0.80,
                                  ),
                                  itemCount: _agents.length,
                                  itemBuilder: (context, index) {
                                    final agent = _agents[index];
                                    return AgentCard(agent: agent);
                                  },
                                ),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
