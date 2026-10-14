// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ServiceHUB';

  @override
  String get landingHeadline => 'Find trusted artisans for your service needs';

  @override
  String get landingTagline => 'Verified. Secure. Local.';

  @override
  String get landingCtaPrimary => 'Find a Service';

  @override
  String get landingCtaSecondary => 'Browse Artisans';

  @override
  String get landingLoginLink => 'Already have an account? Login';

  @override
  String get landingRegisterLink => 'New here? Register';

  @override
  String get landingAuthPrefixLogin => 'Already have an account? ';

  @override
  String get landingAuthActionLogin => 'Login';

  @override
  String get landingAuthPrefixRegister => 'New here? ';

  @override
  String get landingAuthActionRegister => 'Register';

  @override
  String get landingTrustTitle => 'Trusted • Secure • Local';

  @override
  String get landingTrustVerified => 'Verified artisans';

  @override
  String get landingTrustPayments => 'Protected payments';

  @override
  String get landingTrustLocal => 'Local service professionals';

  @override
  String get landingSampleCta => 'View a sample artisan';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesHeading => 'What do you need help with?';

  @override
  String get servicesSubheading => 'Choose a service to get started';

  @override
  String get servicesBookNow => 'Book Now';

  @override
  String get categoryPlumbing => 'Plumbing';

  @override
  String get categoryPlumbingDesc => 'Leaks, pipes, installations';

  @override
  String get categoryElectrical => 'Electrical';

  @override
  String get categoryElectricalDesc => 'Wiring, sockets, repairs';

  @override
  String get categoryCarpentry => 'Carpentry';

  @override
  String get categoryCarpentryDesc => 'Furniture, doors, shelves';

  @override
  String get categoryPainting => 'Painting';

  @override
  String get categoryPaintingDesc => 'Interior, exterior, touch-ups';

  @override
  String get categoryMasonry => 'Masonry';

  @override
  String get categoryMasonryDesc => 'Walls, tiles, concrete';

  @override
  String get categoryMechanics => 'Mechanics';

  @override
  String get categoryMechanicsDesc => 'Vehicle and equipment repair';

  @override
  String get loginPromptTitle => 'Log in to continue';

  @override
  String get loginPromptBody =>
      'You need an account to create a service request.';

  @override
  String get loginPromptLogin => 'Log In';

  @override
  String get loginPromptRegister => 'Create an Account';

  @override
  String get loginPromptContinueBrowsing => 'Continue browsing';

  @override
  String get createRequestTitle => 'Create Request';

  @override
  String createRequestStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get createRequestContinue => 'Continue';

  @override
  String get createRequestSubmit => 'Submit Request';

  @override
  String get createRequestStep1Heading => 'Describe what you need done';

  @override
  String get createRequestStep1DescriptionHint =>
      'Tell us about the job. Include details like what\'s broken, where it is, and any other context.';

  @override
  String get createRequestStep1PhotoLabel => 'Add photos (optional)';

  @override
  String get createRequestStep1PhotoHint =>
      'Photos help artisans give accurate quotations.';

  @override
  String get createRequestStep1TakePhoto => 'Take photo';

  @override
  String get createRequestStep1ChooseGallery => 'Choose from gallery';

  @override
  String get createRequestStep1UrgencyLabel => 'How urgent is this?';

  @override
  String get createRequestStep1UrgencyLow => 'Low';

  @override
  String get createRequestStep1UrgencyLowDesc => 'Within a week';

  @override
  String get createRequestStep1UrgencyMedium => 'Medium';

  @override
  String get createRequestStep1UrgencyMediumDesc => 'Within 2-3 days';

  @override
  String get createRequestStep1UrgencyHigh => 'High';

  @override
  String get createRequestStep1UrgencyHighDesc => 'Within 24 hours';

  @override
  String get createRequestStep1AiTitle => 'AI-Assisted Matching';

  @override
  String get createRequestStep1AiDescription =>
      'Let AI analyze your request and recommend artisans best suited to your job. You can still browse and choose manually.';

  @override
  String get createRequestStep3Heading => 'When would you like this done?';

  @override
  String get createRequestStep3Subheading =>
      'Choose a preferred time window. The artisan will confirm a specific time with you.';

  @override
  String get createRequestStep3SelectDate => 'Select date';

  @override
  String createRequestStep3SelectedDate(String date) {
    return 'Selected: $date';
  }

  @override
  String get createRequestStep3TimeWindowLabel => 'Preferred time window';

  @override
  String get createRequestStep3EarliestLabel => 'Earliest';

  @override
  String get createRequestStep3LatestLabel => 'Latest';

  @override
  String get createRequestStep3FlexibleTitle => 'I\'m flexible';

  @override
  String get createRequestStep3FlexibleDescription =>
      'The artisan will propose a time that works for both of you.';

  @override
  String get createRequestStep3NotesLabel => 'Additional notes (optional)';

  @override
  String get createRequestStep3NotesHint => 'Any special instructions?';

  @override
  String get createRequestStep2Heading => 'Where do you need the service?';

  @override
  String get createRequestStep2Subheading =>
      'We\'ll use this to find artisans in your area.';

  @override
  String get createRequestStep2SearchHint =>
      'Search for an address or landmark';

  @override
  String get createRequestStep2PinActive => 'Address set';

  @override
  String get createRequestStep2PinInactive => 'Enter an address';

  @override
  String get createRequestStep2MapPlaceholder =>
      'Map preview available in the next release';

  @override
  String get createRequestStep2ConfirmedTitle => 'Confirmed location';

  @override
  String get createRequestStep4Heading => 'Review your request';

  @override
  String get createRequestStep4Subheading =>
      'Check the details below. You can edit any section before submitting.';

  @override
  String get createRequestStep4JobLabel => 'Job';

  @override
  String get createRequestStep4LocationLabel => 'Location';

  @override
  String get createRequestStep4LocationMissing => 'No location set';

  @override
  String get createRequestStep4ScheduleLabel => 'Schedule';

  @override
  String get createRequestStep4ScheduleFlexible => 'Flexible scheduling';

  @override
  String get createRequestStep4ScheduleMissing => 'No schedule set';

  @override
  String get createRequestStep4PreferredWindow => 'Preferred window';

  @override
  String get createRequestStep4AiLabel => 'AI-Assisted Matching';

  @override
  String get createRequestStep4AiEnabled =>
      'Enabled — We\'ll recommend artisans after submission.';

  @override
  String get createRequestStep4AiDisabled =>
      'Disabled — Manual artisan selection';

  @override
  String get createRequestStep4AiOn => 'ON';

  @override
  String get createRequestStep4AiOff => 'OFF';

  @override
  String get createRequestStep4LegalNote =>
      'By submitting, you agree to receive quotations from verified artisans.';

  @override
  String get createRequestSuccessTitle => 'Request Submitted';

  @override
  String get createRequestSuccessBodyNoAi =>
      'Your request is now visible to verified artisans near your location. You\'ll start receiving quotations shortly.';

  @override
  String get createRequestSuccessBodyAi =>
      'AI is analyzing your request and finding the best artisans for your job. You\'ll see recommendations in a moment.';

  @override
  String get createRequestSuccessAnalyzing => 'Analyzing';

  @override
  String get createRequestSuccessSeeArtisans => 'See Recommended Artisans';

  @override
  String get createRequestSuccessViewRequest => 'View Request';

  @override
  String get createRequestSuccessBackHome => 'Back to Home';

  @override
  String get createRequestSuccessComingSoon =>
      'Request tracking is coming in the next release.';

  @override
  String get artisanSelectionTitle => 'Choose an Artisan';

  @override
  String get artisanSelectionBreadcrumbService => 'Plumbing';

  @override
  String get artisanSortTopRated => 'Top rated';

  @override
  String get artisanSortNearest => 'Nearest';

  @override
  String get artisanSortMostExperienced => 'Most experienced';

  @override
  String get artisanFilterVerifiedOnly => 'Verified only';

  @override
  String get artisanReviewsSuffix => 'reviews';

  @override
  String get artisanChipRespondsFast => 'Responds fast';

  @override
  String get artisanProfileAbout => 'About';

  @override
  String get artisanProfileAvailability => 'Availability';

  @override
  String get artisanProfilePrice => 'Price';

  @override
  String get artisanProfilePriceNote =>
      'Quotation-based. You\'ll receive a detailed quote after the artisan reviews your request.';

  @override
  String get artisanProfileSelect => 'Select This Artisan';

  @override
  String get artisanProfileBackToList => 'Back to list';

  @override
  String get artisanSelectionEmptyTitle => 'No artisans available';

  @override
  String get artisanSelectionEmptyBody =>
      'We couldn\'t find any verified artisans for this request right now.';

  @override
  String get artisanSelectionEmptyBack => 'Back';

  @override
  String selectionConfirmationTitle(String name) {
    return 'Send request to $name?';
  }

  @override
  String get selectionConfirmationBody =>
      'The artisan will receive your request and can accept or decline. If they accept, they\'ll send you a detailed quotation.';

  @override
  String get selectionConfirmationRequestLabel => 'Request';

  @override
  String get selectionConfirmationDateLabel => 'Preferred date';

  @override
  String get selectionConfirmationSend => 'Send Request';

  @override
  String get selectionConfirmationCancel => 'Cancel';

  @override
  String get requestSentTitle => 'Request sent';

  @override
  String requestSentBody(String name) {
    return '$name has been notified. They\'ll review your request and respond shortly.';
  }

  @override
  String get requestSentBackHome => 'Back to Home';

  @override
  String get requestSentViewRequest => 'View Request';

  @override
  String get createRequestSuccessBrowseArtisans => 'Browse Artisans';

  @override
  String get aiUnderstandTitle => 'Improve with AI';

  @override
  String get aiUnderstandDescription =>
      'Optional. AI can suggest the problem type, urgency, and useful details. You always decide what to keep.';

  @override
  String get aiUnderstandButton => 'Improve with AI';

  @override
  String get aiUnderstandLoading => 'Analyzing your description…';

  @override
  String get aiProblemTypeLabel => 'Problem type';

  @override
  String get aiUrgencyLabel => 'Urgency';

  @override
  String get aiUsefulContextLabel => 'Useful context';

  @override
  String get aiMissingInfoLabel => 'Consider adding';

  @override
  String get aiUseSuggestion => 'Use this';

  @override
  String get aiDismiss => 'Dismiss';

  @override
  String get aiAdvisoryDisclaimer =>
      'AI suggestions are advisory. You can edit or ignore them.';

  @override
  String get aiUnavailableMessage =>
      'AI assistance is currently unavailable. You can continue manually.';

  @override
  String get aiLowConfidenceMessage =>
      'AI couldn\'t confidently interpret this description. You can continue manually.';

  @override
  String get aiQuotationTitle => 'Analyze Quotation';

  @override
  String get aiQuotationDescription =>
      'Optional. AI can flag unusual pricing and highlight missing details. You decide whether to accept or reject.';

  @override
  String get aiQuotationAnalyzeButton => 'Analyze Quotation';

  @override
  String get aiQuotationLoading => 'Analyzing the quotation…';

  @override
  String get aiQuotationFlagged => 'Some details look unusual';

  @override
  String get aiQuotationLooksTypical => 'No unusual patterns detected';

  @override
  String get aiQuotationNoQuote => 'There is no quotation to analyze yet.';

  @override
  String aiQuotationConfidence(int score) {
    return 'Confidence: $score%';
  }

  @override
  String createRequestStep1PhotoCount(int current, int max) {
    return '$current of $max photos';
  }

  @override
  String createRequestStep1PhotoLimitReached(int max) {
    return 'You can add up to $max photos.';
  }

  @override
  String get createRequestStep1CameraDenied =>
      'Camera access is off. Enable it in your device settings to take photos.';

  @override
  String get createRequestStep1GalleryDenied =>
      'Photo access is off. Enable it in your device settings to choose photos.';

  @override
  String get createRequestStep1PhotoPickFailed =>
      'We couldn\'t add that photo. Please try again.';

  @override
  String get createRequestStep2UseCurrentLocation => 'Use my current location';

  @override
  String get createRequestStep2Or => 'or';

  @override
  String get createRequestStep2ApproximateTitle => 'Address entered';

  @override
  String get createRequestStep2LocationUnavailable =>
      'We couldn\'t get your location right now. You can still type your address manually.';

  @override
  String get createRequestStep2SuggestionUse => 'Use this address';

  @override
  String get createRequestStep2SuggestionDismiss => 'Dismiss';

  @override
  String get trackingCancelDialogTitle => 'Cancel this request?';

  @override
  String get trackingCancelDialogBody =>
      'This cannot be undone. No work will be performed. If funds were held, they will be refunded according to the platform workflow.';

  @override
  String get trackingCancelReasonHint => 'Reason for cancelling (required)';

  @override
  String get trackingCancelReasonRequired => 'Please provide a reason.';

  @override
  String get trackingCancelConfirm => 'Cancel request';

  @override
  String get trackingCancelFailed =>
      'Could not cancel the request. Please try again.';

  @override
  String get commonKeepIt => 'Keep it';

  @override
  String get mapTitle => 'Artisans nearby';

  @override
  String get mapSearchHint => 'Search artisans or services';

  @override
  String get mapFilterAll => 'All';

  @override
  String get mapWithinKm => 'Within 5 km';

  @override
  String mapArtisanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artisans',
      one: '1 artisan',
      zero: 'No artisans',
    );
    return '$_temp0 nearby';
  }

  @override
  String get mapSeeAll => 'See all';

  @override
  String get mapViewProfile => 'View profile';

  @override
  String get mapMessage => 'Message';

  @override
  String get mapVerified => 'VERIFIED';

  @override
  String mapKmAway(String km) {
    return '$km km away';
  }

  @override
  String get mapEmptyTitle => 'No artisans here yet';

  @override
  String get mapEmptyBody => 'Try panning the map or changing your filter.';

  @override
  String get mapResetFilters => 'Reset filters';

  @override
  String mapJobsCount(int count) {
    return '($count jobs)';
  }

  @override
  String get mapRecenter => 'Recenter on me';

  @override
  String get mapListView => 'List view';
}
