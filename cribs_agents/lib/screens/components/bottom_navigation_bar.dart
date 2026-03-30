import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cribs_agents/provider/agent_provider.dart';
import 'package:cribs_agents/services/chat_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import '../../constants.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        border: Border(top: BorderSide(color: Colors.black12, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: SvgPicture.asset(
                    'assets/icons/map-square.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      currentIndex == 0 ? kPrimaryColor : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Home',
                  index: 0,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: SvgPicture.asset(
                    'assets/icons/group.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      currentIndex == 1 ? kPrimaryColor : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Leads',
                  index: 1,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: SvgPicture.asset(
                    'assets/icons/house.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      currentIndex == 2 ? kPrimaryColor : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Properties',
                  index: 2,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: Consumer<AgentProvider>(
                    builder: (context, agentProvider, child) {
                      final agent = agentProvider.agent;
                      final agentId = agent?.agentId;

                      return StreamBuilder<int>(
                        stream: agentId != null
                            ? ChatService()
                                .getUnreadCountStream('agent_$agentId')
                            : Stream.value(0),
                        initialData: 0,
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;
                          return _buildIconWithBadge(
                            icon: SvgPicture.asset(
                              'assets/icons/chat.svg',
                              width: 20,
                              height: 20,
                              colorFilter: ColorFilter.mode(
                                currentIndex == 3 ? kPrimaryColor : Colors.grey,
                                BlendMode.srcIn,
                              ),
                            ),
                            badgeCount: unreadCount,
                          );
                        },
                      );
                    },
                  ),
                  label: 'Messages',
                  index: 3,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context: context,
                  icon: Consumer<AgentProvider>(
                    builder: (context, agentProvider, child) {
                      final agent = agentProvider.agent;
                      final profileImageUrl = agent?.profilePictureUrl;

                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: getResolvedImageProvider(profileImageUrl),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: currentIndex == 4
                                ? kPrimaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),
                  label: 'Profile',
                  index: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithBadge({
    required Widget icon,
    required int badgeCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        if (badgeCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required Widget icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? kPrimaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
