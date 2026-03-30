import 'dart:async';
import 'package:cribs_agents/screens/components/modern_header.dart';
import 'package:cribs_agents/screens/agents/user_widgets/searchbar.dart';
import 'package:cribs_agents/services/property_service.dart';
import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/models/property.dart';
import 'package:cribs_agents/screens/properties/components/property_card.dart';
import 'package:cribs_agents/screens/properties/add_property_screen.dart';
import 'package:intl/intl.dart';
import 'package:cribs_agents/services/plan_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/screens/plans/plans_screen.dart';
import 'package:cribs_agents/screens/notification/notification_screen.dart';
import 'package:cribs_agents/screens/schedule/schedule_screen.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final PropertyService _propertyService = PropertyService();
  final PlanService _planService = PlanService();
  List<Property> _properties = [];
  List<Property> _filteredProperties = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _activePlanName;
  String? _planExpiry;
  bool _isPlanExpired = false;
  StreamSubscription<Map<String, dynamic>?>? _subscriptionStream;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _setupSubscriptionStream();
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _setupSubscriptionStream() {
    _subscriptionStream = PlanService.subscriptionStream.listen((data) {
      if (mounted) {
        if (data == null) {
          // Plan expired or no subscription
          setState(() {
            _activePlanName = null;
            _planExpiry = null;
            _isPlanExpired = true;
          });
        } else {
          // Check if plan is expired
          bool isExpired = false;
          if (data['end_date'] != null) {
            try {
              final endDate = DateTime.parse(data['end_date']);
              isExpired = endDate.isBefore(DateTime.now());
            } catch (e) {
              debugPrint('Error parsing end_date: $e');
            }
          }

          setState(() {
            _activePlanName = data['plan_name'];
            _isPlanExpired = isExpired;
            if (data['end_date'] != null) {
              final date = DateTime.parse(data['end_date']);
              _planExpiry = DateFormat('MMM d, yyyy').format(date);
            }
          });
        }
      }
    });
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _propertyService.getAgentProperties(),
        _planService.getCurrentSubscription(),
      ]);

      final propertyResult = results[0] as Map<String, dynamic>;
      final subscriptionData = results[1];

      if (mounted) {
        if (subscriptionData != null) {
          // Check if plan is expired
          bool isExpired = false;
          if (subscriptionData['end_date'] != null) {
            try {
              final endDate = DateTime.parse(subscriptionData['end_date']);
              isExpired = endDate.isBefore(DateTime.now());
            } catch (e) {
              debugPrint('Error parsing end_date: $e');
            }
          }

          setState(() {
            _activePlanName = subscriptionData['plan_name'];
            _isPlanExpired = isExpired;
            if (subscriptionData['end_date'] != null) {
              final date = DateTime.parse(subscriptionData['end_date']);
              _planExpiry = DateFormat('MMM d, yyyy').format(date);
            }
          });
          // Notify stream for other listeners
          PlanService.notifySubscriptionChange(
              isExpired ? null : subscriptionData);
        } else {
          setState(() {
            _activePlanName = null;
            _isPlanExpired = true;
          });
        }

        if (propertyResult['success'] == true) {
          setState(() {
            _properties = propertyResult['properties'] as List<Property>;
            _filteredProperties = _properties;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = propertyResult['message']?.toString() ??
                'Failed to load properties';
            _filteredProperties = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading properties: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshProperties() async {
    _searchController.clear();
    await _loadProperties();
  }

  void _filterProperties(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProperties = _properties;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredProperties = _properties.where((property) {
        final titleMatch =
            property.title.toLowerCase().contains(lowercaseQuery);
        final addressMatch =
            property.address?.toLowerCase().contains(lowercaseQuery) ?? false;
        final cityMatch =
            property.location.toLowerCase().contains(lowercaseQuery);
        return titleMatch || addressMatch || cityMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      body: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'PROPERTIES',
              onCalendarPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyScheduleScreen()),
                );
              },
              onNotificationPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotificationScreen()),
                );
              },
              actions: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kLightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.auto_awesome_outlined,
                      color: kPrimaryColor,
                      size: 20,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlansScreen(),
                        ),
                      );
                      // Refresh when returning from plans screen
                      if (result == true || result == null) {
                        _loadProperties();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: kWhite, size: 20),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPropertyScreen(),
                        ),
                      );
                      if (result == true) {
                        _refreshProperties();
                      }
                    },
                  ),
                ),
              ],
            ),
            // Styled plan banner - show for active or expired plans
            if (_activePlanName != null || _isPlanExpired) _buildPlanBanner(),
            Container(
              color: kWhite,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SearchBarWidget(
                    hintText: 'Search property by title, address, or city...',
                    controller: _searchController,
                    onChanged: _filterProperties,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CustomLoadingIndicator())
                  : _errorMessage != null
                      ? NetworkErrorWidget(
                          errorMessage: _errorMessage!,
                          onRefresh: _refreshProperties,
                        )
                      : CustomRefreshIndicator(
                          onRefresh: _refreshProperties,
                          child: _buildPropertyList(_filteredProperties),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanBanner() {
    // Determine if showing expired state
    final bool showExpired = _isPlanExpired || _activePlanName == null;

    // Theme colors based on state
    final Color primaryThemeColor = showExpired ? kRed : kPrimaryColor;
    final Color backgroundStart =
        showExpired ? const Color(0xFFFFF5F5) : const Color(0xFFF0F7FF);
    final Color backgroundEnd =
        showExpired ? const Color(0xFFFFF0F0) : const Color(0xFFE6F0FA);
    final Color iconBg =
        showExpired ? const Color(0xFFFFEBEB) : const Color(0xFFE1EFFE);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4), // Reduced margins
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // Slightly smaller radius
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundStart, backgroundEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: primaryThemeColor.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlansScreen()),
            );
            _loadProperties();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10), // Reduced visible padding
            child: Row(
              children: [
                // Icon Section
                Container(
                  width: 36, // Smaller icon container
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryThemeColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      showExpired
                          ? Icons.warning_rounded
                          : Icons.workspace_premium_rounded,
                      size: 18, // Smaller icon
                      color: primaryThemeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            showExpired
                                ? (_activePlanName ?? 'No Active Plan')
                                : _activePlanName!,
                            style: GoogleFonts.outfit(
                              fontSize: 14, // Smaller title
                              fontWeight: FontWeight.w700,
                              color: kBlack,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (!showExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: kGreen,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'PRO',
                                style: GoogleFonts.outfit(
                                  fontSize: 7, // Smaller badge text
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        showExpired
                            ? 'Plan expired'
                            : 'Valid until $_planExpiry',
                        style: GoogleFonts.outfit(
                          fontSize: 11, // Smaller subtitle
                          color: showExpired ? kRed : kGrey600,
                          fontWeight:
                              showExpired ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Button
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4), // Compact button
                  decoration: BoxDecoration(
                    color: showExpired ? kRed : kWhite,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: showExpired
                          ? kRed
                          : primaryThemeColor.withValues(alpha: 0.5),
                    ),
                    boxShadow: showExpired
                        ? [
                            BoxShadow(
                              color: kRed.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    showExpired ? 'Renew' : 'Manage',
                    style: GoogleFonts.outfit(
                      fontSize: 11, // Smaller button text
                      fontWeight: FontWeight.w600,
                      color: showExpired ? kWhite : primaryThemeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyList(List<Property> propertyList) {
    if (propertyList.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const EmptyStateWidget(
              message:
                  'No Properties Found\nYou have not listed any properties yet. Tap the \'+\' button to add one.',
              icon: Icons.home_work_outlined,
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: kPaddingAll16,
      itemCount: propertyList.length,
      itemBuilder: (context, index) {
        return PropertyCard(
          property: propertyList[index],
          onDelete: _refreshProperties,
        );
      },
    );
  }
}
