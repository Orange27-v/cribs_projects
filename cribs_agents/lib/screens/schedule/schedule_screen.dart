import 'package:cribs_agents/services/schedule_service.dart';
import 'package:flutter/material.dart';

import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/screens/schedule/schedule_card.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class MyScheduleScreen extends StatefulWidget {
  final int initialTabIndex;
  final String initialFilterStatus;

  const MyScheduleScreen({
    super.key,
    this.initialTabIndex = 0, // Default to Today
    this.initialFilterStatus = "All appointments",
  });

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScheduleService _scheduleService = ScheduleService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _allInspections = [];
  List<dynamic> _todayInspections = [];
  List<dynamic> _upcomingInspections = [];
  List<dynamic> _pastInspections = [];
  late String _selectedFilter;

  final List<String> tabs = ["Today", "Upcoming", "Past"];

  // Note: Tab counts should reflect filtered results if desired,
  // but usually counts show totals. We'll stick to totals or filtered?
  // Let's keep totals for badge, but filter content.
  List<int> get tabCounts => [
        _todayInspections.length,
        _upcomingInspections.length,
        _pastInspections.length,
      ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilterStatus;
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _fetchInspections();
  }

  // Helper to filter inspections based on status
  // When a specific status is selected, show ALL inspections with that status
  // regardless of date-based tab (Today/Upcoming/Past)
  List<dynamic> _filterInspections(List<dynamic> inspections) {
    if (_selectedFilter == "All appointments") {
      return inspections;
    }
    // When filtering by status, search in ALL inspections (across all date ranges)
    return _allInspections.where((inspection) {
      final status = inspection['status']?.toString().toLowerCase() ?? '';
      return status == _selectedFilter.toLowerCase();
    }).toList();
  }

  Future<void> _fetchInspections() async {
    try {
      final inspections = await _scheduleService.getAgentInspections();

      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      setState(() {
        _allInspections = List.from(inspections);

        _todayInspections = inspections.where((i) {
          final date = DateTime.parse(i['inspection_date']);

          final normalizedDate = DateTime(date.year, date.month, date.day);

          return normalizedDate == today;
        }).toList();

        _upcomingInspections = inspections.where((i) {
          final date = DateTime.parse(i['inspection_date']);

          final normalizedDate = DateTime(date.year, date.month, date.day);

          return normalizedDate.isAfter(today);
        }).toList();

        _pastInspections = inspections.where((i) {
          final date = DateTime.parse(i['inspection_date']);

          final normalizedDate = DateTime(date.year, date.month, date.day);

          return normalizedDate.isBefore(today);
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();

        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
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
          'My Schedule',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading schedule',
                        style: const TextStyle(
                          fontSize: kFontSize16,
                          fontWeight: FontWeight.w500,
                          color: kBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: kFontSize14,
                            color: kGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _fetchInspections();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Retry',
                            style: TextStyle(color: kWhite)),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: CustomRefreshIndicator(
                    onRefresh: _fetchInspections,
                    child: CustomScrollView(
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        // Dropdown Filter Section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    "Filter appointments:",
                                    style: TextStyle(
                                      fontSize: kFontSize14,
                                      fontWeight: FontWeight.w500,
                                      color: kBlack54,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kWhite,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedFilter,
                                        isDense: true,
                                        isExpanded:
                                            true, // Allow dropdown to take up available space
                                        style: const TextStyle(
                                          fontSize: kFontSize14,
                                          color: kBlack,
                                        ),
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 20,
                                        ),
                                        items: const <DropdownMenuItem<String>>[
                                          DropdownMenuItem<String>(
                                            value: "All appointments",
                                            child: Text("All appointments"),
                                          ),
                                          DropdownMenuItem<String>(
                                            enabled: true,
                                            child: Divider(
                                              thickness: 1,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: "Scheduled",
                                            child: Text("Scheduled"),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: "Confirmed",
                                            child: Text("Confirmed"),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: "Completed",
                                            child: Text("Completed"),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: "Cancelled",
                                            child: Text("Cancelled"),
                                          ),
                                          DropdownMenuItem<String>(
                                            value: "No show",
                                            child: Text("No show"),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedFilter = value;
                                            });
                                            debugPrint("Selected: $value");
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tabs
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: kWhite,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorColor: kPrimaryColor,
                              labelColor: kPrimaryColor,
                              unselectedLabelColor: kGrey,
                              dividerColor: Colors.transparent,
                              labelPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              tabs: List.generate(tabs.length, (index) {
                                return Tab(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          tabs[index],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: kFontSize12),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (tabCounts[index] > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: kPrimaryColor,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            tabCounts[index].toString(),
                                            style: const TextStyle(
                                              color: kWhite,
                                              fontSize: kFontSize10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        // Tab Views
                        SliverFillRemaining(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildInspectionList(
                                _filterInspections(_todayInspections),
                              ),
                              _buildInspectionList(
                                _filterInspections(_upcomingInspections),
                                noDataMessage: "No upcoming appointments",
                              ),
                              _buildInspectionList(
                                _filterInspections(_pastInspections),
                                noDataMessage: "No past appointments",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildInspectionList(
    List<dynamic> inspections, {
    String noDataMessage = "No appointments today",
  }) {
    if (inspections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 150.0),
        child: EmptyStateWidget(
          message: noDataMessage,
          icon: Icons.event_note,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: inspections.length,
      itemBuilder: (context, index) {
        return ScheduleCard(inspection: inspections[index]);
      },
    );
  }
}
