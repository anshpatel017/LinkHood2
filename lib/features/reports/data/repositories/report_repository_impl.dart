import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/report_repository.dart';
import '../models/report_model.dart';
import 'package:uuid/uuid.dart';

class ReportRepositoryImpl implements ReportRepository {
  final supa.SupabaseClient _supabase;

  ReportRepositoryImpl(this._supabase);

  @override
  Future<Report> submitReport({
    required String itemType,
    required String reason,
    String? reportedItemId,
    String? description,
  }) async {
    try {
      final reporterId = _supabase.auth.currentUser!.id;
      final response = await _supabase.from('reports').insert({
        'id': const Uuid().v4(),
        'reporter_id': reporterId,
        'reported_item_id': reportedItemId,
        'item_type': itemType,
        'reason': reason,
        'description': description,
      }).select().single();

      return ReportModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to submit report: $e');
    }
  }
}
