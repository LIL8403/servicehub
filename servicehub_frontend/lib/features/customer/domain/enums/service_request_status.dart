/// Mirrors the backend enum at app/Enums/ServiceRequestStatus.php
///
/// The string values must stay in sync with the backend, since they
/// arrive over the wire as the `status` field on a ServiceRequest.
enum ServiceRequestStatus {
  created('created'),
  awaitingArtisanSelection('awaiting_artisan_selection'),
  pendingArtisanResponse('pending_artisan_response'),
  artisanApproved('artisan_approved'),
  artisanSelected('artisan_selected'),
  noArtisanAvailable('no_artisan_available'),
  inspectionScheduled('inspection_scheduled'),
  inspectionCompleted('inspection_completed'),
  quotationPending('quotation_pending'),
  quotationReceived('quotation_received'),
  quotationAccepted('quotation_accepted'),
  paymentPending('payment_pending'),
  booked('booked'),
  inProgress('in_progress'),
  awaitingConfirmation('awaiting_confirmation'),
  completed('completed'),
  cancelled('cancelled'),
  disputed('disputed'),
  unknown('unknown');

  const ServiceRequestStatus(this.value);

  /// The raw string value as stored and transmitted by the backend.
  final String value;

  /// Safely parses a raw status string into an enum value.
  /// Returns [ServiceRequestStatus.unknown] for null, empty, or
  /// unrecognised inputs — never throws.
  static ServiceRequestStatus fromString(String? value) {
    if (value == null || value.isEmpty) return ServiceRequestStatus.unknown;
    return ServiceRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ServiceRequestStatus.unknown,
    );
  }

  /// A human-readable label suitable for the generic tracking timeline.
  /// Localized copy for user-facing strings lives in the ARB files;
  /// this getter is intended for developer-facing display and fallbacks.
  String get label {
    switch (this) {
      case ServiceRequestStatus.created:
        return 'Created';
      case ServiceRequestStatus.awaitingArtisanSelection:
        return 'Awaiting artisan selection';
      case ServiceRequestStatus.pendingArtisanResponse:
        return 'Pending artisan response';
      case ServiceRequestStatus.artisanApproved:
        return 'Artisan approved';
      case ServiceRequestStatus.artisanSelected:
        return 'Artisan selected';
      case ServiceRequestStatus.noArtisanAvailable:
        return 'No artisan available';
      case ServiceRequestStatus.inspectionScheduled:
        return 'Inspection scheduled';
      case ServiceRequestStatus.inspectionCompleted:
        return 'Inspection completed';
      case ServiceRequestStatus.quotationPending:
        return 'Quotation pending';
      case ServiceRequestStatus.quotationReceived:
        return 'Quotation received';
      case ServiceRequestStatus.quotationAccepted:
        return 'Quotation accepted';
      case ServiceRequestStatus.paymentPending:
        return 'Payment pending';
      case ServiceRequestStatus.booked:
        return 'Booked';
      case ServiceRequestStatus.inProgress:
        return 'In progress';
      case ServiceRequestStatus.awaitingConfirmation:
        return 'Awaiting confirmation';
      case ServiceRequestStatus.completed:
        return 'Completed';
      case ServiceRequestStatus.cancelled:
        return 'Cancelled';
      case ServiceRequestStatus.disputed:
        return 'Disputed';
      case ServiceRequestStatus.unknown:
        return 'Unknown';
    }
  }
}