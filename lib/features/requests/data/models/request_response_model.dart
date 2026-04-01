import '../../domain/entities/request_response.dart';

class RequestResponseModel extends RequestResponse {
  const RequestResponseModel({
    required super.id,
    required super.requestId,
    required super.responderId,
    required super.responderName,
    required super.responderAvatarUrl,
    required super.status,
    super.message,
    required super.createdAt,
  });

  factory RequestResponseModel.fromJson(Map<String, dynamic> json) {
    // The responder info may come from a joined 'users' table
    final responder = json['users'] as Map<String, dynamic>?;
    return RequestResponseModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      responderId: json['responder_id'] as String,
      responderName: responder?['full_name'] as String? ?? '',
      responderAvatarUrl: responder?['avatar_url'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
