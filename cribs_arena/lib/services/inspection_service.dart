import 'dart:async';
import 'package:cribs_arena/services/booking_service.dart';
import 'package:flutter/foundation.dart';

class InspectionService {
  final BookingService _bookingService = BookingService();

  /// Provides a real-time stream of upcoming inspections count.
  /// Only counts inspections that meet ALL of the following criteria:
  /// - Date is TODAY or in the FUTURE (past dates are excluded)
  /// - Status is 'scheduled' or 'rescheduled'
  /// - Excludes: cancelled, completed, no_show, and past inspections
  Stream<int> getUpcomingInspectionsCountStream({
    Duration interval = const Duration(seconds: 5),
  }) {
    return Stream.periodic(interval).asyncMap((_) async {
      try {
        final bookings = await _bookingService.getMyBookings();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final upcoming = bookings.where((b) {
          final date = DateTime.parse(b['inspection_date']);
          final normalized = DateTime(date.year, date.month, date.day);
          final status = (b['status'] as String?)?.toLowerCase() ?? 'scheduled';

          // Only count if date is today or future AND status is scheduled or rescheduled
          final isUpcoming = normalized.isAfter(today) || normalized == today;
          final isActiveStatus =
              status == 'scheduled' || status == 'rescheduled';

          return isUpcoming && isActiveStatus;
        }).length;

        return upcoming;
      } catch (e) {
        // Handle "Authentication token not found" gracefully without spamming logs
        if (e.toString().contains('Authentication token not found')) {
          return 0;
        }
        debugPrint('Error in InspectionService stream: $e');
        return 0;
      }
    });
  }
}
