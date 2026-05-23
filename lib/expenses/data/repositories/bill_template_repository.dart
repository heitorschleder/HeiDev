import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_network_exception.dart';
import '../../domain/expense_category.dart';
import '../models/bill_template_model.dart';

@injectable
class BillTemplateRepository {
  final SupabaseClient _client;

  BillTemplateRepository(this._client);

  Future<List<BillTemplateModel>> fetchTemplates() async {
    try {
      final data = await _client.from('bill_templates').select().order('title');
      return (data as List).map((e) => BillTemplateModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao carregar modelos.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> saveTemplate({
    required String title,
    required ExpenseCategory category,
    required bool isEssential,
    required double defaultAmount,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('bill_templates').insert({
        'user_id': userId,
        'title': title,
        'category': category.name,
        'is_essential': isEssential,
        'default_amount': defaultAmount,
      });
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao salvar modelo.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> updateTemplate(BillTemplateModel model) async {
    try {
      await _client.from('bill_templates').update(model.toJson()).eq('id', model.id);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao atualizar modelo.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _client.from('bill_templates').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao excluir modelo.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }
}
