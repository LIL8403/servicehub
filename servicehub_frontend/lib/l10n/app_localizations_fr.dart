// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'ServiceHUB';

  @override
  String get landingHeadline =>
      'Trouvez des artisans de confiance pour vos besoins';

  @override
  String get landingTagline => 'Vérifié. Sécurisé. Local.';

  @override
  String get landingCtaPrimary => 'Trouver un service';

  @override
  String get landingCtaSecondary => 'Parcourir les artisans';

  @override
  String get landingLoginLink => 'Vous avez déjà un compte ? Connexion';

  @override
  String get landingRegisterLink => 'Nouveau ? Inscription';

  @override
  String get landingAuthPrefixLogin => 'Vous avez déjà un compte ? ';

  @override
  String get landingAuthActionLogin => 'Connexion';

  @override
  String get landingAuthPrefixRegister => 'Nouveau ? ';

  @override
  String get landingAuthActionRegister => 'Inscription';

  @override
  String get landingTrustTitle => 'Fiable • Sécurisé • Local';

  @override
  String get landingTrustVerified => 'Artisans vérifiés';

  @override
  String get landingTrustPayments => 'Paiements protégés';

  @override
  String get landingTrustLocal => 'Professionnels locaux';

  @override
  String get landingSampleCta => 'Voir un exemple d\'artisan';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesHeading => 'De quoi avez-vous besoin ?';

  @override
  String get servicesSubheading => 'Choisissez un service pour commencer';

  @override
  String get servicesBookNow => 'Réserver';

  @override
  String get categoryPlumbing => 'Plomberie';

  @override
  String get categoryPlumbingDesc => 'Fuites, tuyaux, installations';

  @override
  String get categoryElectrical => 'Électricité';

  @override
  String get categoryElectricalDesc => 'Câblage, prises, réparations';

  @override
  String get categoryCarpentry => 'Menuiserie';

  @override
  String get categoryCarpentryDesc => 'Meubles, portes, étagères';

  @override
  String get categoryPainting => 'Peinture';

  @override
  String get categoryPaintingDesc => 'Intérieur, extérieur, retouches';

  @override
  String get categoryMasonry => 'Maçonnerie';

  @override
  String get categoryMasonryDesc => 'Murs, carrelage, béton';

  @override
  String get categoryMechanics => 'Mécanique';

  @override
  String get categoryMechanicsDesc => 'Réparation de véhicules et équipements';

  @override
  String get loginPromptTitle => 'Connectez-vous pour continuer';

  @override
  String get loginPromptBody =>
      'Vous avez besoin d\'un compte pour créer une demande de service.';

  @override
  String get loginPromptLogin => 'Connexion';

  @override
  String get loginPromptRegister => 'Créer un compte';

  @override
  String get loginPromptContinueBrowsing => 'Continuer à parcourir';

  @override
  String get createRequestTitle => 'Créez une demande';

  @override
  String createRequestStepLabel(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get createRequestContinue => 'Continuer';

  @override
  String get createRequestSubmit => 'Soumettre la demande';

  @override
  String get createRequestStep1Heading => 'Décrivez ce que vous voulez faire';

  @override
  String get createRequestStep1DescriptionHint =>
      'Parlez-nous du travail. Incluez des détails comme ce qui est cassé, où c\'est, et tout autre contexte.';

  @override
  String get createRequestStep1PhotoLabel => 'Ajouter des photos (facultatif)';

  @override
  String get createRequestStep1PhotoHint =>
      'Les photos aident les artisans à donner des devis précis.';

  @override
  String get createRequestStep1TakePhoto => 'Prendre une photo';

  @override
  String get createRequestStep1ChooseGallery => 'Choisir dans la galerie';

  @override
  String get createRequestStep1UrgencyLabel => 'Quelle est l\'urgence ?';

  @override
  String get createRequestStep1UrgencyLow => 'Faible';

  @override
  String get createRequestStep1UrgencyLowDesc => 'Dans la semaine';

  @override
  String get createRequestStep1UrgencyMedium => 'Moyen';

  @override
  String get createRequestStep1UrgencyMediumDesc => 'Dans 2-3 jours';

  @override
  String get createRequestStep1UrgencyHigh => 'Élevé';

  @override
  String get createRequestStep1UrgencyHighDesc => 'Dans les 24 heures';

  @override
  String get createRequestStep1AiTitle => 'Correspondance assistée par IA';

  @override
  String get createRequestStep1AiDescription =>
      'Laissez l\'IA analyser votre demande et recommander les artisans les mieux adaptés. Vous pouvez toujours parcourir et choisir manuellement.';

  @override
  String get createRequestStep3Heading =>
      'Quand souhaitez-vous que ce soit fait ?';

  @override
  String get createRequestStep3Subheading =>
      'Choisissez un créneau horaire préféré. L\'artisan confirmera un horaire précis avec vous.';

  @override
  String get createRequestStep3SelectDate => 'Sélectionner la date';

  @override
  String createRequestStep3SelectedDate(String date) {
    return 'Sélectionné : $date';
  }

  @override
  String get createRequestStep3TimeWindowLabel => 'Créneau horaire préféré';

  @override
  String get createRequestStep3EarliestLabel => 'Au plus tôt';

  @override
  String get createRequestStep3LatestLabel => 'Au plus tard';

  @override
  String get createRequestStep3FlexibleTitle => 'Je suis flexible';

  @override
  String get createRequestStep3FlexibleDescription =>
      'L\'artisan proposera une heure qui convient aux deux parties.';

  @override
  String get createRequestStep3NotesLabel =>
      'Remarques supplémentaires (facultatif)';

  @override
  String get createRequestStep3NotesHint => 'Instructions particulières ?';

  @override
  String get createRequestStep2Heading => 'Où avez-vous besoin du service ?';

  @override
  String get createRequestStep2Subheading =>
      'Nous utiliserons cela pour trouver des artisans dans votre région.';

  @override
  String get createRequestStep2SearchHint =>
      'Rechercher une adresse ou un point de repère';

  @override
  String get createRequestStep2PinActive => 'Adresse définie';

  @override
  String get createRequestStep2PinInactive => 'Entrez une adresse';

  @override
  String get createRequestStep2MapPlaceholder =>
      'Aperçu de la carte dans la prochaine version';

  @override
  String get createRequestStep2ConfirmedTitle => 'Lieu confirmé';

  @override
  String get createRequestStep4Heading => 'Vérifiez votre demande';

  @override
  String get createRequestStep4Subheading =>
      'Vérifiez les détails ci-dessous. Vous pouvez modifier chaque section avant de soumettre.';

  @override
  String get createRequestStep4JobLabel => 'Travail';

  @override
  String get createRequestStep4LocationLabel => 'Lieu';

  @override
  String get createRequestStep4LocationMissing => 'Aucun lieu défini';

  @override
  String get createRequestStep4ScheduleLabel => 'Horaire';

  @override
  String get createRequestStep4ScheduleFlexible => 'Horaire flexible';

  @override
  String get createRequestStep4ScheduleMissing => 'Aucun horaire défini';

  @override
  String get createRequestStep4PreferredWindow => 'Créneau préféré';

  @override
  String get createRequestStep4AiLabel => 'Correspondance assistée par IA';

  @override
  String get createRequestStep4AiEnabled =>
      'Activé — Nous recommanderons des artisans après soumission.';

  @override
  String get createRequestStep4AiDisabled =>
      'Désactivé — Sélection manuelle des artisans';

  @override
  String get createRequestStep4AiOn => 'ON';

  @override
  String get createRequestStep4AiOff => 'OFF';

  @override
  String get createRequestStep4LegalNote =>
      'En soumettant, vous acceptez de recevoir des devis d\'artisans vérifiés.';

  @override
  String get createRequestSuccessTitle => 'Demande soumise';

  @override
  String get createRequestSuccessBodyNoAi =>
      'Votre demande est maintenant visible par les artisans vérifiés près de chez vous. Vous commencerez à recevoir des devis sous peu.';

  @override
  String get createRequestSuccessBodyAi =>
      'L\'IA analyse votre demande et recherche les meilleurs artisans pour votre travail. Vous verrez les recommandations dans un instant.';

  @override
  String get createRequestSuccessAnalyzing => 'Analyse';

  @override
  String get createRequestSuccessSeeArtisans => 'Voir les artisans recommandés';

  @override
  String get createRequestSuccessViewRequest => 'Voir la demande';

  @override
  String get createRequestSuccessBackHome => 'Retour à l\'accueil';

  @override
  String get createRequestSuccessComingSoon =>
      'Le suivi des demandes arrive dans la prochaine version.';

  @override
  String get artisanSelectionTitle => 'Choisir un artisan';

  @override
  String get artisanSelectionBreadcrumbService => 'Plomberie';

  @override
  String get artisanSortTopRated => 'Mieux notés';

  @override
  String get artisanSortNearest => 'Les plus proches';

  @override
  String get artisanSortMostExperienced => 'Les plus expérimentés';

  @override
  String get artisanFilterVerifiedOnly => 'Vérifiés uniquement';

  @override
  String get artisanReviewsSuffix => 'avis';

  @override
  String get artisanChipRespondsFast => 'Répond vite';

  @override
  String get artisanProfileAbout => 'À propos';

  @override
  String get artisanProfileAvailability => 'Disponibilité';

  @override
  String get artisanProfilePrice => 'Prix';

  @override
  String get artisanProfilePriceNote =>
      'Sur devis. Vous recevrez un devis détaillé après examen de votre demande par l\'artisan.';

  @override
  String get artisanProfileSelect => 'Sélectionner cet artisan';

  @override
  String get artisanProfileBackToList => 'Retour à la liste';

  @override
  String get artisanSelectionEmptyTitle => 'Aucun artisan disponible';

  @override
  String get artisanSelectionEmptyBody =>
      'Nous n\'avons trouvé aucun artisan vérifié pour cette demande pour le moment.';

  @override
  String get artisanSelectionEmptyBack => 'Retour';

  @override
  String selectionConfirmationTitle(String name) {
    return 'Envoyer la demande à $name ?';
  }

  @override
  String get selectionConfirmationBody =>
      'L\'artisan recevra votre demande et pourra l\'accepter ou la refuser. S\'il accepte, il vous enverra un devis détaillé.';

  @override
  String get selectionConfirmationRequestLabel => 'Demande';

  @override
  String get selectionConfirmationDateLabel => 'Date souhaitée';

  @override
  String get selectionConfirmationSend => 'Envoyer la demande';

  @override
  String get selectionConfirmationCancel => 'Annuler';

  @override
  String get requestSentTitle => 'Demande envoyée';

  @override
  String requestSentBody(String name) {
    return '$name a été notifié. Il examinera votre demande et répondra sous peu.';
  }

  @override
  String get requestSentBackHome => 'Retour à l\'accueil';

  @override
  String get requestSentViewRequest => 'Voir la demande';

  @override
  String get createRequestSuccessBrowseArtisans => 'Parcourir les artisans';

  @override
  String get aiUnderstandTitle => 'Améliorer avec l\'IA';

  @override
  String get aiUnderstandDescription =>
      'Facultatif. L\'IA peut suggérer le type de problème, l\'urgence et les détails utiles. C\'est vous qui décidez.';

  @override
  String get aiUnderstandButton => 'Améliorer avec l\'IA';

  @override
  String get aiUnderstandLoading => 'Analyse de votre description…';

  @override
  String get aiProblemTypeLabel => 'Type de problème';

  @override
  String get aiUrgencyLabel => 'Urgence';

  @override
  String get aiUsefulContextLabel => 'Contexte utile';

  @override
  String get aiMissingInfoLabel => 'À préciser';

  @override
  String get aiUseSuggestion => 'Utiliser';

  @override
  String get aiDismiss => 'Ignorer';

  @override
  String get aiAdvisoryDisclaimer =>
      'Les suggestions de l\'IA sont indicatives. Vous pouvez les modifier ou les ignorer.';

  @override
  String get aiUnavailableMessage =>
      'L\'assistance IA est momentanément indisponible. Vous pouvez continuer manuellement.';

  @override
  String get aiLowConfidenceMessage =>
      'L\'IA n\'a pas pu interpréter cette description avec confiance. Vous pouvez continuer manuellement.';

  @override
  String get aiQuotationTitle => 'Analyser le devis';

  @override
  String get aiQuotationDescription =>
      'Facultatif. L\'IA peut signaler des tarifs inhabituels et repérer des informations manquantes. C\'est vous qui décidez d\'accepter ou de refuser.';

  @override
  String get aiQuotationAnalyzeButton => 'Analyser le devis';

  @override
  String get aiQuotationLoading => 'Analyse du devis…';

  @override
  String get aiQuotationFlagged => 'Certains éléments semblent inhabituels';

  @override
  String get aiQuotationLooksTypical => 'Aucune anomalie détectée';

  @override
  String get aiQuotationNoQuote => 'Aucun devis à analyser pour le moment.';

  @override
  String aiQuotationConfidence(int score) {
    return 'Confiance : $score %';
  }

  @override
  String createRequestStep1PhotoCount(int current, int max) {
    return '$current sur $max photos';
  }

  @override
  String createRequestStep1PhotoLimitReached(int max) {
    return 'Vous pouvez ajouter jusqu\'à $max photos.';
  }

  @override
  String get createRequestStep1CameraDenied =>
      'L\'accès à la caméra est désactivé. Activez-le dans les réglages de votre appareil.';

  @override
  String get createRequestStep1GalleryDenied =>
      'L\'accès aux photos est désactivé. Activez-le dans les réglages de votre appareil.';

  @override
  String get createRequestStep1PhotoPickFailed =>
      'Impossible d\'ajouter cette photo. Veuillez réessayer.';

  @override
  String get createRequestStep2UseCurrentLocation =>
      'Utiliser ma position actuelle';

  @override
  String get createRequestStep2Or => 'ou';

  @override
  String get createRequestStep2ApproximateTitle => 'Adresse saisie';

  @override
  String get createRequestStep2LocationUnavailable =>
      'Impossible d\'obtenir votre position. Vous pouvez saisir votre adresse manuellement.';

  @override
  String get createRequestStep2SuggestionUse => 'Utiliser cette adresse';

  @override
  String get createRequestStep2SuggestionDismiss => 'Ignorer';

  @override
  String get trackingCancelDialogTitle => 'Annuler cette demande ?';

  @override
  String get trackingCancelDialogBody =>
      'Cette action est irréversible. Aucun travail ne sera effectué. Si des fonds ont été réservés, ils seront remboursés selon le processus de la plateforme.';

  @override
  String get trackingCancelReasonHint => 'Motif d\'annulation (obligatoire)';

  @override
  String get trackingCancelReasonRequired => 'Veuillez indiquer un motif.';

  @override
  String get trackingCancelConfirm => 'Annuler la demande';

  @override
  String get trackingCancelFailed =>
      'Impossible d\'annuler la demande. Veuillez réessayer.';

  @override
  String get commonKeepIt => 'Conserver';

  @override
  String get mapTitle => 'Artisans à proximité';

  @override
  String get mapSearchHint => 'Rechercher un artisan ou un service';

  @override
  String get mapFilterAll => 'Tous';

  @override
  String get mapWithinKm => 'Dans 5 km';

  @override
  String mapArtisanCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artisans',
      one: '1 artisan',
      zero: 'Aucun artisan',
    );
    return '$_temp0 à proximité';
  }

  @override
  String get mapSeeAll => 'Voir tout';

  @override
  String get mapViewProfile => 'Voir le profil';

  @override
  String get mapMessage => 'Message';

  @override
  String get mapVerified => 'VÉRIFIÉ';

  @override
  String mapKmAway(String km) {
    return 'à $km km';
  }

  @override
  String get mapEmptyTitle => 'Aucun artisan ici';

  @override
  String get mapEmptyBody =>
      'Essayez de déplacer la carte ou de modifier votre filtre.';

  @override
  String get mapResetFilters => 'Réinitialiser les filtres';

  @override
  String mapJobsCount(int count) {
    return '($count missions)';
  }

  @override
  String get mapRecenter => 'Recentrer sur moi';

  @override
  String get mapListView => 'Vue liste';
}
