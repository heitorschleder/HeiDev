import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@injectable
class HomeRepository {
  HomeRepository(SupabaseClient client) : _client = client;

  final SupabaseClient _client;

  SupabaseClient get client => _client;
}
