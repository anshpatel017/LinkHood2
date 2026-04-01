import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/report_repository.dart';
import '../../data/repositories/report_repository_impl.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReportRepositoryImpl(client);
});

final reportControllerProvider = Provider<ReportController>((ref) {
  return ReportController(ref);
});

class ReportController {
  final Ref _ref;
  ReportController(this._ref);

  Future<void> submitReport({
    required String itemType,
    required String reason,
    String? reportedItemId,
    String? description,
  }) async {
    final repo = _ref.read(reportRepositoryProvider);
    await repo.submitReport(
      itemType: itemType,
      reason: reason,
      reportedItemId: reportedItemId,
      description: description,
    );
  }
}
