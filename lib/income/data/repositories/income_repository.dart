import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_network_exception.dart';
import '../../domain/income_type.dart';
import '../models/income_event_model.dart';
import '../models/income_model.dart';

@injectable
class IncomeRepository {
  final SupabaseClient _client;

  IncomeRepository(this._client);

  Future<IncomeModel?> fetchIncome({required DateTime month}) async {
    try {
      final monthKey = _monthKey(month);
      final data = await _client
          .from('incomes')
          .select()
          .lte('effective_from', monthKey)
          .order('effective_from', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      return IncomeModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(message: 'Erro ao carregar renda.', reason: AppNetworkExceptionReason.unknown);
    }
  }

  Future<void> saveIncome({
    required IncomeType type,
    required double grossSalary,
    required bool receivesVr,
    required double vrAmount,
    required bool receivesVa,
    required double vaAmount,
    required double commission,
    required double bonus,
    required double otherIncome,
    required DateTime effectiveFrom,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('incomes').upsert(
        {
          'user_id': userId,
          'effective_from': _monthKey(effectiveFrom),
          'type': switch (type) {
            IncomeType.clt => 'CLT',
            IncomeType.pj => 'PJ',
            IncomeType.autonomo => 'autonomo',
          },
          'gross_salary': grossSalary,
          'receives_vr': receivesVr,
          'vr_amount': vrAmount,
          'receives_va': receivesVa,
          'va_amount': vaAmount,
          'commission': commission,
          'bonus': bonus,
          'other_income': otherIncome,
        },
        onConflict: 'user_id, effective_from',
      );
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(message: 'Erro ao salvar renda.', reason: AppNetworkExceptionReason.unknown);
    }
  }

  Future<List<IncomeEventModel>> fetchEvents({required DateTime month}) async {
    try {
      final data = await _client
          .from('income_events')
          .select()
          .eq('reference_month', _monthKey(month))
          .order('created_at');
      return (data as List).map((e) => IncomeEventModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(message: 'Erro ao carregar entradas.', reason: AppNetworkExceptionReason.unknown);
    }
  }

  Future<void> saveEvent({
    required DateTime month,
    required String description,
    required double amount,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('income_events').insert({
        'user_id': userId,
        'reference_month': _monthKey(month),
        'description': description,
        'amount': amount,
      });
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(message: 'Erro ao salvar entrada.', reason: AppNetworkExceptionReason.unknown);
    }
  }

  Future<({bool receivesVr, bool receivesVa})> fetchIncomeVouchers() async {
    try {
      final data = await _client
          .from('incomes')
          .select('receives_vr, receives_va')
          .order('effective_from', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return (receivesVr: true, receivesVa: true);
      return (
        receivesVr: data['receives_vr'] == true,
        receivesVa: data['receives_va'] == true,
      );
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      return (receivesVr: true, receivesVa: true);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _client.from('income_events').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(message: 'Erro ao excluir entrada.', reason: AppNetworkExceptionReason.unknown);
    }
  }

  static String _monthKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-01';
}
