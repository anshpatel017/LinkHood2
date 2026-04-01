class RequestResponse {
  final String id;
  final String requestId;
  final String responderId;
  final String responderName;
  final String responderAvatarUrl;
  final String status; // 'pending' | 'accepted' | 'declined'
  final String? message;
  final DateTime createdAt;

  const RequestResponse({
    required this.id,
    required this.requestId,
    required this.responderId,
    required this.responderName,
    required this.responderAvatarUrl,
    required this.status,
    this.message,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
}
