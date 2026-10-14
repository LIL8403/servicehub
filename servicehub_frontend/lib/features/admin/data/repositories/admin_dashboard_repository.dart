import 'dart:convert';

import '../../../../core/api/api_exception.dart';
import '../../../../core/api/api_service.dart';

/// Aggregated dashboard data returned by GET /admin/dashboard.
class AdminDashboardData {
  const AdminDashboardData({
    required this.usersTotal,
    required this.usersByStatus,
    required this.artisansByStatus,
    required this.serviceRequestsTotal,
    required this.serviceRequestsByStatus,
    required this.paymentsByStatus,
    required this.disputesByStatus,
    required this.revenueThisMonth,
    required this.revenueLastMonth,
    required this.revenueThisMonthCommission,
    required this.dailySeries,
    required this.recentActivity,
  });

  final int usersTotal;
  final Map<String, int> usersByStatus;
  final Map<String, int> artisansByStatus;
  final int serviceRequestsTotal;
  final Map<String, int> serviceRequestsByStatus;
  final Map<String, int> paymentsByStatus;
  final Map<String, int> disputesByStatus;
  final int revenueThisMonth;
  final int revenueLastMonth;
  final int revenueThisMonthCommission;
  final List<DashboardDay> dailySeries;
  final List<DashboardActivity> recentActivity;

  // -----------------------------------------------------------------
  // Derived metrics for the four cards
  // -----------------------------------------------------------------

  int get pendingVerifications => artisansByStatus['pending'] ?? 0;

  int get activeRequests {
    const terminal = {
      'completed',
      'cancelled',
      'disputed',
    };
    var sum = 0;
    serviceRequestsByStatus.forEach((key, value) {
      if (!terminal.contains(key)) sum += value;
    });
    return sum;
  }

  int get openDisputes {
    const terminal = {'resolved', 'closed'};
    var sum = 0;
    disputesByStatus.forEach((key, value) {
      if (!terminal.contains(key)) sum += value;
    });
    return sum;
  }

  int get disputesNeedingAttention {
    const critical = {
      'opened',
      'under_review',
      'pending_execution',
      'reconciliation_required',
    };
    var sum = 0;
    disputesByStatus.forEach((key, value) {
      if (critical.contains(key)) sum += value;
    });
    return sum;
  }

  /// Percentage change of this month's revenue vs last month.
  double get revenueDeltaPercent {
    if (revenueLastMonth == 0) {
      return revenueThisMonth == 0 ? 0.0 : 100.0;
    }
    return ((revenueThisMonth - revenueLastMonth) / revenueLastMonth) * 100;
  }

  // -----------------------------------------------------------------
  // Status donut data
  // -----------------------------------------------------------------

  /// Buckets the service request statuses into the five segments the
  /// donut renders: Completed, In Progress, Awaiting Confirmation,
  /// Cancelled, Other.
  List<DashboardDonutSegment> get donutSegments {
    final completed = serviceRequestsByStatus['completed'] ?? 0;
    final awaiting =
        serviceRequestsByStatus['awaiting_confirmation'] ?? 0;
    final cancelled = serviceRequestsByStatus['cancelled'] ?? 0;
    final disputed = serviceRequestsByStatus['disputed'] ?? 0;

    const inProgressKeys = {
      'payment_pending',
      'booked',
      'in_progress',
      'quotation_accepted',
      'artisan_approved',
      'artisan_selected',
    };
    var inProgress = 0;
    for (var k in inProgressKeys) {
      inProgress += serviceRequestsByStatus[k] ?? 0;
    }

    const otherKeys = {
      'created',
      'awaiting_artisan_selection',
      'pending_artisan_response',
      'no_artisan_available',
      'inspection_scheduled',
      'inspection_completed',
      'quotation_pending',
      'quotation_received',
    };
    var other = 0;
    for (var k in otherKeys) {
      other += serviceRequestsByStatus[k] ?? 0;
    }
    other += disputed; // Disputed goes into "Other" for now

    return [
      DashboardDonutSegment(label: 'Completed', value: completed),
      DashboardDonutSegment(label: 'In Progress', value: inProgress),
      DashboardDonutSegment(
        label: 'Awaiting Confirmation',
        value: awaiting,
      ),
      DashboardDonutSegment(label: 'Cancelled', value: cancelled),
      DashboardDonutSegment(label: 'Other', value: other),
    ];
  }

  /// The top three services by request count. Not part of the
  /// dashboard response yet — returns an empty list until the backend
  /// exposes it. The widget hides itself when empty.
  List<({String name, int count})> get topServices => const [];

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    Map<String, int> toIntMap(dynamic raw) {
      if (raw is! Map) return const {};
      return raw.map(
        (k, v) => MapEntry(
          k.toString(),
          (v as num?)?.toInt() ?? 0,
        ),
      );
    }

    final artisans = json['artisans'] as Map<String, dynamic>? ?? const {};
    final requests =
        json['service_requests'] as Map<String, dynamic>? ?? const {};
    final payments = json['payments'] as Map<String, dynamic>? ?? const {};
    final disputes = json['disputes'] as Map<String, dynamic>? ?? const {};
    final users = json['users'] as Map<String, dynamic>? ?? const {};
    final revenue = json['revenue'] as Map<String, dynamic>? ?? const {};

    final seriesRaw = (json['daily_series'] as List?) ?? const [];
    final activityRaw = (json['recent_activity'] as List?) ?? const [];

    return AdminDashboardData(
      usersTotal: (users['total'] as num?)?.toInt() ?? 0,
      usersByStatus: toIntMap(users['by_status']),
      artisansByStatus:
          toIntMap(artisans['by_verification_status']),
      serviceRequestsTotal:
          (requests['total'] as num?)?.toInt() ?? 0,
      serviceRequestsByStatus: toIntMap(requests['by_status']),
      paymentsByStatus: toIntMap(payments['by_status']),
      disputesByStatus: toIntMap(disputes['by_status']),
      revenueThisMonth: (revenue['this_month'] as num?)?.toInt() ?? 0,
      revenueLastMonth: (revenue['last_month'] as num?)?.toInt() ?? 0,
      revenueThisMonthCommission:
          (revenue['this_month_commission'] as num?)?.toInt() ?? 0,
      dailySeries: seriesRaw
          .whereType<Map<String, dynamic>>()
          .map(DashboardDay.fromJson)
          .toList(growable: false),
      recentActivity: activityRaw
          .whereType<Map<String, dynamic>>()
          .map(DashboardActivity.fromJson)
          .toList(growable: false),
    );
  }
}

class DashboardDay {
  const DashboardDay({
    required this.date,
    required this.revenue,
    required this.requests,
  });

  final DateTime date;
  final int revenue;
  final int requests;

  factory DashboardDay.fromJson(Map<String, dynamic> json) {
    return DashboardDay(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      requests: (json['requests'] as num?)?.toInt() ?? 0,
    );
  }
}

class DashboardActivity {
  const DashboardActivity({
    required this.id,
    required this.eventType,
    required this.actorName,
    required this.subjectType,
    required this.subjectId,
    required this.metadata,
    required this.occurredAt,
  });

  final String id;
  final String eventType;
  final String? actorName;
  final String? subjectType;
  final String? subjectId;
  final Map<String, dynamic> metadata;
  final DateTime? occurredAt;

  factory DashboardActivity.fromJson(Map<String, dynamic> json) {
    return DashboardActivity(
      id: json['id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? '',
      actorName: json['actor_name']?.toString(),
      subjectType: json['subject_type']?.toString(),
      subjectId: json['subject_id']?.toString(),
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? const {},
      occurredAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ),
    );
  }
}

class DashboardDonutSegment {
  const DashboardDonutSegment({required this.label, required this.value});

  final String label;
  final int value;
}

class AdminDashboardRepository {
  AdminDashboardRepository({required this.apiService});

  final ApiService apiService;

  Future<AdminDashboardData> fetch() async {
    try {
      final response =
          await apiService.authenticatedGet('/admin/dashboard');
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final dashboard = json['dashboard'] as Map<String, dynamic>?;
      if (dashboard == null) {
        throw const ApiException(
          message: 'Unexpected response shape.',
          statusCode: 500,
        );
      }
      return AdminDashboardData.fromJson(dashboard);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Failed to load dashboard: $e');
    }
  }
}