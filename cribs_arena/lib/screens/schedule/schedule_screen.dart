import 'package:flutter/material.dart';

import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/screens/schedule/schedule_card.dart';
import 'package:cribs_arena/services/booking_service.dart';
import 'package:cribs_arena/services/update_inspection_services.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});

  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  final UpdateInspectionService _updateInspectionService =
      UpdateInspectionService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _todayBookings = [];
  List<dynamic> _upcomingBookings = [];
  List<dynamic> _pastBookings = [];
  String _selectedFilter = "All appointments";

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final bookings = await _bookingService.getMyBookings();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      setState(() {
        // Filter and sort by created_at (most recent first)
        _todayBookings = bookings.where((b) {
          final date = DateTime.parse(b['inspection_date']);
          final normalizedBookingDate =
              DateTime(date.year, date.month, date.day);
          return normalizedBookingDate == today;
        }).toList()
          ..sort((a, b) {
            final aCreated =
                DateTime.parse(a['created_at'] ?? a['inspection_date']);
            final bCreated =
                DateTime.parse(b['created_at'] ?? b['inspection_date']);
            return bCreated.compareTo(aCreated); // Most recent first
          });

        _upcomingBookings = bookings.where((b) {
          final date = DateTime.parse(b['inspection_date']);
          final normalizedBookingDate =
              DateTime(date.year, date.month, date.day);
          return normalizedBookingDate.isAfter(today);
        }).toList()
          ..sort((a, b) {
            final aCreated =
                DateTime.parse(a['created_at'] ?? a['inspection_date']);
            final bCreated =
                DateTime.parse(b['created_at'] ?? b['inspection_date']);
            return bCreated.compareTo(aCreated); // Most recent first
          });

        _pastBookings = bookings.where((b) {
          final date = DateTime.parse(b['inspection_date']);
          final normalizedBookingDate =
              DateTime(date.year, date.month, date.day);
          return normalizedBookingDate.isBefore(today);
        }).toList()
          ..sort((a, b) {
            final aCreated =
                DateTime.parse(a['created_at'] ?? a['inspection_date']);
            final bCreated =
                DateTime.parse(b['created_at'] ?? b['inspection_date']);
            return bCreated.compareTo(aCreated); // Most recent first
          });

        _tabController = TabController(length: tabs.length, vsync: this);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  final List<String> tabs = ["Today", "Upcoming", "Past"];

  @override
  void dispose() {
    _tabController.dispose();
    _updateInspectionService.dispose();
    super.dispose();
  }

  List<dynamic> _filterBookings(List<dynamic> bookings) {
    if (_selectedFilter == "All appointments") {
      return bookings;
    }
    final selectedFilter = _selectedFilter.toLowerCase();
    return bookings.where((booking) {
      final status =
          (booking['status'] as String? ?? 'scheduled').toLowerCase();
      if (selectedFilter == "confirmed") {
        return status == "scheduled";
      }
      if (selectedFilter == "no show") {
        return status == "no_show" || status == "no show";
      }
      return status == selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CustomLoadingIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    final filteredTodayBookings = _filterBookings(_todayBookings);
    final filteredUpcomingBookings = _filterBookings(_upcomingBookings);
    final filteredPastBookings = _filterBookings(_pastBookings);

    final tabCounts = [
      filteredTodayBookings.length,
      filteredUpcomingBookings.length,
      filteredPastBookings.length
    ];

    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('My Schedule'),
      ),
      body: SafeArea(
        child: CustomRefreshIndicator(
          onRefresh: _fetchBookings,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              // Dropdown Filter Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: const BoxDecoration(
                            color: kWhite,
                            borderRadius: kRadius8,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              dropdownColor: kWhite,
                              value: _selectedFilter,
                              isExpanded: true,
                              isDense: true,
                              style: GoogleFonts.roboto(
                                fontSize: kFontSize14,
                                color: kBlack,
                              ),
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  size: kIconSize20),
                              items: <String>[
                                "All appointments",
                                "Scheduled",
                                "Confirmed",
                                "Completed",
                                "Cancelled",
                                "No show"
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedFilter = value;
                                  });
                                }
                                debugPrint("Selected: $value");
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
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    tabs: List.generate(tabs.length, (index) {
                      return Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                tabs[index],
                                style: const TextStyle(fontSize: kFontSize12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tabCounts[index] > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tabCounts[index].toString(),
                                  style: const TextStyle(
                                      color: kWhite, fontSize: kFontSize10),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),

              // Tab Views
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBookingList(filteredTodayBookings),
                    _buildBookingList(filteredUpcomingBookings),
                    _buildBookingList(filteredPastBookings,
                        noDataMessage: "No past appointments"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingList(List<dynamic> bookings,
      {String noDataMessage = "No appointments"}) {
    if (bookings.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.only(bottom: 150.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleImageContainer(
              imagePath: 'assets/images/magnifier.png',
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              noDataMessage,
              style: const TextStyle(
                fontSize: kFontSize16,
                color: kGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return ScheduleCard(
          booking: bookings[index],
          onStatusChanged: _fetchBookings,
          updateInspectionService: _updateInspectionService,
        );
      },
    );
  }
}
