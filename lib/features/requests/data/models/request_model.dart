import '../../domain/entities/request.dart';

class ItemRequestModel extends ItemRequest {
  const ItemRequestModel({
    required super.id,
    required super.requesterId,
    required super.category,
    required super.itemName,
    required super.description,
    super.budgetPerDay,
    super.durationDays,
    super.startDate,
    super.endDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ItemRequestModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['created_at'] as String);
    return ItemRequestModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String? ?? '',
      category: json['category'] as String,
      itemName: json['item_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      budgetPerDay: (json['budget_per_day'] as num?)?.toDouble(),
      durationDays: json['duration_days'] as int?,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'] as String)
          : null,
      status: json['status'] as String? ?? 'open',
      createdAt: createdAt,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          createdAt,
    );
  }

  Map<String, dynamic> toCreateJson(double lat, double lng) {
    final data = <String, dynamic>{
      // Do NOT include id or requester_id — let DB defaults handle them
      'category': category,
      'item_name': itemName,
      'description': description,
      'budget_per_day': budgetPerDay,
      'duration_days': durationDays,
      'location': 'POINT($lng $lat)',
    };
    if (startDate != null) {
      data['start_date'] = startDate!.toIso8601String().substring(0, 10);
    }
    if (endDate != null) {
      data['end_date'] = endDate!.toIso8601String().substring(0, 10);
    }
    return data;
  }
}
