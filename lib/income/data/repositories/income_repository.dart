import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_network_exception.dart';
import '../../domain/income_type.dart';
import '../models/income_model.dart';

@injectable
class IncomeRepository {
  final SupabaseClient _client;

  IncomeRepository(this._client);

  Future<IncomeModel?> fetchIncome() async {
    try {
      final data = await _client.from('incomes').select().maybeSingle();
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
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('incomes').upsert(
        {
          'user_id': userId,
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
        onConflict: 'user_id',
      );
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(message: 'Erro ao salvar renda.', reason: AppNetworkExceptionReason.unknown);
    }
  }
}
