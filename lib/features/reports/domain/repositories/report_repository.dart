import '../entities/report.dart';

abstract class ReportRepository {
  Future<Report> submitReport({
    required String itemType,
    required String reason,
    String? reportedItemId,
    String? description,
  });
}
