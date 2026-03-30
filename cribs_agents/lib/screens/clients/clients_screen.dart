import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../provider/agent_provider.dart';
import '../../services/chat_service.dart';
import '../chat/conversation.dart';
import '../../models/client.dart';
import '../../services/client_service.dart';
import '../../widgets/widgets.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final clients = await ClientService().getClients();
      if (mounted) {
        setState(() {
          _clients = clients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  ImageProvider _getProfileImage(String? path) {
    if (path == null ||
        path.isEmpty ||
        path == 'default_profile.jpg' ||
        path.contains('default_profile')) {
      return const AssetImage('assets/images/default_profile.jpg');
    }

    if (path.startsWith('http')) {
      return NetworkImage(path);
    }

    // Prepare path
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // If not starting with storage, add it
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }

    return NetworkImage('$kMainBaseUrl/$cleanPath');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Clients',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NetworkErrorWidget(
            errorMessage: _error,
            onRefresh: _loadClients,
            title: 'Error Loading Clients',
          ),
        ),
      );
    }

    if (_clients.isEmpty) {
      return CustomRefreshIndicator(
        onRefresh: _loadClients,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: const Padding(
              padding: EdgeInsets.only(bottom: 120),
              child: EmptyStateWidget(
                message:
                    'No Clients Yet\nClients who have an inspection with you will appear here.',
                icon: Icons.people_outline,
              ),
            ),
          ),
        ),
      );
    }

    return CustomRefreshIndicator(
      onRefresh: _loadClients,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _clients.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          final client = _clients[index - 1];
          return _buildClientCard(client);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kPrimaryColor.withValues(alpha: 0.1),
                  const Color(0xFF10B981).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kPrimaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: kPrimaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_clients.length} ${_clients.length == 1 ? 'Client' : 'Clients'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'People who booked inspections with you',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToChat(client),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with gradient border
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kPrimaryColor,
                        Color(0xFF10B981),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kWhite,
                    ),
                    child: CircleAvatar(
                      backgroundImage:
                          _getProfileImage(client.profilePictureUrl),
                      radius: 26,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Client info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              client.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            client.area != null
                                ? Icons.location_on_rounded
                                : Icons.email_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              client.area ?? client.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Inspection status badge
                      if (client.inspectionStatus != null) ...[
                        const SizedBox(height: 6),
                        _buildStatusBadge(client.inspectionStatus!),
                      ],
                    ],
                  ),
                ),
                // Simple chat button with SVG icon
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/chat.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      kPrimaryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => _navigateToChat(client),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToChat(Client client) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      ),
    );

    try {
      // Get current agent info
      final agentProvider = Provider.of<AgentProvider>(context, listen: false);
      final agent = agentProvider.agent;

      if (agent == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Find or create conversation with valid MongoDB ObjectId
      final conversationId = await ChatService().findOrCreateConversation(
        userId: 'user_${client.userId}',
        agentId: 'agent_${agent.agentId}',
        userName: client.fullName,
        userAvatar: client.profilePictureUrl ?? '',
        agentName: '${agent.firstName} ${agent.lastName}',
        agentAvatar: agent.profilePictureUrl ?? '',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate with valid conversation ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            conversationId: conversationId,
            otherParticipantId: 'user_${client.userId}',
            participantName: client.fullName,
            participantImageUrl: client.profilePictureUrl ?? '',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    String statusLabel;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xFF10B981); // Emerald green
        statusLabel = 'Completed';
        break;
      case 'confirmed':
        statusColor = const Color(0xFF3B82F6); // Blue
        statusLabel = 'Confirmed';
        break;
      case 'scheduled':
        statusColor = const Color(0xFFF59E0B); // Amber
        statusLabel = 'Scheduled';
        break;
      case 'cancelled':
        statusColor = const Color(0xFFEF4444); // Red
        statusLabel = 'Cancelled';
        break;
      case 'pending':
        statusColor = const Color(0xFF8B5CF6); // Purple
        statusLabel = 'Pending';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}
