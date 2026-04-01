class ItemRequest {
  final String id;
  final String requesterId;
  final String category;
  final String itemName;
  final String description;
  final double? budgetPerDay;
  final int? durationDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemRequest({
    required this.id,
    required this.requesterId,
    required this.category,
    required this.itemName,
    required this.description,
    this.budgetPerDay,
    this.durationDays,
    this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}
