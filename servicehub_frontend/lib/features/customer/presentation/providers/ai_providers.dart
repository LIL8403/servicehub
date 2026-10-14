import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/ai_repository.dart';
import '../../domain/models/quotation_analysis.dart';
import '../../domain/models/request_understanding.dart';

// ─────────────────────────────────────────────────────────────
// Repository wiring
// ─────────────────────────────────────────────────────────────

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AiRepository(apiService: api);
});

// ─────────────────────────────────────────────────────────────
// Draft understanding (wizard — Step 1)
// ─────────────────────────────────────────────────────────────

/// UI state for the wizard's optional "Improve with AI" action.
class DraftUnderstandingState {
  const DraftUnderstandingState({
    this.isLoading = false,
    this.understanding,
    this.errorMessage,
  });

  final bool isLoading;
  final RequestUnderstanding? understanding;
  final String? errorMessage;

  bool get hasResult => understanding != null;
}

class DraftUnderstandingNotifier
    extends StateNotifier<DraftUnderstandingState> {
  DraftUnderstandingNotifier(this._ref)
      : super(const DraftUnderstandingState());

  final Ref _ref;

  Future<void> analyze({
    required String description,
    String? serviceId,
    Map<String, dynamic>? preferredSchedule,
  }) async {
    state = const DraftUnderstandingState(isLoading: true);

    try {
      final result = await _ref
          .read(aiRepositoryProvider)
          .understandDraft(
            description: description,
            serviceId: serviceId,
            preferredSchedule: preferredSchedule,
          );
      if (!mounted) return;
      state = DraftUnderstandingState(understanding: result);
    } on ApiException catch (e) {
      if (!mounted) return;
      state = DraftUnderstandingState(errorMessage: e.firstErrorMessage);
    } catch (_) {
      if (!mounted) return;
      state = const DraftUnderstandingState(
        errorMessage: 'AI assistance is currently unavailable.',
      );
    }
  }

  void clear() {
    state = const DraftUnderstandingState();
  }
}

final draftUnderstandingProvider = StateNotifierProvider.autoDispose<
    DraftUnderstandingNotifier, DraftUnderstandingState>(
  (ref) => DraftUnderstandingNotifier(ref),
);

// ─────────────────────────────────────────────────────────────
// Quotation analysis (tracking — QuotationReceivedView)
// ─────────────────────────────────────────────────────────────

class QuotationAnalysisState {
  const QuotationAnalysisState({
    this.isLoading = false,
    this.analysis,
    this.errorMessage,
  });

  final bool isLoading;
  final QuotationAnalysis? analysis;
  final String? errorMessage;

  bool get hasResult => analysis != null;
}

class QuotationAnalysisNotifier
    extends StateNotifier<QuotationAnalysisState> {
  QuotationAnalysisNotifier(this._ref) : super(const QuotationAnalysisState());

  final Ref _ref;

  Future<void> analyze(String requestId) async {
    state = const QuotationAnalysisState(isLoading: true);

    try {
      final result =
          await _ref.read(aiRepositoryProvider).analyzeQuotation(requestId);
      if (!mounted) return;
      state = QuotationAnalysisState(analysis: result);
    } on ApiException catch (e) {
      if (!mounted) return;
      state = QuotationAnalysisState(errorMessage: e.firstErrorMessage);
    } catch (_) {
      if (!mounted) return;
      state = const QuotationAnalysisState(
        errorMessage: 'AI analysis is currently unavailable.',
      );
    }
  }

  void clear() {
    state = const QuotationAnalysisState();
  }
}

final quotationAnalysisProvider = StateNotifierProvider.autoDispose<
    QuotationAnalysisNotifier, QuotationAnalysisState>(
  (ref) => QuotationAnalysisNotifier(ref),
);