import 'package:flutter/material.dart';

import '../../constants.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/screens/agents/agent_card.dart';
import 'package:cribs_arena/screens/agents/agent_card_skeleton.dart';
import 'package:cribs_arena/widgets/widgets.dart';

class AgentTab extends StatelessWidget {
  final List<Agent> agents;
  final bool isLoading;
  final String error;
  final VoidCallback onRefresh;

  const AgentTab({
    super.key,
    this.agents = const [],
    this.isLoading = false,
    this.error = '',
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const AgentCardSkeleton();
        },
      );
    }

    if (error.isNotEmpty) {
      return NetworkErrorWidget(
        errorMessage: error,
        onRefresh: onRefresh,
      );
    }

    if (agents.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 150),
          const CircleImageContainer(
            imagePath: 'assets/images/magnifier.png',
            size: 100,
          ),
          const SizedBox(height: 20),
          const Text(
            'No saved agents yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Connect with agents and save your\nfavorites here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.search, color: kWhite),
            label: const Text(
              'Explore',
              style: TextStyle(color: kWhite),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        return AgentCard(agent: agents[index]);
      },
    );
  }
}
