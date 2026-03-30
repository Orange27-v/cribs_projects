import 'package:cribs_agents/screens/notification/notification_screen.dart';
import 'package:cribs_agents/screens/schedule/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';

import 'package:cribs_agents/screens/agents/user_widgets/searchbar.dart';
import 'package:cribs_agents/models/lead.dart';
import 'package:cribs_agents/models/follower.dart';
import 'package:cribs_agents/screens/leads/components/lead_card.dart';
import 'package:cribs_agents/screens/leads/components/follower_card.dart';
import 'package:cribs_agents/screens/leads/components/leads_tab_bar.dart';
import 'package:cribs_agents/screens/components/modern_header.dart';

import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/leads_service.dart';
import 'package:cribs_agents/services/chat_service.dart';
import 'package:cribs_agents/services/agent_profile_service.dart';
import 'package:cribs_agents/screens/chat/conversation.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final LeadsService _leadsService = LeadsService();
  final ChatService _chatService = ChatService();
  final AgentProfileService _agentProfileService = AgentProfileService();

  // Tab state
  int _selectedTabIndex = 0;

  // Saved Properties (Leads)
  List<Lead> _activeLeads = [];
  bool _isLoadingLeads = true;

  // Followers
  List<Follower> _followers = [];
  bool _isLoadingFollowers = true;

  Map<String, dynamic>? _agentProfile;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchLeads(),
      _fetchFollowers(),
      _fetchAgentProfile(),
    ]);
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoadingLeads = true);
    final result = await _leadsService.fetchLeads();
    if (mounted) {
      if (result['success']) {
        final List<dynamic> data = result['data'];
        setState(() {
          _activeLeads = data.map((json) => Lead.fromJson(json)).toList();
          _isLoadingLeads = false;
        });
      } else {
        setState(() => _isLoadingLeads = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to fetch leads')),
        );
      }
    }
  }

  Future<void> _fetchFollowers() async {
    setState(() => _isLoadingFollowers = true);
    final result = await _leadsService.fetchFollowers();
    if (mounted) {
      if (result['success']) {
        final List<dynamic> data = result['data'] ?? [];
        setState(() {
          _followers = data.map((json) => Follower.fromJson(json)).toList();
          _isLoadingFollowers = false;
        });
      } else {
        setState(() => _isLoadingFollowers = false);
      }
    }
  }

  Future<void> _fetchAgentProfile() async {
    final result = await _agentProfileService.getAgentProfile();
    if (mounted && result['success']) {
      setState(() {
        _agentProfile = result['data'];
      });
    }
  }

  void _handleChatWithLead(Lead lead) async {
    if (_agentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent profile not loaded yet')),
      );
      return;
    }

    final user = lead.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User information missing')),
      );
      return;
    }

    await _startChat(
      userId: user.userId,
      userName: user.fullName,
      userAvatar: user.profilePictureUrl ?? '',
    );
  }

  void _handleChatWithFollower(Follower follower) async {
    if (_agentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agent profile not loaded yet')),
      );
      return;
    }

    final user = follower.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User information missing')),
      );
      return;
    }

    await _startChat(
      userId: user.userId,
      userName: user.fullName,
      userAvatar: user.profilePictureUrl ?? '',
    );
  }

  Future<void> _startChat({
    required int userId,
    required String userName,
    required String userAvatar,
  }) async {
    try {
      final data = _agentProfile!['data'];
      if (data == null) {
        throw Exception('Agent profile data is null');
      }

      final agentData = data['agent'];
      final agentInfo = data['agent_information'];

      if (agentData == null || agentInfo == null) {
        throw Exception('Agent or agent information is missing');
      }

      debugPrint('💬 Starting chat from leads screen');
      debugPrint('   User ID: user_$userId');
      debugPrint('   Agent ID: agent_${agentData['agent_id']}');

      final conversationId = await _chatService.findOrCreateConversation(
        userId: 'user_$userId',
        agentId: 'agent_${agentData['agent_id']}',
        userName: userName,
        userAvatar: userAvatar,
        agentName: '${agentData['first_name']} ${agentData['last_name']}',
        agentAvatar: agentInfo['profile_picture_url'] ?? '',
      );

      debugPrint('✅ Conversation created/found: $conversationId');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversationId,
              otherParticipantId: 'user_$userId',
              participantName: userName,
              participantImageUrl: userAvatar,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to start chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'LEADS',
              onCalendarPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyScheduleScreen(),
                  ),
                );
              },
              onNotificationPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SearchBarWidget(
                  hintText: _selectedTabIndex == 0
                      ? 'Search lead by name or property'
                      : 'Search followers by name',
                ),
              ),
            ),
            // Tab Bar
            LeadsTabBar(
              selectedIndex: _selectedTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
            // Content
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildLeadsList()
                  : _buildFollowersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadsList() {
    return CustomRefreshIndicator(
      onRefresh: _fetchLeads,
      child: _isLoadingLeads
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _activeLeads.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const EmptyStateWidget(
                      message:
                          'No Saved Properties Yet\nWhen users save your properties, they\'ll appear here.',
                      icon: Icons.home_outlined,
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _activeLeads.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return LeadCard(
                      lead: _activeLeads[index],
                      onChatPressed: () =>
                          _handleChatWithLead(_activeLeads[index]),
                    );
                  },
                ),
    );
  }

  Widget _buildFollowersList() {
    return CustomRefreshIndicator(
      onRefresh: _fetchFollowers,
      child: _isLoadingFollowers
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _followers.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const EmptyStateWidget(
                      message:
                          'No Followers Yet\nWhen users save you as their favorite agent, they\'ll appear here.',
                      icon: Icons.people_outline,
                    ),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _followers.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return FollowerCard(
                      follower: _followers[index],
                      onChatPressed: () =>
                          _handleChatWithFollower(_followers[index]),
                    );
                  },
                ),
    );
  }
}
