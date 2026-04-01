import '../../domain/entities/report.dart';

class ReportModel extends Report {
  const ReportModel({
    required super.id,
    required super.reporterId,
    super.reportedItemId,
    required super.itemType,
    required super.reason,
    super.description,
    required super.status,
    required super.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedItemId: json['reported_item_id'] as String?,
      itemType: json['item_type'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
