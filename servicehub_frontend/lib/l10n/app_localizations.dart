import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Application name shown in the app bar and splash screen
  ///
  /// In en, this message translates to:
  /// **'ServiceHUB'**
  String get appName;

  /// Main headline on the public landing page
  ///
  /// In en, this message translates to:
  /// **'Find trusted artisans for your service needs'**
  String get landingHeadline;

  /// Three-word trust tagline under the headline
  ///
  /// In en, this message translates to:
  /// **'Verified. Secure. Local.'**
  String get landingTagline;

  /// Primary call-to-action on the landing page
  ///
  /// In en, this message translates to:
  /// **'Find a Service'**
  String get landingCtaPrimary;

  /// Secondary call-to-action on the landing page
  ///
  /// In en, this message translates to:
  /// **'Browse Artisans'**
  String get landingCtaSecondary;

  /// Login link on the landing page
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get landingLoginLink;

  /// Register link on the landing page
  ///
  /// In en, this message translates to:
  /// **'New here? Register'**
  String get landingRegisterLink;

  /// Prefix text before the Login link on the landing page
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get landingAuthPrefixLogin;

  /// Login link label on the landing page
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get landingAuthActionLogin;

  /// Prefix text before the Register link on the landing page
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get landingAuthPrefixRegister;

  /// Register link label on the landing page
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get landingAuthActionRegister;

  /// Trust block section title
  ///
  /// In en, this message translates to:
  /// **'Trusted • Secure • Local'**
  String get landingTrustTitle;

  /// First trust point on the landing page
  ///
  /// In en, this message translates to:
  /// **'Verified artisans'**
  String get landingTrustVerified;

  /// Second trust point on the landing page
  ///
  /// In en, this message translates to:
  /// **'Protected payments'**
  String get landingTrustPayments;

  /// Third trust point on the landing page
  ///
  /// In en, this message translates to:
  /// **'Local service professionals'**
  String get landingTrustLocal;

  /// Sample artisan preview link
  ///
  /// In en, this message translates to:
  /// **'View a sample artisan'**
  String get landingSampleCta;

  /// App bar title on the service categories screen
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// Main heading on the service categories screen
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get servicesHeading;

  /// Subheading on the service categories screen
  ///
  /// In en, this message translates to:
  /// **'Choose a service to get started'**
  String get servicesSubheading;

  /// Primary action button on the service categories screen
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get servicesBookNow;

  /// Plumbing category name
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get categoryPlumbing;

  /// Plumbing category description
  ///
  /// In en, this message translates to:
  /// **'Leaks, pipes, installations'**
  String get categoryPlumbingDesc;

  /// Electrical category name
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get categoryElectrical;

  /// Electrical category description
  ///
  /// In en, this message translates to:
  /// **'Wiring, sockets, repairs'**
  String get categoryElectricalDesc;

  /// Carpentry category name
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get categoryCarpentry;

  /// Carpentry category description
  ///
  /// In en, this message translates to:
  /// **'Furniture, doors, shelves'**
  String get categoryCarpentryDesc;

  /// Painting category name
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get categoryPainting;

  /// Painting category description
  ///
  /// In en, this message translates to:
  /// **'Interior, exterior, touch-ups'**
  String get categoryPaintingDesc;

  /// Masonry category name
  ///
  /// In en, this message translates to:
  /// **'Masonry'**
  String get categoryMasonry;

  /// Masonry category description
  ///
  /// In en, this message translates to:
  /// **'Walls, tiles, concrete'**
  String get categoryMasonryDesc;

  /// Mechanics category name
  ///
  /// In en, this message translates to:
  /// **'Mechanics'**
  String get categoryMechanics;

  /// Mechanics category description
  ///
  /// In en, this message translates to:
  /// **'Vehicle and equipment repair'**
  String get categoryMechanicsDesc;

  /// Title on the login prompt bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Log in to continue'**
  String get loginPromptTitle;

  /// Body text on the login prompt bottom sheet
  ///
  /// In en, this message translates to:
  /// **'You need an account to create a service request.'**
  String get loginPromptBody;

  /// Log in button on the login prompt bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginPromptLogin;

  /// Create account button on the login prompt bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get loginPromptRegister;

  /// Continue browsing link on the login prompt bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Continue browsing'**
  String get loginPromptContinueBrowsing;

  /// App bar title for the create request wizard
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get createRequestTitle;

  /// Progress step caption in the wizard
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String createRequestStepLabel(int current, int total);

  /// Continue button on wizard steps
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get createRequestContinue;

  /// Submit button on the final wizard step
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get createRequestSubmit;

  /// Heading on wizard step 1
  ///
  /// In en, this message translates to:
  /// **'Describe what you need done'**
  String get createRequestStep1Heading;

  /// Placeholder for the description field on wizard step 1
  ///
  /// In en, this message translates to:
  /// **'Tell us about the job. Include details like what\'s broken, where it is, and any other context.'**
  String get createRequestStep1DescriptionHint;

  /// Photo upload section label on wizard step 1
  ///
  /// In en, this message translates to:
  /// **'Add photos (optional)'**
  String get createRequestStep1PhotoLabel;

  /// Photo upload helper text on wizard step 1
  ///
  /// In en, this message translates to:
  /// **'Photos help artisans give accurate quotations.'**
  String get createRequestStep1PhotoHint;

  /// Take photo button label
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get createRequestStep1TakePhoto;

  /// Choose from gallery button label
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get createRequestStep1ChooseGallery;

  /// Urgency section label on wizard step 1
  ///
  /// In en, this message translates to:
  /// **'How urgent is this?'**
  String get createRequestStep1UrgencyLabel;

  /// Low urgency label
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get createRequestStep1UrgencyLow;

  /// Low urgency description
  ///
  /// In en, this message translates to:
  /// **'Within a week'**
  String get createRequestStep1UrgencyLowDesc;

  /// Medium urgency label
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get createRequestStep1UrgencyMedium;

  /// Medium urgency description
  ///
  /// In en, this message translates to:
  /// **'Within 2-3 days'**
  String get createRequestStep1UrgencyMediumDesc;

  /// High urgency label
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get createRequestStep1UrgencyHigh;

  /// High urgency description
  ///
  /// In en, this message translates to:
  /// **'Within 24 hours'**
  String get createRequestStep1UrgencyHighDesc;

  /// AI assist card title
  ///
  /// In en, this message translates to:
  /// **'AI-Assisted Matching'**
  String get createRequestStep1AiTitle;

  /// AI assist card description
  ///
  /// In en, this message translates to:
  /// **'Let AI analyze your request and recommend artisans best suited to your job. You can still browse and choose manually.'**
  String get createRequestStep1AiDescription;

  /// Heading on wizard step 3
  ///
  /// In en, this message translates to:
  /// **'When would you like this done?'**
  String get createRequestStep3Heading;

  /// Subheading on wizard step 3
  ///
  /// In en, this message translates to:
  /// **'Choose a preferred time window. The artisan will confirm a specific time with you.'**
  String get createRequestStep3Subheading;

  /// Date picker section label
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get createRequestStep3SelectDate;

  /// Confirmation line showing the selected date
  ///
  /// In en, this message translates to:
  /// **'Selected: {date}'**
  String createRequestStep3SelectedDate(String date);

  /// Time window section label
  ///
  /// In en, this message translates to:
  /// **'Preferred time window'**
  String get createRequestStep3TimeWindowLabel;

  /// Earliest time field label
  ///
  /// In en, this message translates to:
  /// **'Earliest'**
  String get createRequestStep3EarliestLabel;

  /// Latest time field label
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get createRequestStep3LatestLabel;

  /// Flexible toggle title
  ///
  /// In en, this message translates to:
  /// **'I\'m flexible'**
  String get createRequestStep3FlexibleTitle;

  /// Flexible toggle description
  ///
  /// In en, this message translates to:
  /// **'The artisan will propose a time that works for both of you.'**
  String get createRequestStep3FlexibleDescription;

  /// Additional notes section label
  ///
  /// In en, this message translates to:
  /// **'Additional notes (optional)'**
  String get createRequestStep3NotesLabel;

  /// Additional notes placeholder
  ///
  /// In en, this message translates to:
  /// **'Any special instructions?'**
  String get createRequestStep3NotesHint;

  /// Heading on wizard step 2
  ///
  /// In en, this message translates to:
  /// **'Where do you need the service?'**
  String get createRequestStep2Heading;

  /// Subheading on wizard step 2
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this to find artisans in your area.'**
  String get createRequestStep2Subheading;

  /// Placeholder for the address search field
  ///
  /// In en, this message translates to:
  /// **'Search for an address or landmark'**
  String get createRequestStep2SearchHint;

  /// Label under the map pin when an address is entered
  ///
  /// In en, this message translates to:
  /// **'Address set'**
  String get createRequestStep2PinActive;

  /// Label under the map pin when no address is entered
  ///
  /// In en, this message translates to:
  /// **'Enter an address'**
  String get createRequestStep2PinInactive;

  /// Caption shown in the map placeholder
  ///
  /// In en, this message translates to:
  /// **'Map preview available in the next release'**
  String get createRequestStep2MapPlaceholder;

  /// Title of the address confirmation card
  ///
  /// In en, this message translates to:
  /// **'Confirmed location'**
  String get createRequestStep2ConfirmedTitle;

  /// Heading on wizard step 4
  ///
  /// In en, this message translates to:
  /// **'Review your request'**
  String get createRequestStep4Heading;

  /// Subheading on wizard step 4
  ///
  /// In en, this message translates to:
  /// **'Check the details below. You can edit any section before submitting.'**
  String get createRequestStep4Subheading;

  /// Job section label on review
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get createRequestStep4JobLabel;

  /// Location section label on review
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get createRequestStep4LocationLabel;

  /// Fallback text when no location is present
  ///
  /// In en, this message translates to:
  /// **'No location set'**
  String get createRequestStep4LocationMissing;

  /// Schedule section label on review
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get createRequestStep4ScheduleLabel;

  /// Schedule headline when the user is flexible
  ///
  /// In en, this message translates to:
  /// **'Flexible scheduling'**
  String get createRequestStep4ScheduleFlexible;

  /// Fallback text when no schedule is present
  ///
  /// In en, this message translates to:
  /// **'No schedule set'**
  String get createRequestStep4ScheduleMissing;

  /// Label before the time window
  ///
  /// In en, this message translates to:
  /// **'Preferred window'**
  String get createRequestStep4PreferredWindow;

  /// AI section label on review
  ///
  /// In en, this message translates to:
  /// **'AI-Assisted Matching'**
  String get createRequestStep4AiLabel;

  /// AI enabled status text
  ///
  /// In en, this message translates to:
  /// **'Enabled — We\'ll recommend artisans after submission.'**
  String get createRequestStep4AiEnabled;

  /// AI disabled status text
  ///
  /// In en, this message translates to:
  /// **'Disabled — Manual artisan selection'**
  String get createRequestStep4AiDisabled;

  /// AI ON pill
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get createRequestStep4AiOn;

  /// AI OFF pill
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get createRequestStep4AiOff;

  /// Legal note on review screen
  ///
  /// In en, this message translates to:
  /// **'By submitting, you agree to receive quotations from verified artisans.'**
  String get createRequestStep4LegalNote;

  /// Success screen title
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get createRequestSuccessTitle;

  /// Success body when AI assist is off
  ///
  /// In en, this message translates to:
  /// **'Your request is now visible to verified artisans near your location. You\'ll start receiving quotations shortly.'**
  String get createRequestSuccessBodyNoAi;

  /// Success body when AI assist is on
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing your request and finding the best artisans for your job. You\'ll see recommendations in a moment.'**
  String get createRequestSuccessBodyAi;

  /// Analyzing indicator label
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get createRequestSuccessAnalyzing;

  /// Primary CTA for AI ON success
  ///
  /// In en, this message translates to:
  /// **'See Recommended Artisans'**
  String get createRequestSuccessSeeArtisans;

  /// View request CTA
  ///
  /// In en, this message translates to:
  /// **'View Request'**
  String get createRequestSuccessViewRequest;

  /// Back to home link
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get createRequestSuccessBackHome;

  /// Placeholder snackbar text
  ///
  /// In en, this message translates to:
  /// **'Request tracking is coming in the next release.'**
  String get createRequestSuccessComingSoon;

  /// Title of the artisan selection screen
  ///
  /// In en, this message translates to:
  /// **'Choose an Artisan'**
  String get artisanSelectionTitle;

  /// Service name shown in the artisan selection breadcrumb
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get artisanSelectionBreadcrumbService;

  /// Sort chip: highest rating first
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get artisanSortTopRated;

  /// Sort chip: closest first
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get artisanSortNearest;

  /// Sort chip: most years of experience first
  ///
  /// In en, this message translates to:
  /// **'Most experienced'**
  String get artisanSortMostExperienced;

  /// Filter chip: show only verified artisans
  ///
  /// In en, this message translates to:
  /// **'Verified only'**
  String get artisanFilterVerifiedOnly;

  /// Suffix after the review count, e.g. 42 reviews
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get artisanReviewsSuffix;

  /// Chip shown when the artisan's response rate is high
  ///
  /// In en, this message translates to:
  /// **'Responds fast'**
  String get artisanChipRespondsFast;

  /// Section heading on the artisan profile
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get artisanProfileAbout;

  /// Section heading on the artisan profile
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get artisanProfileAvailability;

  /// Section heading on the artisan profile
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get artisanProfilePrice;

  /// Explains the quotation-based pricing model
  ///
  /// In en, this message translates to:
  /// **'Quotation-based. You\'ll receive a detailed quote after the artisan reviews your request.'**
  String get artisanProfilePriceNote;

  /// Primary CTA on the artisan profile
  ///
  /// In en, this message translates to:
  /// **'Select This Artisan'**
  String get artisanProfileSelect;

  /// Secondary action on the artisan profile
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get artisanProfileBackToList;

  /// Empty state title when no artisans match
  ///
  /// In en, this message translates to:
  /// **'No artisans available'**
  String get artisanSelectionEmptyTitle;

  /// Empty state body when no artisans match
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find any verified artisans for this request right now.'**
  String get artisanSelectionEmptyBody;

  /// Empty state back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get artisanSelectionEmptyBack;

  /// Confirmation sheet title with artisan name
  ///
  /// In en, this message translates to:
  /// **'Send request to {name}?'**
  String selectionConfirmationTitle(String name);

  /// Confirmation sheet body text
  ///
  /// In en, this message translates to:
  /// **'The artisan will receive your request and can accept or decline. If they accept, they\'ll send you a detailed quotation.'**
  String get selectionConfirmationBody;

  /// Label in the confirmation sheet reference card
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get selectionConfirmationRequestLabel;

  /// Label in the confirmation sheet reference card
  ///
  /// In en, this message translates to:
  /// **'Preferred date'**
  String get selectionConfirmationDateLabel;

  /// Primary CTA in the confirmation sheet
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get selectionConfirmationSend;

  /// Cancel button in the confirmation sheet
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get selectionConfirmationCancel;

  /// Title of the request sent page
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSentTitle;

  /// Body text on the request sent page
  ///
  /// In en, this message translates to:
  /// **'{name} has been notified. They\'ll review your request and respond shortly.'**
  String requestSentBody(String name);

  /// Return to customer home
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get requestSentBackHome;

  /// View the request tracking screen
  ///
  /// In en, this message translates to:
  /// **'View Request'**
  String get requestSentViewRequest;

  /// No description provided for @createRequestSuccessBrowseArtisans.
  ///
  /// In en, this message translates to:
  /// **'Browse Artisans'**
  String get createRequestSuccessBrowseArtisans;

  /// No description provided for @aiUnderstandTitle.
  ///
  /// In en, this message translates to:
  /// **'Improve with AI'**
  String get aiUnderstandTitle;

  /// No description provided for @aiUnderstandDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional. AI can suggest the problem type, urgency, and useful details. You always decide what to keep.'**
  String get aiUnderstandDescription;

  /// No description provided for @aiUnderstandButton.
  ///
  /// In en, this message translates to:
  /// **'Improve with AI'**
  String get aiUnderstandButton;

  /// No description provided for @aiUnderstandLoading.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your description…'**
  String get aiUnderstandLoading;

  /// No description provided for @aiProblemTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Problem type'**
  String get aiProblemTypeLabel;

  /// No description provided for @aiUrgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get aiUrgencyLabel;

  /// No description provided for @aiUsefulContextLabel.
  ///
  /// In en, this message translates to:
  /// **'Useful context'**
  String get aiUsefulContextLabel;

  /// No description provided for @aiMissingInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Consider adding'**
  String get aiMissingInfoLabel;

  /// No description provided for @aiUseSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get aiUseSuggestion;

  /// No description provided for @aiDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get aiDismiss;

  /// No description provided for @aiAdvisoryDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI suggestions are advisory. You can edit or ignore them.'**
  String get aiAdvisoryDisclaimer;

  /// No description provided for @aiUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'AI assistance is currently unavailable. You can continue manually.'**
  String get aiUnavailableMessage;

  /// No description provided for @aiLowConfidenceMessage.
  ///
  /// In en, this message translates to:
  /// **'AI couldn\'t confidently interpret this description. You can continue manually.'**
  String get aiLowConfidenceMessage;

  /// No description provided for @aiQuotationTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze Quotation'**
  String get aiQuotationTitle;

  /// No description provided for @aiQuotationDescription.
  ///
  /// In en, this message translates to:
  /// **'Optional. AI can flag unusual pricing and highlight missing details. You decide whether to accept or reject.'**
  String get aiQuotationDescription;

  /// No description provided for @aiQuotationAnalyzeButton.
  ///
  /// In en, this message translates to:
  /// **'Analyze Quotation'**
  String get aiQuotationAnalyzeButton;

  /// No description provided for @aiQuotationLoading.
  ///
  /// In en, this message translates to:
  /// **'Analyzing the quotation…'**
  String get aiQuotationLoading;

  /// No description provided for @aiQuotationFlagged.
  ///
  /// In en, this message translates to:
  /// **'Some details look unusual'**
  String get aiQuotationFlagged;

  /// No description provided for @aiQuotationLooksTypical.
  ///
  /// In en, this message translates to:
  /// **'No unusual patterns detected'**
  String get aiQuotationLooksTypical;

  /// No description provided for @aiQuotationNoQuote.
  ///
  /// In en, this message translates to:
  /// **'There is no quotation to analyze yet.'**
  String get aiQuotationNoQuote;

  /// No description provided for @aiQuotationConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {score}%'**
  String aiQuotationConfidence(int score);

  /// No description provided for @createRequestStep1PhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{current} of {max} photos'**
  String createRequestStep1PhotoCount(int current, int max);

  /// No description provided for @createRequestStep1PhotoLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to {max} photos.'**
  String createRequestStep1PhotoLimitReached(int max);

  /// No description provided for @createRequestStep1CameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is off. Enable it in your device settings to take photos.'**
  String get createRequestStep1CameraDenied;

  /// No description provided for @createRequestStep1GalleryDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo access is off. Enable it in your device settings to choose photos.'**
  String get createRequestStep1GalleryDenied;

  /// No description provided for @createRequestStep1PhotoPickFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t add that photo. Please try again.'**
  String get createRequestStep1PhotoPickFailed;

  /// No description provided for @createRequestStep2UseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get createRequestStep2UseCurrentLocation;

  /// No description provided for @createRequestStep2Or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get createRequestStep2Or;

  /// No description provided for @createRequestStep2ApproximateTitle.
  ///
  /// In en, this message translates to:
  /// **'Address entered'**
  String get createRequestStep2ApproximateTitle;

  /// No description provided for @createRequestStep2LocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t get your location right now. You can still type your address manually.'**
  String get createRequestStep2LocationUnavailable;

  /// No description provided for @createRequestStep2SuggestionUse.
  ///
  /// In en, this message translates to:
  /// **'Use this address'**
  String get createRequestStep2SuggestionUse;

  /// No description provided for @createRequestStep2SuggestionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get createRequestStep2SuggestionDismiss;

  /// No description provided for @trackingCancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get trackingCancelDialogTitle;

  /// No description provided for @trackingCancelDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. No work will be performed. If funds were held, they will be refunded according to the platform workflow.'**
  String get trackingCancelDialogBody;

  /// No description provided for @trackingCancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for cancelling (required)'**
  String get trackingCancelReasonHint;

  /// No description provided for @trackingCancelReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason.'**
  String get trackingCancelReasonRequired;

  /// No description provided for @trackingCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get trackingCancelConfirm;

  /// No description provided for @trackingCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the request. Please try again.'**
  String get trackingCancelFailed;

  /// No description provided for @commonKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get commonKeepIt;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Artisans nearby'**
  String get mapTitle;

  /// No description provided for @mapSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search artisans or services'**
  String get mapSearchHint;

  /// No description provided for @mapFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mapFilterAll;

  /// No description provided for @mapWithinKm.
  ///
  /// In en, this message translates to:
  /// **'Within 5 km'**
  String get mapWithinKm;

  /// No description provided for @mapArtisanCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No artisans} =1{1 artisan} other{{count} artisans}} nearby'**
  String mapArtisanCount(int count);

  /// No description provided for @mapSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get mapSeeAll;

  /// No description provided for @mapViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get mapViewProfile;

  /// No description provided for @mapMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get mapMessage;

  /// No description provided for @mapVerified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get mapVerified;

  /// No description provided for @mapKmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String mapKmAway(String km);

  /// No description provided for @mapEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No artisans here yet'**
  String get mapEmptyTitle;

  /// No description provided for @mapEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Try panning the map or changing your filter.'**
  String get mapEmptyBody;

  /// No description provided for @mapResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get mapResetFilters;

  /// No description provided for @mapJobsCount.
  ///
  /// In en, this message translates to:
  /// **'({count} jobs)'**
  String mapJobsCount(int count);

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter on me'**
  String get mapRecenter;

  /// No description provided for @mapListView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get mapListView;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
