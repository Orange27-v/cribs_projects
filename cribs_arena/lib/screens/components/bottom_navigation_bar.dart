import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../../services/chat_service.dart';
import '../../widgets/widgets.dart';
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
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Debug: Check if user data exists
        debugPrint('🔍 BottomNav - User data: ${userProvider.user}');

        final String? profilePicturePath =
            userProvider.user?['profile_picture_url'];

        // Debug: Check profile picture path
        debugPrint('🔍 BottomNav - Profile picture path: $profilePicturePath');

        final ImageProvider profileImage =
            getResolvedImageProvider(profilePicturePath);

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
                        // ignore: deprecated_member_use
                        colorFilter: ColorFilter.mode(
                            currentIndex == 0 ? kPrimaryColor : Colors.grey,
                            BlendMode.srcIn),
                      ),
                      label: 'Discover',
                      index: 0,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      context: context,
                      icon: SvgPicture.asset(
                        'assets/icons/house.svg', // Using house.svg for Saved
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                            currentIndex == 1 ? kPrimaryColor : Colors.grey,
                            BlendMode.srcIn),
                      ),
                      label: 'Saved',
                      index: 1,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      context: context,
                      icon: Consumer<UserProvider>(
                        builder: (context, userProvider, child) {
                          final rawUserId =
                              userProvider.user?['user_id']?.toString();

                          return StreamBuilder<int>(
                            stream: rawUserId != null
                                ? ChatService()
                                    .getUnreadCountStream('user_$rawUserId')
                                : Stream.value(0),
                            initialData: 0,
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.data ?? 0;
                              return _buildIconWithBadge(
                                icon: SvgPicture.asset(
                                  'assets/icons/chat.svg',
                                  width: 20,
                                  height: 20,
                                  // ignore: deprecated_member_use
                                  colorFilter: ColorFilter.mode(
                                      currentIndex == 2
                                          ? kPrimaryColor
                                          : Colors.grey,
                                      BlendMode.srcIn),
                                ),
                                badgeCount: unreadCount,
                              );
                            },
                          );
                        },
                      ),
                      label: 'Chat',
                      index: 2,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      context: context,
                      icon: Container(
                        // Using Container for Profile image
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: profileImage,
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: currentIndex == 3
                                ? kPrimaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      label: 'Profile',
                      index: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
