class Report {
  final String id;
  final String reporterId;
  final String? reportedItemId;
  final String itemType;
  final String reason;
  final String? description;
  final String status;
  final DateTime createdAt;

  const Report({
    required this.id,
    required this.reporterId,
    this.reportedItemId,
    required this.itemType,
    required this.reason,
    this.description,
    required this.status,
    required this.createdAt,
  });
}
